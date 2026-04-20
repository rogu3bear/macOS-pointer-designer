import Foundation
import AppKit

/// Monitors the helper tool's health and notifies when it becomes unresponsive
public final class HelperWatchdog {
    public enum HelperStatus {
        case healthy
        case unresponsive
        case notInstalled
        case versionMismatch(expected: String, actual: String)
    }

    public typealias StatusCallback = (HelperStatus) -> Void

    private let helperManager: HelperService
    private let expectedVersion: String
    private let checkInterval: TimeInterval
    private let responseTimeout: TimeInterval

    private var timer: Timer?
    private var statusCallback: StatusCallback?
    private let queue = DispatchQueue(label: Identity.watchdogQueueLabel, qos: .utility)
    private let lock = NSLock()
    private var isRunning = false
    private var consecutiveFailures = 0
    private let maxConsecutiveFailures = 3

    /// Default initializer
    public convenience init() {
        self.init(
            helperManager: HelperToolManager.shared,
            expectedVersion: "1.0.0",
            checkInterval: 30.0,
            responseTimeout: 5.0
        )
    }

    /// Initializer for dependency injection (testing)
    public init(
        helperManager: HelperService,
        expectedVersion: String,
        checkInterval: TimeInterval = 30.0,
        responseTimeout: TimeInterval = 5.0
    ) {
        self.helperManager = helperManager
        self.expectedVersion = expectedVersion
        self.checkInterval = checkInterval
        self.responseTimeout = responseTimeout
    }

    // MARK: - Public API

    /// Start monitoring the helper tool
    public func start(statusCallback: @escaping StatusCallback) {
        lock.lock()
        defer { lock.unlock() }

        guard !isRunning else { return }
        isRunning = true
        self.statusCallback = statusCallback

        // Initial check
        performHealthCheck()

        // Schedule periodic checks
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.timer = Timer.scheduledTimer(withTimeInterval: self.checkInterval, repeats: true) { [weak self] _ in
                self?.performHealthCheck()
            }
        }

        NSLog("HelperWatchdog: Started monitoring")
    }

    /// Stop monitoring
    public func stop() {
        lock.lock()
        defer { lock.unlock() }

        guard isRunning else { return }
        isRunning = false

        DispatchQueue.main.async { [weak self] in
            self?.timer?.invalidate()
            self?.timer = nil
        }

        statusCallback = nil
        consecutiveFailures = 0

        NSLog("HelperWatchdog: Stopped monitoring")
    }

    /// Force an immediate health check
    public func checkNow() {
        performHealthCheck()
    }

    // MARK: - Private

    private func performHealthCheck() {
        queue.async { [weak self] in
            guard let self = self else { return }

            // Check if installed
            guard self.helperManager.isHelperInstalled else {
                self.reportStatus(.notInstalled)
                return
            }

            // Ping helper with timeout
            self.pingHelper { [weak self] success, version in
                guard let self = self else { return }

                if success {
                    self.consecutiveFailures = 0

                    // Check version
                    if let version = version, version != self.expectedVersion {
                        self.reportStatus(.versionMismatch(expected: self.expectedVersion, actual: version))
                    } else {
                        self.reportStatus(.healthy)
                    }
                } else {
                    self.consecutiveFailures += 1

                    if self.consecutiveFailures >= self.maxConsecutiveFailures {
                        self.reportStatus(.unresponsive)
                    }
                }
            }
        }
    }

    private func pingHelper(completion: @escaping (Bool, String?) -> Void) {
        // Create XPC connection for health check
        let connection = NSXPCConnection(machServiceName: Identity.xpcMachServiceName)
        connection.remoteObjectInterface = NSXPCInterface(with: PointerHelperProtocol.self)

        var completed = false
        let completionLock = NSLock()

        // Timeout handling
        DispatchQueue.global().asyncAfter(deadline: .now() + responseTimeout) {
            completionLock.lock()
            if !completed {
                completed = true
                completionLock.unlock()
                connection.invalidate()
                completion(false, nil)
            } else {
                completionLock.unlock()
            }
        }

        connection.resume()

        guard let helper = connection.remoteObjectProxyWithErrorHandler({ error in
            NSLog("HelperWatchdog: XPC error: \(error)")
            completionLock.lock()
            if !completed {
                completed = true
                completionLock.unlock()
                connection.invalidate()
                completion(false, nil)
            } else {
                completionLock.unlock()
            }
        }) as? PointerHelperProtocol else {
            completionLock.lock()
            if !completed {
                completed = true
                completionLock.unlock()
                connection.invalidate()
                completion(false, nil)
            } else {
                completionLock.unlock()
            }
            return
        }

        helper.getVersion { version in
            completionLock.lock()
            if !completed {
                completed = true
                completionLock.unlock()
                connection.invalidate()
                completion(true, version)
            } else {
                completionLock.unlock()
            }
        }
    }

    private func reportStatus(_ status: HelperStatus) {
        lock.lock()
        let callback = statusCallback
        lock.unlock()

        DispatchQueue.main.async {
            callback?(status)
        }

        switch status {
        case .healthy:
            break // Don't log healthy status to avoid spam
        case .unresponsive:
            NSLog("HelperWatchdog: Helper is unresponsive after \(self.consecutiveFailures) failed checks")
        case .notInstalled:
            NSLog("HelperWatchdog: Helper is not installed")
        case .versionMismatch(let expected, let actual):
            NSLog("HelperWatchdog: Version mismatch - expected \(expected), got \(actual)")
        }
    }
}

// MARK: - Notifications

public extension Notification.Name {
    static let helperBecameUnresponsive = Notification.Name(Identity.helperBecameUnresponsiveNotification)
    static let helperRecovered = Notification.Name(Identity.helperRecoveredNotification)
}
