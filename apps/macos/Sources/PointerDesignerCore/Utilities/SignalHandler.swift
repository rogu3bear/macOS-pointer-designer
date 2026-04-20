import Foundation

/// Centralized signal handling for clean shutdown
/// Uses DispatchSourceSignal for safe async signal handling
/// Note: Only ProcessLifecycleManager should create instances to avoid duplicate handlers
public final class SignalHandler {

    public enum Signal: Int32, CaseIterable {
        case terminate = 15  // SIGTERM
        case interrupt = 2   // SIGINT

        var name: String {
            switch self {
            case .terminate: return "SIGTERM"
            case .interrupt: return "SIGINT"
            }
        }
    }

    public typealias SignalCallback = (Signal) -> Void

    private var sources: [Signal: DispatchSourceSignal] = [:]
    private var callbacks: [SignalCallback] = []
    private let queue = DispatchQueue(label: Identity.signalHandlerQueueLabel, qos: .userInitiated)
    private let lock = NSLock()
    private var isActive = false

    public init() {}

    // MARK: - Public API

    /// Start listening for termination signals
    public func start() {
        lock.lock()
        defer { lock.unlock() }

        guard !isActive else { return }
        isActive = true

        for sig in Signal.allCases {
            setupSignalSource(for: sig)
        }

        NSLog("SignalHandler: Started listening for signals")
    }

    /// Stop listening for signals
    public func stop() {
        lock.lock()
        defer { lock.unlock() }

        guard isActive else { return }
        isActive = false

        for (sig, source) in sources {
            source.cancel()
            // Restore default signal handling
            signal(sig.rawValue, SIG_DFL)
        }
        sources.removeAll()

        NSLog("SignalHandler: Stopped listening for signals")
    }

    /// Register a callback for when a signal is received
    /// Callbacks are invoked on the main queue
    public func onSignal(_ callback: @escaping SignalCallback) {
        lock.lock()
        defer { lock.unlock() }
        callbacks.append(callback)
    }

    /// Remove all registered callbacks
    public func removeAllCallbacks() {
        lock.lock()
        defer { lock.unlock() }
        callbacks.removeAll()
    }

    // MARK: - Private

    private func setupSignalSource(for sig: Signal) {
        // Ignore default handler
        signal(sig.rawValue, SIG_IGN)

        let source = DispatchSource.makeSignalSource(signal: sig.rawValue, queue: queue)
        source.setEventHandler { [weak self] in
            self?.handleSignal(sig)
        }
        source.resume()

        sources[sig] = source
    }

    private func handleSignal(_ sig: Signal) {
        NSLog("SignalHandler: Received \(sig.name)")

        lock.lock()
        let currentCallbacks = callbacks
        lock.unlock()

        // Invoke callbacks on main queue for safe UI/AppKit operations
        DispatchQueue.main.async {
            for callback in currentCallbacks {
                callback(sig)
            }
        }
    }
}
