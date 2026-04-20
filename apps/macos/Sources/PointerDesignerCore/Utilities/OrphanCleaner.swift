import Foundation

/// Asynchronously cleans up orphaned helper processes from previous crashes
/// Runs on background queue to avoid blocking main thread
public final class OrphanCleaner {
    public struct CleanupResult {
        public let processesFound: Int
        public let processesKilled: Int
        public let errors: [Error]
    }

    private let processName: String
    private let currentPID: pid_t
    private let queue = DispatchQueue(label: Identity.orphanCleanerQueueLabel, qos: .utility)
    private let gracePeriod: TimeInterval
    private let forceKillTimeout: TimeInterval

    /// Default initializer for helper process cleanup
    public convenience init() {
        self.init(
            processName: "PointerDesignerHelper",
            currentPID: ProcessInfo.processInfo.processIdentifier,
            gracePeriod: 1.0,
            forceKillTimeout: 2.0
        )
    }

    /// Initializer for dependency injection (testing)
    public init(processName: String, currentPID: pid_t, gracePeriod: TimeInterval = 1.0, forceKillTimeout: TimeInterval = 2.0) {
        self.processName = processName
        self.currentPID = currentPID
        self.gracePeriod = gracePeriod
        self.forceKillTimeout = forceKillTimeout
    }

    // MARK: - Public API

    /// Clean up orphaned processes asynchronously
    /// Completion is called on the main queue
    public func cleanupAsync(completion: ((CleanupResult) -> Void)? = nil) {
        queue.async { [weak self] in
            guard let self = self else { return }
            let result = self.performCleanup()

            if let completion = completion {
                DispatchQueue.main.async {
                    completion(result)
                }
            }
        }
    }

    /// Clean up orphaned processes synchronously (use sparingly)
    public func cleanupSync() -> CleanupResult {
        return performCleanup()
    }

    // MARK: - Private

    private func performCleanup() -> CleanupResult {
        var errors: [Error] = []

        // Find processes matching the name
        let pids: [pid_t]
        do {
            pids = try findProcesses(matching: processName)
        } catch {
            NSLog("OrphanCleaner: Failed to find processes: \(error)")
            return CleanupResult(processesFound: 0, processesKilled: 0, errors: [error])
        }

        // Filter out current process
        let orphanPIDs = pids.filter { $0 != currentPID }

        guard !orphanPIDs.isEmpty else {
            return CleanupResult(processesFound: 0, processesKilled: 0, errors: [])
        }

        NSLog("OrphanCleaner: Found \(orphanPIDs.count) orphaned process(es)")

        var killedCount = 0

        for pid in orphanPIDs {
            do {
                try killProcess(pid: pid)
                killedCount += 1
                NSLog("OrphanCleaner: Killed orphan process (PID: \(pid))")
            } catch {
                errors.append(error)
                NSLog("OrphanCleaner: Failed to kill PID \(pid): \(error)")
            }
        }

        return CleanupResult(processesFound: orphanPIDs.count, processesKilled: killedCount, errors: errors)
    }

    private func findProcesses(matching name: String) throws -> [pid_t] {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
        task.arguments = ["-f", name]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = FileHandle.nullDevice

        try task.run()
        task.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8) else {
            return []
        }

        return output
            .split(separator: "\n")
            .compactMap { Int32($0) }
    }

    private func killProcess(pid: pid_t) throws {
        // Try graceful termination first
        guard kill(pid, SIGTERM) == 0 else {
            throw OrphanCleanerError.signalFailed(pid: pid, errno: errno)
        }

        // Poll for process termination instead of blocking sleep
        if waitForProcessExit(pid: pid, timeout: gracePeriod) {
            return // Process exited gracefully
        }

        // Still running, force kill
        NSLog("OrphanCleaner: Process \(pid) didn't terminate gracefully, force killing")

        guard kill(pid, SIGKILL) == 0 else {
            throw OrphanCleanerError.forceKillFailed(pid: pid, errno: errno)
        }

        // Wait for force kill to take effect
        if !waitForProcessExit(pid: pid, timeout: 0.5) {
            throw OrphanCleanerError.processStillRunning(pid: pid)
        }
    }

    /// Poll for process exit with timeout, returns true if process exited
    private func waitForProcessExit(pid: pid_t, timeout: TimeInterval) -> Bool {
        let deadline = Date().addingTimeInterval(timeout)
        let pollInterval: TimeInterval = 0.05 // 50ms polling

        while Date() < deadline {
            if kill(pid, 0) != 0 {
                return true // Process no longer exists
            }
            // Use RunLoop to avoid blocking the thread entirely
            RunLoop.current.run(until: Date().addingTimeInterval(pollInterval))
        }

        return kill(pid, 0) != 0
    }
}

// MARK: - Errors

public enum OrphanCleanerError: Error, LocalizedError {
    case signalFailed(pid: pid_t, errno: Int32)
    case forceKillFailed(pid: pid_t, errno: Int32)
    case processStillRunning(pid: pid_t)

    public var errorDescription: String? {
        switch self {
        case .signalFailed(let pid, let errno):
            return "Failed to send signal to process \(pid): \(String(cString: strerror(errno)))"
        case .forceKillFailed(let pid, let errno):
            return "Failed to force kill process \(pid): \(String(cString: strerror(errno)))"
        case .processStillRunning(let pid):
            return "Process \(pid) is still running after force kill"
        }
    }
}
