import AppKit
import PointerDesignerCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var menuBarController: MenuBarController?
    private var preferencesWindowController: PreferencesWindowController?

    private let lifecycleManager = ProcessLifecycleManager.shared
    private let cursorEngine = CursorEngine.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Lifecycle manager handles: single instance, crash recovery, orphan cleanup, signals
        guard lifecycleManager.startup() else {
            NSApplication.shared.terminate(nil)
            return
        }

        // Register for clean shutdown
        lifecycleManager.registerForTermination { [weak self] in
            self?.performCleanup()
        }

        setupMenuBar()
        setupCursorEngine()
        checkHelperToolInstallation()
    }

    func applicationWillTerminate(_ notification: Notification) {
        lifecycleManager.shutdown()
    }

    // MARK: - Setup

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)

        guard let statusItem = statusItem else {
            showFatalError("Failed to Create Menu Bar Item",
                           message: "Cursor Designer could not create a menu bar item. Please try restarting the app.")
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
        NSLog("AppDelegate: setupCursorEngine - isEnabled=%d, contrastMode=%@",
              settings.isEnabled ? 1 : 0, String(describing: settings.contrastMode))
        cursorEngine.configure(with: settings)

        if settings.isEnabled {
            NSLog("AppDelegate: Starting cursor engine")
            cursorEngine.start()
            lifecycleManager.markCursorActive(true)
        } else {
            NSLog("AppDelegate: Cursor engine NOT started (isEnabled=false)")
        }

        // Track cursor state changes for crash recovery
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(settingsDidChange),
            name: .settingsDidChange,
            object: nil
        )
    }

    @objc private func settingsDidChange() {
        let settings = SettingsManager.shared.currentSettings
        lifecycleManager.markCursorActive(settings.isEnabled)
    }

    private func checkHelperToolInstallation() {
        // Disabled for testing - helper prompt was blocking smoke tests
        // TODO: Re-enable when helper installation is properly signed
        // if !HelperToolManager.shared.isHelperInstalled {
        //     DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
        //         self?.promptHelperInstallation()
        //     }
        // }
    }

    private func promptHelperInstallation() {
        let alert = NSAlert()
        alert.messageText = "Helper Tool Required"
        alert.informativeText = "Cursor Designer needs to install a helper tool for system-wide cursor changes. This requires administrator privileges."
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
        NSLog("AppDelegate: showPreferences() called")
        if preferencesWindowController == nil {
            NSLog("AppDelegate: Creating new PreferencesWindowController")
            preferencesWindowController = PreferencesWindowController()
        }
        NSLog("AppDelegate: Making Preferences window key and visible")
        preferencesWindowController?.window?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    // MARK: - Cleanup

    private func performCleanup() {
        cursorEngine.stop()
        menuBarController = nil
        NotificationCenter.default.removeObserver(self)
        HelperToolManager.shared.shutdown()
        SystemIntegrationManager.shared.shutdown()
    }

    private func showFatalError(_ title: String, message: String) {
        let alert = NSAlert()
        alert.messageText = title
        alert.informativeText = message
        alert.alertStyle = .critical
        alert.runModal()
        NSApplication.shared.terminate(nil)
    }
}
