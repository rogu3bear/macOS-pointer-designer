import Foundation

/// A property wrapper that provides thread-safe access to a value.
/// Uses NSLock for synchronization, suitable for low-contention scenarios.
@propertyWrapper
public final class Atomic<Value> {
    private var value: Value
    private let lock = NSLock()

    public init(wrappedValue: Value) {
        self.value = wrappedValue
    }

    public var wrappedValue: Value {
        get {
            lock.lock()
            defer { lock.unlock() }
            return value
        }
        set {
            lock.lock()
            defer { lock.unlock() }
            value = newValue
        }
    }

    /// Perform an atomic read-modify-write operation
    public func mutate(_ transform: (inout Value) -> Void) {
        lock.lock()
        defer { lock.unlock() }
        transform(&value)
    }

    /// Perform an atomic read and return a computed value
    public func withValue<T>(_ transform: (Value) -> T) -> T {
        lock.lock()
        defer { lock.unlock() }
        return transform(value)
    }
}

/// A property wrapper optimized for read-heavy workloads using os_unfair_lock.
/// Faster than NSLock but requires more care (non-recursive, not suitable for contention).
@propertyWrapper
public final class AtomicUnfair<Value> {
    private var value: Value
    private var unfairLock = os_unfair_lock()

    public init(wrappedValue: Value) {
        self.value = wrappedValue
    }

    public var wrappedValue: Value {
        get {
            os_unfair_lock_lock(&unfairLock)
            defer { os_unfair_lock_unlock(&unfairLock) }
            return value
        }
        set {
            os_unfair_lock_lock(&unfairLock)
            defer { os_unfair_lock_unlock(&unfairLock) }
            value = newValue
        }
    }

    /// Perform an atomic read-modify-write operation
    public func mutate(_ transform: (inout Value) -> Void) {
        os_unfair_lock_lock(&unfairLock)
        defer { os_unfair_lock_unlock(&unfairLock) }
        transform(&value)
    }
}
