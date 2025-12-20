import AppKit
import PointerDesignerCore

final class PreferencesWindowController: NSWindowController {
    private var preferencesView: PreferencesView?

    convenience init() {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 400),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Pointer Designer Preferences"

        // Edge case #54: Center window on main screen to avoid wrong display/space
        if let mainScreen = NSScreen.main {
            let screenFrame = mainScreen.visibleFrame
            let windowFrame = window.frame
            let x = screenFrame.midX - windowFrame.width / 2
            let y = screenFrame.midY - windowFrame.height / 2
            window.setFrame(NSRect(x: x, y: y, width: windowFrame.width, height: windowFrame.height), display: false)
        } else {
            window.center()
        }

        window.isReleasedWhenClosed = false
        // Edge case #54: Ensure window appears on current space
        window.collectionBehavior = [.moveToActiveSpace]

        // Edge case #69: Accessibility for preferences window
        window.setAccessibilityLabel("Pointer Designer Preferences")
        window.setAccessibilityHelp("Configure cursor appearance and behavior settings")

        self.init(window: window)

        preferencesView = PreferencesView(frame: window.contentView!.bounds)
        window.contentView = preferencesView

        // Edge case #70: Set initial first responder for keyboard navigation
        if let firstControl = preferencesView?.firstKeyView {
            window.initialFirstResponder = firstControl
        }
    }
}

final class PreferencesView: NSView {
    private var colorWell: NSColorWell?
    private var contrastModePopup: NSPopUpButton?
    private var outlineWidthSlider: NSSlider?
    private var launchAtLoginCheckbox: NSButton?
    private var samplingRateSlider: NSSlider?

    // Edge case #70: Track first key view for keyboard navigation
    var firstKeyView: NSView? {
        return colorWell
    }

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupUI()
        loadSettings()
        // Edge case #55: Observe settings changes from external sources
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(settingsDidChange),
            name: .settingsDidChange,
            object: nil
        )
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        loadSettings()
        // Edge case #55: Observe settings changes from external sources
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(settingsDidChange),
            name: .settingsDidChange,
            object: nil
        )
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupUI() {
        let stackView = NSStackView()
        stackView.orientation = .vertical
        stackView.alignment = .leading
        stackView.spacing = 16
        stackView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -20)
        ])

        // Cursor Color Section
        let colorSection = createSection(title: "Cursor Color")
        colorWell = NSColorWell()
        colorWell?.color = .white
        colorWell?.target = self
        colorWell?.action = #selector(colorChanged)
        // Edge case #69: VoiceOver accessibility
        colorWell?.setAccessibilityLabel("Cursor Color")
        colorWell?.setAccessibilityHelp("Choose the color for your custom cursor")
        colorSection.addArrangedSubview(colorWell!)
        stackView.addArrangedSubview(colorSection)

        // Contrast Mode Section
        let contrastSection = createSection(title: "Contrast Mode")
        contrastModePopup = NSPopUpButton()
        contrastModePopup?.addItems(withTitles: ["None", "Auto-Invert", "Outline"])
        contrastModePopup?.target = self
        contrastModePopup?.action = #selector(contrastModeChanged)
        // Edge case #69: VoiceOver accessibility
        contrastModePopup?.setAccessibilityLabel("Contrast Mode")
        contrastModePopup?.setAccessibilityHelp("Select how the cursor adapts to different backgrounds: None, Auto-Invert, or Outline")
        contrastSection.addArrangedSubview(contrastModePopup!)
        stackView.addArrangedSubview(contrastSection)

        // Outline Width Section
        let outlineSection = createSection(title: "Outline Width")
        outlineWidthSlider = NSSlider(value: 2, minValue: 1, maxValue: 5, target: self, action: #selector(outlineWidthChanged))
        // Edge case #53: Disable continuous updates to avoid excessive saves
        outlineWidthSlider?.isContinuous = false
        outlineWidthSlider?.widthAnchor.constraint(equalToConstant: 200).isActive = true
        // Edge case #69: VoiceOver accessibility
        outlineWidthSlider?.setAccessibilityLabel("Outline Width")
        outlineWidthSlider?.setAccessibilityHelp("Adjust the width of the cursor outline from 1 to 5 pixels")
        outlineWidthSlider?.setAccessibilityValue("\(Int(outlineWidthSlider?.doubleValue ?? 2)) pixels")
        outlineSection.addArrangedSubview(outlineWidthSlider!)
        stackView.addArrangedSubview(outlineSection)

        // Sampling Rate Section
        let samplingSection = createSection(title: "Background Sampling Rate")
        samplingRateSlider = NSSlider(value: 60, minValue: 15, maxValue: 120, target: self, action: #selector(samplingRateChanged))
        // Edge case #53: Disable continuous updates to avoid excessive saves
        samplingRateSlider?.isContinuous = false
        samplingRateSlider?.widthAnchor.constraint(equalToConstant: 200).isActive = true
        // Edge case #69: VoiceOver accessibility
        samplingRateSlider?.setAccessibilityLabel("Background Sampling Rate")
        samplingRateSlider?.setAccessibilityHelp("Adjust how often the cursor samples the background. Higher values are smoother but use more CPU. Range: 15 to 120 Hz")
        samplingRateSlider?.setAccessibilityValue("\(Int(samplingRateSlider?.doubleValue ?? 60)) Hz")
        let samplingLabel = NSTextField(labelWithString: "Higher = smoother, more CPU")
        samplingLabel.font = NSFont.systemFont(ofSize: 10)
        samplingLabel.textColor = .secondaryLabelColor
        samplingSection.addArrangedSubview(samplingRateSlider!)
        samplingSection.addArrangedSubview(samplingLabel)
        stackView.addArrangedSubview(samplingSection)

        // Launch at Login Section
        launchAtLoginCheckbox = NSButton(checkboxWithTitle: "Launch at Login", target: self, action: #selector(launchAtLoginChanged))
        // Edge case #69: VoiceOver accessibility
        launchAtLoginCheckbox?.setAccessibilityLabel("Launch at Login")
        launchAtLoginCheckbox?.setAccessibilityHelp("Automatically start Pointer Designer when you log in")
        stackView.addArrangedSubview(launchAtLoginCheckbox!)

        // Reset Button
        let resetButton = NSButton(title: "Reset to Defaults", target: self, action: #selector(resetToDefaults))
        // Edge case #69 & #70: Accessibility and keyboard shortcut
        resetButton.setAccessibilityLabel("Reset to Defaults")
        resetButton.setAccessibilityHelp("Reset all settings to their default values")
        resetButton.keyEquivalent = "r"
        resetButton.keyEquivalentModifierMask = [.command]
        stackView.addArrangedSubview(resetButton)

        // Edge case #70: Set up keyboard navigation chain
        setupKeyViewLoop()
    }

    // Edge case #70: Set up logical keyboard navigation order
    private func setupKeyViewLoop() {
        guard let colorWell = colorWell,
              let contrastModePopup = contrastModePopup,
              let outlineWidthSlider = outlineWidthSlider,
              let samplingRateSlider = samplingRateSlider,
              let launchAtLoginCheckbox = launchAtLoginCheckbox else {
            return
        }

        // Set up the tab order: color well -> contrast mode -> outline width -> sampling rate -> launch at login
        colorWell.nextKeyView = contrastModePopup
        contrastModePopup.nextKeyView = outlineWidthSlider
        outlineWidthSlider.nextKeyView = samplingRateSlider
        samplingRateSlider.nextKeyView = launchAtLoginCheckbox
        // Loop back to start
        launchAtLoginCheckbox.nextKeyView = colorWell
    }

    private func createSection(title: String) -> NSStackView {
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 8

        let label = NSTextField(labelWithString: title)
        label.font = NSFont.boldSystemFont(ofSize: 13)
        stack.addArrangedSubview(label)

        return stack
    }

    private func loadSettings() {
        let settings = SettingsManager.shared.currentSettings

        colorWell?.color = NSColor(
            red: CGFloat(settings.cursorColor.red),
            green: CGFloat(settings.cursorColor.green),
            blue: CGFloat(settings.cursorColor.blue),
            alpha: CGFloat(settings.cursorColor.alpha)
        )

        switch settings.contrastMode {
        case .none: contrastModePopup?.selectItem(at: 0)
        case .autoInvert: contrastModePopup?.selectItem(at: 1)
        case .outline: contrastModePopup?.selectItem(at: 2)
        }

        outlineWidthSlider?.doubleValue = Double(settings.outlineWidth)
        samplingRateSlider?.doubleValue = Double(settings.samplingRate)
        launchAtLoginCheckbox?.state = settings.launchAtLogin ? .on : .off
    }

    @objc private func colorChanged() {
        guard let color = colorWell?.color else { return }
        // Edge case #51: Convert to sRGB color space before extracting components
        // NSColorWell may return colors in different color spaces (P3, Device RGB, etc.)
        guard let sRGBColor = color.usingColorSpace(.sRGB) else {
            // Fallback: try converting via RGB color space
            if let rgbColor = color.usingColorSpace(NSColorSpace.deviceRGB) {
                var settings = SettingsManager.shared.currentSettings
                settings.cursorColor = CursorColor(
                    red: Float(rgbColor.redComponent),
                    green: Float(rgbColor.greenComponent),
                    blue: Float(rgbColor.blueComponent),
                    alpha: Float(rgbColor.alphaComponent)
                )
                saveAndApply(settings)
            }
            return
        }

        var settings = SettingsManager.shared.currentSettings
        settings.cursorColor = CursorColor(
            red: Float(sRGBColor.redComponent),
            green: Float(sRGBColor.greenComponent),
            blue: Float(sRGBColor.blueComponent),
            alpha: Float(sRGBColor.alphaComponent)
        )
        saveAndApply(settings)
    }

    @objc private func contrastModeChanged() {
        var settings = SettingsManager.shared.currentSettings
        switch contrastModePopup?.indexOfSelectedItem {
        case 0: settings.contrastMode = .none
        case 1: settings.contrastMode = .autoInvert
        case 2: settings.contrastMode = .outline
        default: break
        }
        saveAndApply(settings)
    }

    @objc private func outlineWidthChanged() {
        var settings = SettingsManager.shared.currentSettings
        settings.outlineWidth = Float(outlineWidthSlider?.doubleValue ?? 2)
        // Edge case #69: Update accessibility value for VoiceOver
        outlineWidthSlider?.setAccessibilityValue("\(Int(outlineWidthSlider?.doubleValue ?? 2)) pixels")
        saveAndApply(settings)
    }

    @objc private func samplingRateChanged() {
        var settings = SettingsManager.shared.currentSettings
        settings.samplingRate = Int(samplingRateSlider?.doubleValue ?? 60)
        // Edge case #69: Update accessibility value for VoiceOver
        samplingRateSlider?.setAccessibilityValue("\(Int(samplingRateSlider?.doubleValue ?? 60)) Hz")
        saveAndApply(settings)
    }

    @objc private func launchAtLoginChanged() {
        var settings = SettingsManager.shared.currentSettings
        settings.launchAtLogin = launchAtLoginCheckbox?.state == .on
        SettingsManager.shared.save(settings)
        LaunchAtLoginManager.shared.setEnabled(settings.launchAtLogin)
    }

    @objc private func resetToDefaults() {
        let defaults = CursorSettings.defaults
        SettingsManager.shared.save(defaults)
        loadSettings()
        CursorEngine.shared.configure(with: defaults)
    }

    // Edge case #55: Refresh UI when settings change externally
    @objc private func settingsDidChange(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            self?.loadSettings()
        }
    }

    private func saveAndApply(_ settings: CursorSettings) {
        SettingsManager.shared.save(settings)
        CursorEngine.shared.configure(with: settings)
    }
}
