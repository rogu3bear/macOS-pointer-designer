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
        window.center()
        window.isReleasedWhenClosed = false

        self.init(window: window)

        preferencesView = PreferencesView(frame: window.contentView!.bounds)
        window.contentView = preferencesView
    }
}

final class PreferencesView: NSView {
    private var colorWell: NSColorWell?
    private var contrastModePopup: NSPopUpButton?
    private var outlineWidthSlider: NSSlider?
    private var launchAtLoginCheckbox: NSButton?
    private var samplingRateSlider: NSSlider?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupUI()
        loadSettings()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
        loadSettings()
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
        colorSection.addArrangedSubview(colorWell!)
        stackView.addArrangedSubview(colorSection)

        // Contrast Mode Section
        let contrastSection = createSection(title: "Contrast Mode")
        contrastModePopup = NSPopUpButton()
        contrastModePopup?.addItems(withTitles: ["None", "Auto-Invert", "Outline"])
        contrastModePopup?.target = self
        contrastModePopup?.action = #selector(contrastModeChanged)
        contrastSection.addArrangedSubview(contrastModePopup!)
        stackView.addArrangedSubview(contrastSection)

        // Outline Width Section
        let outlineSection = createSection(title: "Outline Width")
        outlineWidthSlider = NSSlider(value: 2, minValue: 1, maxValue: 5, target: self, action: #selector(outlineWidthChanged))
        outlineWidthSlider?.widthAnchor.constraint(equalToConstant: 200).isActive = true
        outlineSection.addArrangedSubview(outlineWidthSlider!)
        stackView.addArrangedSubview(outlineSection)

        // Sampling Rate Section
        let samplingSection = createSection(title: "Background Sampling Rate")
        samplingRateSlider = NSSlider(value: 60, minValue: 15, maxValue: 120, target: self, action: #selector(samplingRateChanged))
        samplingRateSlider?.widthAnchor.constraint(equalToConstant: 200).isActive = true
        let samplingLabel = NSTextField(labelWithString: "Higher = smoother, more CPU")
        samplingLabel.font = NSFont.systemFont(ofSize: 10)
        samplingLabel.textColor = .secondaryLabelColor
        samplingSection.addArrangedSubview(samplingRateSlider!)
        samplingSection.addArrangedSubview(samplingLabel)
        stackView.addArrangedSubview(samplingSection)

        // Launch at Login Section
        launchAtLoginCheckbox = NSButton(checkboxWithTitle: "Launch at Login", target: self, action: #selector(launchAtLoginChanged))
        stackView.addArrangedSubview(launchAtLoginCheckbox!)

        // Reset Button
        let resetButton = NSButton(title: "Reset to Defaults", target: self, action: #selector(resetToDefaults))
        stackView.addArrangedSubview(resetButton)
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
        var settings = SettingsManager.shared.currentSettings
        settings.cursorColor = CursorColor(
            red: Float(color.redComponent),
            green: Float(color.greenComponent),
            blue: Float(color.blueComponent),
            alpha: Float(color.alphaComponent)
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
        saveAndApply(settings)
    }

    @objc private func samplingRateChanged() {
        var settings = SettingsManager.shared.currentSettings
        settings.samplingRate = Int(samplingRateSlider?.doubleValue ?? 60)
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

    private func saveAndApply(_ settings: CursorSettings) {
        SettingsManager.shared.save(settings)
        CursorEngine.shared.configure(with: settings)
    }
}
