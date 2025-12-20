import AppKit
import PointerDesignerCore

final class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusItem: NSStatusItem?
    private var menuBarController: MenuBarController?
    private var preferencesWindowController: PreferencesWindowController?
    private let cursorEngine = CursorEngine.shared

    func applicationDidFinishLaunching(_ notification: Notification) {
        setupMenuBar()
        setupCursorEngine()
        checkHelperToolInstallation()
    }

    func applicationWillTerminate(_ notification: Notification) {
        cursorEngine.stop()
    }

    private func setupMenuBar() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        menuBarController = MenuBarController(statusItem: statusItem!)
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
        }
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
        if preferencesWindowController == nil {
            preferencesWindowController = PreferencesWindowController()
        }
        preferencesWindowController?.showWindow(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
}
