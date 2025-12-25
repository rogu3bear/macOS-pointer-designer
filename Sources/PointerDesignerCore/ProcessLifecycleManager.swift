import Foundation
import AppKit

/// Central coordinator for application lifecycle management
/// Owns and orchestrates: single instance, signals, crash recovery, orphan cleanup
public final class ProcessLifecycleManager: ProcessLifecycleService {
    public static let shared = ProcessLifecycleManager()

    // Components
    private let singleInstanceGuard: SingleInstanceGuard
    private let signalHandler: SignalHandler
    private let crashRecoveryManager: CrashRecoveryManager
    private let orphanCleaner: OrphanCleaner
    private let cursorService: CursorService

    // State
    private let lock = NSLock()
    private var _isRunning = false
    private var terminationHandlers: [() -> Void] = []

    public var isRunning: Bool {
        lock.lock()
        defer { lock.unlock() }
        return _isRunning
    }

    /// Default initializer using production singletons
    private init() {
        self.singleInstanceGuard = SingleInstanceGuard()
        self.signalHandler = SignalHandler()
        self.crashRecoveryManager = CrashRecoveryManager()
        self.orphanCleaner = OrphanCleaner()
        self.cursorService = CursorEngine.shared
    }

    /// Initializer for dependency injection (testing)
    public init(
        singleInstanceGuard: SingleInstanceGuard,
        signalHandler: SignalHandler,
        crashRecoveryManager: CrashRecoveryManager,
        orphanCleaner: OrphanCleaner,
        cursorService: CursorService
    ) {
        self.singleInstanceGuard = singleInstanceGuard
        self.signalHandler = signalHandler
        self.crashRecoveryManager = crashRecoveryManager
        self.orphanCleaner = orphanCleaner
        self.cursorService = cursorService
    }

    // MARK: - ProcessLifecycleService

    /// Perform startup sequence
    /// Returns false if app should terminate (e.g., another instance running)
    public func startup() -> Bool {
        lock.lock()
        guard !_isRunning else {
            lock.unlock()
            return true
        }
        lock.unlock()

        NSLog("ProcessLifecycleManager: Starting up...")

        // Step 0: Migrate App Support directory if needed (one-time, from old name)
        let migrationResult = AppSupportMigrator.migrateIfNeeded()
        switch migrationResult {
        case .migrated:
            NSLog("ProcessLifecycleManager: Migrated App Support from PointerDesigner to CursorDesigner")
        case .copied:
            NSLog("ProcessLifecycleManager: Copied App Support from PointerDesigner to CursorDesigner")
        case .merged(let filesCopied):
            NSLog("ProcessLifecycleManager: Merged \(filesCopied) file(s) from PointerDesigner to CursorDesigner")
        case .failed(let error):
            NSLog("ProcessLifecycleManager: App Support migration failed: \(error)")
        case .notNeeded:
            break
        }

        // Step 1: Check single instance
        guard singleInstanceGuard.ensureSingleInstance() else {
            NSLog("ProcessLifecycleManager: Another instance is running, aborting startup")
            return false
        }

        // Step 2: Check for crash and recover
        crashRecoveryManager.onRecovery { [weak self] in
            self?.performCrashRecovery()
        }
        crashRecoveryManager.recoverIfNeeded()

        // Step 3: Clean up orphaned processes (async, non-blocking)
        orphanCleaner.cleanupAsync { result in
            if result.processesKilled > 0 {
                NSLog("ProcessLifecycleManager: Cleaned up \(result.processesKilled) orphaned process(es)")
            }
        }

        // Step 4: Start signal handling
        signalHandler.onSignal { [weak self] signal in
            self?.handleSignal(signal)
        }
        signalHandler.start()

        // Step 5: Start new session
        crashRecoveryManager.startSession()

        lock.lock()
        _isRunning = true
        lock.unlock()

        NSLog("ProcessLifecycleManager: Startup complete")
        return true
    }

    /// Perform clean shutdown
    public func shutdown() {
        lock.lock()
        guard _isRunning else {
            lock.unlock()
            return
        }
        _isRunning = false
        let handlers = terminationHandlers
        lock.unlock()

        NSLog("ProcessLifecycleManager: Shutting down...")

        // Invoke termination handlers
        for handler in handlers {
            handler()
        }

        // Stop signal handling
        signalHandler.stop()
        signalHandler.removeAllCallbacks()

        // End session cleanly (removes session file)
        crashRecoveryManager.endSession()

        NSLog("ProcessLifecycleManager: Shutdown complete")
    }

    /// Register a handler to be called on termination (signal or normal)
    public func registerForTermination(_ handler: @escaping () -> Void) {
        lock.lock()
        defer { lock.unlock() }
        terminationHandlers.append(handler)
    }

    // MARK: - Cursor State Tracking

    /// Update crash recovery to know if cursor was active
    /// Call this when cursor customization is enabled/disabled
    public func markCursorActive(_ active: Bool) {
        crashRecoveryManager.markCursorActive(active)
    }

    // MARK: - Private

    private func handleSignal(_ signal: SignalHandler.Signal) {
        NSLog("ProcessLifecycleManager: Received \(signal), initiating shutdown")

        // Perform shutdown
        shutdown()

        // Terminate the application
        DispatchQueue.main.async {
            NSApplication.shared.terminate(nil)
        }
    }

    private func performCrashRecovery() {
        NSLog("ProcessLifecycleManager: Performing crash recovery")

        // Stop cursor engine if it's somehow still active
        cursorService.stop()

        // Additional recovery steps can be added here
    }
}

// MARK: - Notifications

public extension Notification.Name {
    static let processLifecycleStarted = Notification.Name(Identity.processLifecycleStartedNotification)
    static let processLifecycleShutdown = Notification.Name(Identity.processLifecycleShutdownNotification)
}
