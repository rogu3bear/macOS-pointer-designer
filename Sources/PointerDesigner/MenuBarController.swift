import AppKit
import PointerDesignerCore

final class MenuBarController {
    private let statusItem: NSStatusItem
    private let menu = NSMenu()
    private var enabledMenuItem: NSMenuItem?

    var onPreferencesClicked: (() -> Void)?
    var onQuitClicked: (() -> Void)?

    init(statusItem: NSStatusItem) {
        self.statusItem = statusItem
        setupStatusItem()
        setupMenu()
    }

    private func setupStatusItem() {
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "cursorarrow", accessibilityDescription: "Pointer Designer")
            button.image?.isTemplate = true
        }
        statusItem.menu = menu
    }

    private func setupMenu() {
        let settings = SettingsManager.shared.currentSettings

        // Enabled toggle
        enabledMenuItem = NSMenuItem(
            title: settings.isEnabled ? "Enabled ✓" : "Disabled",
            action: #selector(toggleEnabled),
            keyEquivalent: "e"
        )
        enabledMenuItem?.target = self
        menu.addItem(enabledMenuItem!)

        menu.addItem(NSMenuItem.separator())

        // Quick contrast mode switcher
        let contrastMenu = NSMenu()

        let autoInvertItem = NSMenuItem(title: "Auto-Invert", action: #selector(setAutoInvert), keyEquivalent: "")
        autoInvertItem.target = self
        autoInvertItem.state = settings.contrastMode == .autoInvert ? .on : .off
        contrastMenu.addItem(autoInvertItem)

        let outlineItem = NSMenuItem(title: "Outline", action: #selector(setOutline), keyEquivalent: "")
        outlineItem.target = self
        outlineItem.state = settings.contrastMode == .outline ? .on : .off
        contrastMenu.addItem(outlineItem)

        let noneItem = NSMenuItem(title: "None", action: #selector(setNoContrast), keyEquivalent: "")
        noneItem.target = self
        noneItem.state = settings.contrastMode == .none ? .on : .off
        contrastMenu.addItem(noneItem)

        let contrastMenuItem = NSMenuItem(title: "Contrast Mode", action: nil, keyEquivalent: "")
        contrastMenuItem.submenu = contrastMenu
        menu.addItem(contrastMenuItem)

        menu.addItem(NSMenuItem.separator())

        // Preferences
        let prefsItem = NSMenuItem(title: "Preferences...", action: #selector(openPreferences), keyEquivalent: ",")
        prefsItem.target = self
        menu.addItem(prefsItem)

        menu.addItem(NSMenuItem.separator())

        // Quit
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)
    }

    @objc private func toggleEnabled() {
        var settings = SettingsManager.shared.currentSettings
        settings.isEnabled.toggle()
        SettingsManager.shared.save(settings)

        enabledMenuItem?.title = settings.isEnabled ? "Enabled ✓" : "Disabled"

        if settings.isEnabled {
            CursorEngine.shared.start()
        } else {
            CursorEngine.shared.stop()
        }
    }

    @objc private func setAutoInvert() {
        updateContrastMode(.autoInvert)
    }

    @objc private func setOutline() {
        updateContrastMode(.outline)
    }

    @objc private func setNoContrast() {
        updateContrastMode(.none)
    }

    private func updateContrastMode(_ mode: ContrastMode) {
        var settings = SettingsManager.shared.currentSettings
        settings.contrastMode = mode
        SettingsManager.shared.save(settings)
        CursorEngine.shared.configure(with: settings)
        setupMenu() // Refresh menu checkmarks
    }

    @objc private func openPreferences() {
        onPreferencesClicked?()
    }

    @objc private func quit() {
        onQuitClicked?()
    }
}
