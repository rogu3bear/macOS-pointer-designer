import AppKit
import PointerDesignerCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var menuBarController: MenuBarController?
    private var preferencesWindowController: PreferencesWindowController?
    private let cursorEngine = CursorEngine.shared

    // Edge case #66: Signal dispatch sources for safe signal handling
    private var sigtermSource: DispatchSourceSignal?
    private var sigintSource: DispatchSourceSignal?

    // Edge case #67: Track cursor active state for crash recovery
    private let cursorActiveKey = "com.pointerdesigner.cursorWasActive"

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Edge case #68: Enforce single instance
        if !ensureSingleInstance() {
            return
        }

        // Clean up any orphaned helper processes from previous crashes
        cleanupOrphanedProcesses()

        setupCrashRecovery() // Edge case #67
        setupSignalHandlers() // Edge case #66
        setupMenuBar()
        setupCursorEngine()
        checkHelperToolInstallation()
        checkCrashRecovery() // Edge case #67
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        // Perform cleanup synchronously to ensure it completes before termination
        performCleanup()
        return .terminateNow
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Final cleanup - this runs after applicationShouldTerminate returned .terminateNow
        // Keep this minimal since we already cleaned up in applicationShouldTerminate
    }

    private func performCleanup() {
        NSLog("AppDelegate: Beginning cleanup sequence")

        // Cancel signal sources to prevent late callbacks
        sigtermSource?.cancel()
        sigintSource?.cancel()
        sigtermSource = nil
        sigintSource = nil

        // Remove notification observers
        NotificationCenter.default.removeObserver(self)

        // Restore cursor state (synchronous)
        restoreCursorState()

        // Shutdown helper tool manager XPC connection (synchronous)
        HelperToolManager.shared.shutdown()

        // Shutdown system integration manager (synchronous)
        SystemIntegrationManager.shared.shutdown()

        // Clean up menu bar controller
        menuBarController = nil

        NSLog("AppDelegate: Cleanup complete")
    }

    private func setupMenuBar() {
        // Edge case #65: Status item persistence is handled in MenuBarController
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        guard let statusItem = statusItem else {
            // Edge case #65: Handle case where status item cannot be created
            let alert = NSAlert()
            alert.messageText = "Failed to Create Menu Bar Item"
            alert.informativeText = "Pointer Designer could not create a menu bar item. Please try restarting the app."
            alert.alertStyle = .critical
            alert.runModal()
            NSApplication.shared.terminate(nil)
            return
        }

        menuBarController = MenuBarController(statusItem: statusItem)
        menuBarController?.onPreferencesClicked = { [weak self] in
            self?.showPreferences()
        }
        menuBarController?.onQuitClicked = {
            NSApplication.shared.terminate(nil)
        }
    }

    private func setupCursorEngine() {
        let settings = SettingsManager.shared.currentSettings
        cursorEngine.configure(with: settings)

        if settings.isEnabled {
            cursorEngine.start()
            // Edge case #67: Mark cursor as active
            UserDefaults.standard.set(true, forKey: cursorActiveKey)
        }

        // Edge case #67: Observe cursor state changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(settingsDidChange),
            name: .settingsDidChange,
            object: nil
        )
    }

    // Edge case #67: Update cursor active state when settings change
    @objc private func settingsDidChange() {
        let settings = SettingsManager.shared.currentSettings
        UserDefaults.standard.set(settings.isEnabled, forKey: cursorActiveKey)
    }

    private func checkHelperToolInstallation() {
        if !HelperToolManager.shared.isHelperInstalled {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                self?.promptHelperInstallation()
            }
        }
    }

    private func promptHelperInstallation() {
        let alert = NSAlert()
        alert.messageText = "Helper Tool Required"
        alert.informativeText = "PointerDesigner needs to install a helper tool for system-wide cursor changes. This requires administrator privileges."
        alert.alertStyle = .informational
        alert.addButton(withTitle: "Install")
        alert.addButton(withTitle: "Later")

        if alert.runModal() == .alertFirstButtonReturn {
            HelperToolManager.shared.installHelper { success, error in
                if !success {
                    DispatchQueue.main.async {
                        let errorAlert = NSAlert()
                        errorAlert.messageText = "Installation Failed"
                        errorAlert.informativeText = error?.localizedDescription ?? "Unknown error occurred"
                        errorAlert.alertStyle = .warning
                        errorAlert.runModal()
                    }
                }
            }
        }
    }

    private func showPreferences() {
        // Edge case #52: Bring existing window to front instead of creating duplicate
        if preferencesWindowController == nil {
            preferencesWindowController = PreferencesWindowController()
        }
        // Use makeKeyAndOrderFront to bring existing window to front if already open
        preferencesWindowController?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Edge Cases Implementation

    // Edge case #68: Ensure single instance of app
    private func ensureSingleInstance() -> Bool {
        let bundleIdentifier = Bundle.main.bundleIdentifier ?? "com.pointerdesigner"
        let runningApps = NSWorkspace.shared.runningApplications
        let instances = runningApps.filter { $0.bundleIdentifier == bundleIdentifier }

        // If more than one instance (current + existing)
        if instances.count > 1 {
            // Find the other instance (not current process)
            if let existingInstance = instances.first(where: { $0.processIdentifier != ProcessInfo.processInfo.processIdentifier }) {
                // Activate the existing instance
                existingInstance.activate(options: [.activateIgnoringOtherApps])

                // Show alert to user
                DispatchQueue.main.async {
                    let alert = NSAlert()
                    alert.messageText = "Pointer Designer Already Running"
                    alert.informativeText = "Pointer Designer is already running. The existing instance has been activated."
                    alert.alertStyle = .informational
                    alert.runModal()
                }

                // Terminate this instance
                DispatchQueue.main.async {
                    NSApplication.shared.terminate(nil)
                }

                return false
            }
        }

        return true
    }

    // Edge case #66: Set up signal handlers for clean shutdown
    // Uses DispatchSourceSignal for safe signal handling instead of C signal()
    private func setupSignalHandlers() {
        // SIGTERM handling (e.g., kill command, system shutdown)
        signal(SIGTERM, SIG_IGN) // Ignore default handler
        sigtermSource = DispatchSource.makeSignalSource(signal: SIGTERM, queue: .main)
        sigtermSource?.setEventHandler { [weak self] in
            self?.handleTerminationSignal()
        }
        sigtermSource?.resume()

        // SIGINT handling (e.g., Ctrl+C in terminal)
        signal(SIGINT, SIG_IGN) // Ignore default handler
        sigintSource = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
        sigintSource?.setEventHandler { [weak self] in
            self?.handleTerminationSignal()
        }
        sigintSource?.resume()
    }

    // Safe termination handler called on main queue
    private func handleTerminationSignal() {
        restoreCursorState()
        NSApplication.shared.terminate(nil)
    }

    // Edge case #67: Set up crash handler
    private func setupCrashRecovery() {
        // Register for uncaught exception handler
        NSSetUncaughtExceptionHandler { exception in
            // Attempt to restore cursor before crash
            CursorEngine.shared.stop()
            // Re-throw to allow system to handle the crash
            NSLog("Pointer Designer: Uncaught exception: \(exception)")
        }
    }

    // Edge case #67: Check if app crashed last time with cursor active
    private func checkCrashRecovery() {
        let wasActive = UserDefaults.standard.bool(forKey: cursorActiveKey)
        let settings = SettingsManager.shared.currentSettings

        // If cursor was active during crash but not currently enabled, it means we crashed
        if wasActive && !settings.isEnabled {
            // Ensure cursor is restored
            cursorEngine.stop()

            // Show recovery message
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "Crash Recovery"
                alert.informativeText = "Pointer Designer detected an unexpected shutdown and has restored your cursor to normal."
                alert.alertStyle = .informational
                alert.runModal()
            }

            // Clear the active flag
            UserDefaults.standard.set(false, forKey: cursorActiveKey)
        }
    }

    // Edge case #66: Ensure cursor restoration on terminate
    private func restoreCursorState() {
        cursorEngine.stop()
        UserDefaults.standard.set(false, forKey: cursorActiveKey)
        UserDefaults.standard.synchronize()
    }

    // MARK: - Orphaned Process Cleanup

    private static let helperPIDFilePath = "/tmp/com.pointerdesigner.helper.pid"

    /// Find and terminate any orphaned helper processes from previous runs
    private func cleanupOrphanedProcesses() {
        // First try PID file (most reliable)
        if let pid = readHelperPID() {
            cleanupProcess(pid: pid, source: "PID file")
        }

        // Fallback: also check with pgrep in case PID file is stale
        cleanupOrphanedProcessesWithPgrep()
    }

    private func readHelperPID() -> Int32? {
        guard let content = try? String(contentsOfFile: Self.helperPIDFilePath, encoding: .utf8),
              let pid = Int32(content.trimmingCharacters(in: .whitespacesAndNewlines)) else {
            return nil
        }
        return pid
    }

    private func cleanupProcess(pid: Int32, source: String) {
        // Check if process exists
        guard kill(pid, 0) == 0 else {
            NSLog("AppDelegate: PID \(pid) from \(source) no longer exists, cleaning up stale file")
            try? FileManager.default.removeItem(atPath: Self.helperPIDFilePath)
            return
        }

        NSLog("AppDelegate: Found orphaned helper (PID: \(pid)) via \(source), terminating")
        kill(pid, SIGTERM)

        // Wait briefly then force kill if needed
        DispatchQueue.global().asyncAfter(deadline: .now() + 2.0) {
            if kill(pid, 0) == 0 {
                NSLog("AppDelegate: Force killing unresponsive helper (PID: \(pid))")
                kill(pid, SIGKILL)
            }
            // Clean up PID file
            try? FileManager.default.removeItem(atPath: Self.helperPIDFilePath)
        }
    }

    private func cleanupOrphanedProcessesWithPgrep() {
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/usr/bin/pgrep")
        task.arguments = ["-f", "PointerDesignerHelper"]

        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = FileHandle.nullDevice

        do {
            try task.run()
            task.waitUntilExit()

            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            if let output = String(data: data, encoding: .utf8) {
                let pids = output.split(separator: "\n").compactMap { Int32($0) }
                let currentPID = ProcessInfo.processInfo.processIdentifier

                for pid in pids where pid != currentPID {
                    cleanupProcess(pid: pid, source: "pgrep")
                }
            }
        } catch {
            // pgrep failure is not critical
        }
    }
}
