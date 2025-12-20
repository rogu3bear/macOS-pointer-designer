import AppKit
import PointerDesignerCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var menuBarController: MenuBarController?
    private var preferencesWindowController: PreferencesWindowController?
    private let cursorEngine = CursorEngine.shared

    // Edge case #67: Track cursor active state for crash recovery
    private let cursorActiveKey = "com.pointerdesigner.cursorWasActive"

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Edge case #68: Enforce single instance
        if !ensureSingleInstance() {
            return
        }

        setupCrashRecovery() // Edge case #67
        setupSignalHandlers() // Edge case #66
        setupMenuBar()
        setupCursorEngine()
        checkHelperToolInstallation()
        checkCrashRecovery() // Edge case #67
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Edge case #66: Always restore cursor on termination
        restoreCursorState()
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
    private func setupSignalHandlers() {
        // Use atexit as a backup restoration mechanism
        atexit {
            // This runs when the process exits normally
            CursorEngine.shared.stop()
        }

        // Set up signal handlers for SIGTERM and SIGINT
        signal(SIGTERM) { signal in
            // Restore cursor and exit
            CursorEngine.shared.stop()
            exit(0)
        }

        signal(SIGINT) { signal in
            // Restore cursor and exit
            CursorEngine.shared.stop()
            exit(0)
        }
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
}
