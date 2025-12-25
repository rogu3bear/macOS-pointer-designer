import AppKit
import Combine
import PointerDesignerCore

final class MenuBarController {
    private let statusItem: NSStatusItem
    private let menu = NSMenu()
    private var enabledMenuItem: NSMenuItem?
    private var presetSubmenu: NSMenu?

    // Use CursorStateController for business logic
    private let stateController: CursorStateController
    private let iconGenerator = MenuBarIconGenerator.shared
    private var cancellables = Set<AnyCancellable>()

    var onPreferencesClicked: (() -> Void)?
    var onQuitClicked: (() -> Void)?

    init(statusItem: NSStatusItem, stateController: CursorStateController = .shared) {
        self.statusItem = statusItem
        self.stateController = stateController
        menu.autoenablesItems = false // Prevent auto-disabling menu items
        setupStatusItem()
        setupMenu()
        setupBindings()
        setupObservers() // Edge case #64: Observe settings changes
        updateMenuBarIcon() // Initial icon
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
        cancellables.removeAll()
    }

    // Bind to CursorStateController's published properties
    private func setupBindings() {
        stateController.$isEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isEnabled in
                self?.enabledMenuItem?.title = isEnabled ? "Enabled ✓" : "Disabled"
                self?.enabledMenuItem?.setAccessibilityLabel(isEnabled ? "Disable Cursor Designer" : "Enable Cursor Designer")
            }
            .store(in: &cancellables)

        stateController.$currentSettings
            .receive(on: DispatchQueue.main)
            .sink { [weak self] settings in
                self?.updateContrastModeCheckmarks(for: settings.contrastMode)
                self?.updatePresetCheckmarks(for: settings.preset)
                self?.updateMenuBarIcon()
            }
            .store(in: &cancellables)
    }

    // Update menu bar icon to match current cursor settings
    private func updateMenuBarIcon() {
        let settings = stateController.currentSettings
        let icon = iconGenerator.generateIcon(for: settings)
        statusItem.button?.image = icon
    }

    private func updateContrastModeCheckmarks(for mode: ContrastMode) {
        guard let contrastMenuItem = menu.items.first(where: { $0.title == "Contrast Mode" }),
              let contrastSubmenu = contrastMenuItem.submenu else { return }

        for item in contrastSubmenu.items {
            switch item.title {
            case "Auto-Invert":
                item.state = mode == .autoInvert ? .on : .off
            case "Outline":
                item.state = mode == .outline ? .on : .off
            case "None":
                item.state = mode == .none ? .on : .off
            default:
                break
            }
        }
    }

    private func updatePresetCheckmarks(for preset: CursorPreset) {
        guard let presetSubmenu = presetSubmenu else { return }

        for item in presetSubmenu.items {
            if let itemPreset = item.representedObject as? CursorPreset {
                item.state = itemPreset == preset ? .on : .off
            }
        }
    }

    private func setupStatusItem() {
        // Edge case #65: Set autosave name for status item persistence
        statusItem.autosaveName = "PointerDesignerStatusItem"

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "cursorarrow", accessibilityDescription: "Cursor Designer")
            button.image?.isTemplate = true

            // Edge case #70: Keyboard accessibility for menu bar icon
            button.setAccessibilityLabel("Cursor Designer Menu")
            button.setAccessibilityHelp("Click to open Cursor Designer menu, or press Control-Option-Space")
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
        let settings = stateController.currentSettings

        // Update enabled/disabled state
        enabledMenuItem?.title = settings.isEnabled ? "Enabled ✓" : "Disabled"

        // Update contrast mode checkmarks
        updateContrastModeCheckmarks(for: settings.contrastMode)
    }

    private func setupMenu() {
        let settings = stateController.currentSettings

        // Enabled toggle - Edge case #70: Add keyboard shortcut
        enabledMenuItem = NSMenuItem(
            title: settings.isEnabled ? "Enabled ✓" : "Disabled",
            action: #selector(toggleEnabled),
            keyEquivalent: "e"
        )
        enabledMenuItem?.target = self
        // Edge case #70: Accessibility
        enabledMenuItem?.setAccessibilityLabel(settings.isEnabled ? "Disable Cursor Designer" : "Enable Cursor Designer")
        if let menuItem = enabledMenuItem {
            menu.addItem(menuItem)
        }

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

        // Cursor Presets/Themes submenu
        let presetsMenu = NSMenu()
        self.presetSubmenu = presetsMenu

        for preset in CursorPreset.allCases {
            let presetItem = NSMenuItem(
                title: preset.displayName,
                action: #selector(selectPreset(_:)),
                keyEquivalent: ""
            )
            presetItem.target = self
            presetItem.representedObject = preset
            presetItem.state = settings.preset == preset ? .on : .off

            // Add a color swatch icon for each preset
            presetItem.image = iconGenerator.generatePresetIcon(for: preset)

            presetsMenu.addItem(presetItem)
        }

        let presetsMenuItem = NSMenuItem(title: "Themes", action: nil, keyEquivalent: "")
        presetsMenuItem.submenu = presetsMenu
        presetsMenuItem.setAccessibilityLabel("Choose Cursor Theme")
        menu.addItem(presetsMenuItem)

        menu.addItem(NSMenuItem.separator())

        // Preferences - Edge case #70: Standard Cmd+, shortcut
        let prefsItem = NSMenuItem(title: "Preferences...", action: #selector(openPreferences), keyEquivalent: ",")
        prefsItem.target = self
        prefsItem.isEnabled = true
        prefsItem.setAccessibilityLabel("Open Preferences Window")
        menu.addItem(prefsItem)

        menu.addItem(NSMenuItem.separator())

        // Quit - Edge case #70: Standard Cmd+Q shortcut
        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "q")
        quitItem.target = self
        quitItem.setAccessibilityLabel("Quit Cursor Designer")
        menu.addItem(quitItem)
    }

    @objc private func toggleEnabled() {
        stateController.toggleEnabled()
        // UI updates handled by Combine bindings
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
        stateController.setContrastMode(mode)
        // UI updates handled by Combine bindings
    }

    @objc private func selectPreset(_ sender: NSMenuItem) {
        guard let preset = sender.representedObject as? CursorPreset else { return }
        stateController.applyPreset(preset)
        // UI updates handled by Combine bindings
    }

    @objc private func openPreferences() {
        onPreferencesClicked?()
    }

    @objc private func quit() {
        onQuitClicked?()
    }
}
