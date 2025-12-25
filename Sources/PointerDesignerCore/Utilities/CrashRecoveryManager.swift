import Foundation
import AppKit

/// Manages crash detection and recovery using a session file
/// More reliable than UserDefaults which may not sync before crash
public final class CrashRecoveryManager {
    public struct SessionInfo: Codable {
        public let pid: pid_t
        public let startTime: Date
        public let cursorWasActive: Bool

        public init(pid: pid_t, startTime: Date, cursorWasActive: Bool) {
            self.pid = pid
            self.startTime = startTime
            self.cursorWasActive = cursorWasActive
        }
    }

    public enum CrashCheckResult {
        case noPreviousSession
        case cleanShutdown
        case crashDetected(previousSession: SessionInfo)
    }

    public typealias RecoveryHandler = () -> Void

    private let sessionFilePath: String
    private let fileManager: FileManager
    private var recoveryHandler: RecoveryHandler?
    private let lock = NSLock()

    /// Default initializer
    public convenience init() {
        let sessionPath = Self.defaultSessionFilePath()
        self.init(sessionFilePath: sessionPath, fileManager: .default)
    }

    /// Get the default session file path in Application Support
    /// Falls back to temp directory if Application Support is unavailable
    private static func defaultSessionFilePath() -> String {
        let fileManager = FileManager.default

        // Try Application Support first (persists across reboots)
        if let appSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let appDir = appSupport.appendingPathComponent(Identity.appSupportDirName)

            // Create directory if needed
            if !fileManager.fileExists(atPath: appDir.path) {
                try? fileManager.createDirectory(at: appDir, withIntermediateDirectories: true)
            }

            return appDir.appendingPathComponent("session.json").path
        }

        // Fallback to temp directory
        let tempDir = NSTemporaryDirectory()
        return (tempDir as NSString).appendingPathComponent(Identity.sessionFileName)
    }

    /// Initializer for dependency injection (testing)
    public init(sessionFilePath: String, fileManager: FileManager) {
        self.sessionFilePath = sessionFilePath
        self.fileManager = fileManager
    }

    // MARK: - Public API

    /// Register a handler to be called when crash recovery is performed
    public func onRecovery(_ handler: @escaping RecoveryHandler) {
        lock.lock()
        defer { lock.unlock() }
        recoveryHandler = handler
    }

    /// Check if a previous session crashed
    /// Call this early in app startup before creating a new session
    public func checkForCrash() -> CrashCheckResult {
        guard fileManager.fileExists(atPath: sessionFilePath) else {
            return .noPreviousSession
        }

        // Read previous session info
        guard let previousSession = readSessionInfo() else {
            // Corrupt file, treat as crash
            cleanup()
            return .noPreviousSession
        }

        // Check if the previous process is still running
        if isProcessRunning(pid: previousSession.pid) {
            // Another instance is running (shouldn't happen with SingleInstanceGuard)
            // Don't treat as crash
            return .cleanShutdown
        }

        // Previous process is not running and session file exists = crash
        cleanup()
        return .crashDetected(previousSession: previousSession)
    }

    /// Perform crash recovery if needed
    /// Returns true if crash was detected and recovery was performed
    @discardableResult
    public func recoverIfNeeded(showAlert: Bool = true) -> Bool {
        let result = checkForCrash()

        guard case .crashDetected(let previousSession) = result else {
            return false
        }

        NSLog("CrashRecoveryManager: Crash detected from previous session (PID: \(previousSession.pid))")

        // Invoke recovery handler
        lock.lock()
        let handler = recoveryHandler
        lock.unlock()

        handler?()

        if showAlert && previousSession.cursorWasActive {
            DispatchQueue.main.async {
                self.showRecoveryAlert()
            }
        }

        return true
    }

    /// Start a new session
    /// Call this after crash check, before enabling cursor
    public func startSession() {
        let session = SessionInfo(
            pid: ProcessInfo.processInfo.processIdentifier,
            startTime: Date(),
            cursorWasActive: false
        )
        writeSessionInfo(session)
        NSLog("CrashRecoveryManager: Session started (PID: \(session.pid))")
    }

    /// Update session to indicate cursor is active
    public func markCursorActive(_ active: Bool) {
        guard var session = readSessionInfo() else {
            // No session, create one
            startSession()
            if active {
                markCursorActive(true)
            }
            return
        }

        if session.cursorWasActive != active {
            session = SessionInfo(
                pid: session.pid,
                startTime: session.startTime,
                cursorWasActive: active
            )
            writeSessionInfo(session)
        }
    }

    /// End session cleanly
    /// Call this during normal shutdown
    public func endSession() {
        cleanup()
        NSLog("CrashRecoveryManager: Session ended cleanly")
    }

    // MARK: - Private

    private func readSessionInfo() -> SessionInfo? {
        guard let data = fileManager.contents(atPath: sessionFilePath) else {
            return nil
        }

        return try? JSONDecoder().decode(SessionInfo.self, from: data)
    }

    private func writeSessionInfo(_ session: SessionInfo) {
        guard let data = try? JSONEncoder().encode(session) else {
            NSLog("CrashRecoveryManager: Failed to encode session info")
            return
        }

        do {
            try data.write(to: URL(fileURLWithPath: sessionFilePath), options: .atomic)
        } catch {
            NSLog("CrashRecoveryManager: Failed to write session file: \(error)")
        }
    }

    private func cleanup() {
        try? fileManager.removeItem(atPath: sessionFilePath)
    }

    private func isProcessRunning(pid: pid_t) -> Bool {
        // kill with signal 0 checks if process exists without sending a signal
        return kill(pid, 0) == 0
    }

    private func showRecoveryAlert() {
        let alert = NSAlert()
        alert.messageText = "Crash Recovery"
        alert.informativeText = "Cursor Designer detected an unexpected shutdown and has restored your cursor to normal."
        alert.alertStyle = .informational
        alert.runModal()
    }
}
