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
        setupObservers() // Edge case #64: Observe settings changes
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupStatusItem() {
        // Edge case #65: Set autosave name for status item persistence
        statusItem.autosaveName = "PointerDesignerStatusItem"

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "cursorarrow", accessibilityDescription: "Pointer Designer")
            button.image?.isTemplate = true

            // Edge case #70: Keyboard accessibility for menu bar icon
            button.setAccessibilityLabel("Pointer Designer Menu")
            button.setAccessibilityHelp("Click to open Pointer Designer menu, or press Control-Option-Space")
        }
        statusItem.menu = menu
    }

    // Edge case #64: Setup notification observers for settings changes
    private func setupObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(settingsDidChange),
            name: .settingsDidChange,
            object: nil
        )
    }

    // Edge case #64: Refresh menu when settings change externally (e.g., from preferences)
    @objc private func settingsDidChange() {
        updateMenuState()
    }

    // Edge case #64: Update menu items without rebuilding entire menu
    private func updateMenuState() {
        let settings = SettingsManager.shared.currentSettings

        // Update enabled/disabled state
        enabledMenuItem?.title = settings.isEnabled ? "Enabled ✓" : "Disabled"

        // Update contrast mode checkmarks
        if let contrastMenuItem = menu.items.first(where: { $0.title == "Contrast Mode" }),
           let contrastSubmenu = contrastMenuItem.submenu {
            for item in contrastSubmenu.items {
                switch item.title {
                case "Auto-Invert":
                    item.state = settings.contrastMode == .autoInvert ? .on : .off
                case "Outline":
                    item.state = settings.contrastMode == .outline ? .on : .off
                case "None":
                    item.state = settings.contrastMode == .none ? .on : .off
                default:
                    break
                }
            }
        }
    }

    private func setupMenu() {
        let settings = SettingsManager.shared.currentSettings

        // Enabled toggle - Edge case #70: Add keyboard shortcut
        enabledMenuItem = NSMenuItem(
            title: settings.isEnabled ? "Enabled ✓" : "Disabled",
            action: #selector(toggleEnabled),
            keyEquivalent: "e"
        )
        enabledMenuItem?.target = self
        // Edge case #70: Accessibility
        enabledMenuItem?.setAccessibilityLabel(settings.isEnabled ? "Disable Pointer Designer" : "Enable Pointer Designer")
        menu.addItem(enabledMenuItem!)

        menu.addItem(NSMenuItem.separator())

        // Quick contrast mode switcher - Edge case #70: Add keyboard shortcuts
        let contrastMenu = NSMenu()

        let autoInvertItem = NSMenuItem(title: "Auto-Invert", action: #selector(setAutoInvert), keyEquivalent: "1")
        autoInvertItem.keyEquivalentModifierMask = [.command]
        autoInvertItem.target = self
        autoInvertItem.state = settings.contrastMode == .autoInvert ? .on : .off
        autoInvertItem.setAccessibilityLabel("Auto-Invert Contrast Mode")
        contrastMenu.addItem(autoInvertItem)

        let outlineItem = NSMenuItem(title: "Outline", action: #selector(setOutline), keyEquivalent: "2")
        outlineItem.keyEquivalentModifierMask = [.command]
        outlineItem.target = self
        outlineItem.state = settings.contrastMode == .outline ? .on : .off
        outlineItem.setAccessibilityLabel("Outline Contrast Mode")
        contrastMenu.addItem(outlineItem)

        let noneItem = NSMenuItem(title: "None", action: #selector(setNoContrast), keyEquivalent: "3")
        noneItem.keyEquivalentModifierMask = [.command]
        noneItem.target = self
        noneItem.state = settings.contrastMode == .none ? .on : .off
        noneItem.setAccessibilityLabel("No Contrast Mode")
        contrastMenu.addItem(noneItem)

        let contrastMenuItem = NSMenuItem(title: "Contrast Mode", action: nil, keyEquivalent: "")
        contrastMenuItem.submenu = contrastMenu
        contrastMenuItem.setAccessibilityLabel("Choose Contrast Mode")
        menu.addItem(contrastMenuItem)

        menu.addItem(NSMenuItem.separator())

        // Preferences - Edge case #70: Standard Cmd+, shortcut
        let prefsItem = NSMenuItem(title: "Preferences...", action: #selector(openPreferences), keyEquivalent: ",")
        prefsItem.target = self
        prefsItem.setAccessibilityLabel("Open Preferences Window")
        menu.addItem(prefsItem)

        menu.addItem(NSMenuItem.separator())

        // Quit - Edge case #70: Standard Cmd+Q shortcut
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        quitItem.setAccessibilityLabel("Quit Pointer Designer")
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
        // Edge case #64: Use updateMenuState instead of rebuilding entire menu
        updateMenuState()
    }

    @objc private func openPreferences() {
        onPreferencesClicked?()
    }

    @objc private func quit() {
        onQuitClicked?()
    }
}
