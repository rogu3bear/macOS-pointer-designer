import AppKit
import PointerDesignerCore

// MARK: - CursorPreviewView (Overlay for cursor rects)

/// Transparent overlay view that displays the custom cursor
/// Uses NSTrackingArea with cursorUpdate to override control cursors
final class CursorPreviewView: NSView {
    private var activeCursor: NSCursor?
    private var trackingArea: NSTrackingArea?

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupCursorObserver()
        setupTrackingArea()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCursorObserver()
        setupTrackingArea()
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    private func setupCursorObserver() {
        activeCursor = CursorEngine.shared.currentCursor
        NSLog("CursorPreviewView: Initial cursor = %@", activeCursor != nil ? "set" : "nil")

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(cursorDidUpdate),
            name: .cursorDidUpdate,
            object: nil
        )
    }

    private func setupTrackingArea() {
        let options: NSTrackingArea.Options = [.cursorUpdate, .activeAlways, .inVisibleRect]
        trackingArea = NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil)
        addTrackingArea(trackingArea!)
    }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        if let existing = trackingArea {
            removeTrackingArea(existing)
        }
        let options: NSTrackingArea.Options = [.cursorUpdate, .activeAlways, .inVisibleRect]
        trackingArea = NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil)
        addTrackingArea(trackingArea!)
    }

    @objc private func cursorDidUpdate(_ notification: Notification) {
        guard let cursor = notification.userInfo?["cursor"] as? NSCursor else { return }
        NSLog("CursorPreviewView: Cursor updated, setting new cursor")
        activeCursor = cursor
        // Immediately apply cursor
        cursor.set()
    }

    // Called by NSTrackingArea when cursor enters/moves in the view
    override func cursorUpdate(with event: NSEvent) {
        if let cursor = activeCursor {
            cursor.set()
            NSLog("CursorPreviewView: cursorUpdate - set custom cursor")
        } else {
            super.cursorUpdate(with: event)
        }
    }

    // Allow mouse events to pass through to underlying controls
    override func hitTest(_ point: NSPoint) -> NSView? {
        return nil
    }
}

// MARK: - PreferencesWindowController

final class PreferencesWindowController: NSWindowController {
    private var preferencesView: PreferencesView?
    private var cursorOverlay: CursorPreviewView?
    private let stateController: CursorStateController

    convenience init(stateController: CursorStateController = .shared) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 400),
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Cursor Designer Preferences"

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
        window.setAccessibilityLabel("Cursor Designer Preferences")
        window.setAccessibilityHelp("Configure cursor appearance and behavior settings")

        self.init(window: window, stateController: stateController)

        guard let contentView = window.contentView else { return }

        // Add preferences view
        preferencesView = PreferencesView(frame: contentView.bounds, stateController: self.stateController)
        preferencesView?.autoresizingMask = [.width, .height]
        contentView.addSubview(preferencesView!)

        // Add cursor overlay on top (for cursor rects to work above all controls)
        cursorOverlay = CursorPreviewView(frame: contentView.bounds)
        cursorOverlay?.autoresizingMask = [.width, .height]
        contentView.addSubview(cursorOverlay!)
        NSLog("PreferencesWindowController: Added CursorPreviewView overlay")

        // Edge case #70: Set initial first responder for keyboard navigation
        if let firstControl = preferencesView?.firstKeyView {
            window.initialFirstResponder = firstControl
        }
    }

    init(window: NSWindow, stateController: CursorStateController) {
        self.stateController = stateController
        super.init(window: window)
    }

    required init?(coder: NSCoder) {
        self.stateController = .shared
        super.init(coder: coder)
    }
}

final class PreferencesView: NSView {
    private var colorWell: NSColorWell?
    private var contrastModePopup: NSPopUpButton?
    private var outlineWidthSlider: NSSlider?
    private var launchAtLoginCheckbox: NSButton?
    private var samplingRateSlider: NSSlider?
    private var presetPopup: NSPopUpButton?
    private var glowCheckbox: NSButton?
    private var shadowCheckbox: NSButton?
    private var scaleSlider: NSSlider?
    private var scaleLabel: NSTextField?
    private var permissionStatusLabel: NSTextField?
    private var permissionButton: NSButton?

    // Use CursorStateController for business logic
    private let stateController: CursorStateController

    // Edge case #70: Track first key view for keyboard navigation
    var firstKeyView: NSView? {
        return colorWell
    }

    init(frame frameRect: NSRect, stateController: CursorStateController = .shared) {
        self.stateController = stateController
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
        self.stateController = .shared
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

        // Theme/Preset Section
        let presetSection = createSection(title: "Theme")
        let presetPopupView = NSPopUpButton()
        for preset in CursorPreset.allCases {
            presetPopupView.addItem(withTitle: preset.displayName)
        }
        presetPopupView.target = self
        presetPopupView.action = #selector(presetChanged)
        presetPopupView.setAccessibilityLabel("Cursor Theme")
        presetPopupView.setAccessibilityHelp("Choose a pre-designed cursor theme")
        presetPopup = presetPopupView
        presetSection.addArrangedSubview(presetPopupView)
        stackView.addArrangedSubview(presetSection)

        // Cursor Color Section
        let colorSection = createSection(title: "Cursor Color")
        let colorWellView = NSColorWell()
        colorWellView.color = .white
        colorWellView.target = self
        colorWellView.action = #selector(colorChanged)
        // Edge case #69: VoiceOver accessibility
        colorWellView.setAccessibilityLabel("Cursor Color")
        colorWellView.setAccessibilityHelp("Choose the color for your custom cursor")
        colorWell = colorWellView
        colorSection.addArrangedSubview(colorWellView)
        stackView.addArrangedSubview(colorSection)

        // Cursor Scale Section
        let scaleSection = createSection(title: "Cursor Size")
        let scaleRow = NSStackView()
        scaleRow.orientation = .horizontal
        scaleRow.spacing = 10

        let scaleSliderView = NSSlider(value: 1.0, minValue: 0.5, maxValue: 2.0, target: self, action: #selector(scaleChanged))
        scaleSliderView.isContinuous = true
        scaleSliderView.widthAnchor.constraint(equalToConstant: 150).isActive = true
        scaleSliderView.setAccessibilityLabel("Cursor Size")
        scaleSliderView.setAccessibilityHelp("Adjust cursor size from 50% to 200%")
        scaleSlider = scaleSliderView

        let scaleLabelView = NSTextField(labelWithString: "100%")
        scaleLabelView.font = NSFont.monospacedDigitSystemFont(ofSize: 11, weight: .regular)
        scaleLabel = scaleLabelView

        scaleRow.addArrangedSubview(scaleSliderView)
        scaleRow.addArrangedSubview(scaleLabelView)
        scaleSection.addArrangedSubview(scaleRow)
        stackView.addArrangedSubview(scaleSection)

        // Visual Effects Section
        let effectsSection = createSection(title: "Visual Effects")
        let glowCheck = NSButton(checkboxWithTitle: "Glow Effect", target: self, action: #selector(glowChanged))
        glowCheck.setAccessibilityLabel("Glow Effect")
        glowCheck.setAccessibilityHelp("Add a glowing aura around the cursor")
        glowCheckbox = glowCheck
        effectsSection.addArrangedSubview(glowCheck)

        let shadowCheck = NSButton(checkboxWithTitle: "Drop Shadow", target: self, action: #selector(shadowChanged))
        shadowCheck.setAccessibilityLabel("Drop Shadow")
        shadowCheck.setAccessibilityHelp("Add a shadow beneath the cursor")
        shadowCheckbox = shadowCheck
        effectsSection.addArrangedSubview(shadowCheck)
        stackView.addArrangedSubview(effectsSection)

        // Contrast Mode Section
        let contrastSection = createSection(title: "Contrast Mode")
        let contrastPopup = NSPopUpButton()
        contrastPopup.addItems(withTitles: ["None", "Auto-Invert", "Outline"])
        contrastPopup.target = self
        contrastPopup.action = #selector(contrastModeChanged)
        // Edge case #69: VoiceOver accessibility
        contrastPopup.setAccessibilityLabel("Contrast Mode")
        contrastPopup.setAccessibilityHelp("Select how the cursor adapts to different backgrounds: None, Auto-Invert, or Outline")
        contrastModePopup = contrastPopup
        contrastSection.addArrangedSubview(contrastPopup)
        stackView.addArrangedSubview(contrastSection)

        // Outline Width Section
        let outlineSection = createSection(title: "Outline Width")
        let outlineSlider = NSSlider(value: 2, minValue: 1, maxValue: 5, target: self, action: #selector(outlineWidthChanged))
        // Edge case #53: Disable continuous updates to avoid excessive saves
        outlineSlider.isContinuous = false
        outlineSlider.widthAnchor.constraint(equalToConstant: 200).isActive = true
        // Edge case #69: VoiceOver accessibility
        outlineSlider.setAccessibilityLabel("Outline Width")
        outlineSlider.setAccessibilityHelp("Adjust the width of the cursor outline from 1 to 5 pixels")
        outlineSlider.setAccessibilityValue("\(Int(outlineSlider.doubleValue)) pixels")
        outlineWidthSlider = outlineSlider
        outlineSection.addArrangedSubview(outlineSlider)
        stackView.addArrangedSubview(outlineSection)

        // Sampling Rate Section
        let samplingSection = createSection(title: "Background Sampling Rate")
        let samplingSlider = NSSlider(value: 60, minValue: 15, maxValue: 120, target: self, action: #selector(samplingRateChanged))
        // Edge case #53: Disable continuous updates to avoid excessive saves
        samplingSlider.isContinuous = false
        samplingSlider.widthAnchor.constraint(equalToConstant: 200).isActive = true
        // Edge case #69: VoiceOver accessibility
        samplingSlider.setAccessibilityLabel("Background Sampling Rate")
        samplingSlider.setAccessibilityHelp("Adjust how often the cursor samples the background. Higher values are smoother but use more CPU. Range: 15 to 120 Hz")
        samplingSlider.setAccessibilityValue("\(Int(samplingSlider.doubleValue)) Hz")
        samplingRateSlider = samplingSlider
        let samplingLabel = NSTextField(labelWithString: "Higher = smoother, more CPU")
        samplingLabel.font = NSFont.systemFont(ofSize: 10)
        samplingLabel.textColor = .secondaryLabelColor
        samplingSection.addArrangedSubview(samplingSlider)
        samplingSection.addArrangedSubview(samplingLabel)
        stackView.addArrangedSubview(samplingSection)

        // Permission Status Section
        let permissionSection = createSection(title: "Screen Recording")
        let permissionRow = NSStackView()
        permissionRow.orientation = .horizontal
        permissionRow.spacing = 10

        let statusLabel = NSTextField(labelWithString: "")
        statusLabel.font = NSFont.systemFont(ofSize: 12)
        permissionStatusLabel = statusLabel

        let openSettingsButton = NSButton(title: "Open System Settings", target: self, action: #selector(openPermissionSettings))
        openSettingsButton.bezelStyle = .rounded
        openSettingsButton.controlSize = .small
        openSettingsButton.setAccessibilityLabel("Open Screen Recording Settings")
        permissionButton = openSettingsButton

        permissionRow.addArrangedSubview(statusLabel)
        permissionRow.addArrangedSubview(openSettingsButton)
        permissionSection.addArrangedSubview(permissionRow)

        let permissionNote = NSTextField(labelWithString: "Required for Auto-Invert and Outline contrast modes")
        permissionNote.font = NSFont.systemFont(ofSize: 10)
        permissionNote.textColor = .secondaryLabelColor
        permissionSection.addArrangedSubview(permissionNote)
        stackView.addArrangedSubview(permissionSection)

        // Launch at Login Section
        let loginCheckbox = NSButton(checkboxWithTitle: "Launch at Login", target: self, action: #selector(launchAtLoginChanged))
        // Edge case #69: VoiceOver accessibility
        loginCheckbox.setAccessibilityLabel("Launch at Login")
        loginCheckbox.setAccessibilityHelp("Automatically start Cursor Designer when you log in")
        launchAtLoginCheckbox = loginCheckbox
        stackView.addArrangedSubview(loginCheckbox)

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
        let settings = stateController.currentSettings

        // Preset
        if let index = CursorPreset.allCases.firstIndex(of: settings.preset) {
            presetPopup?.selectItem(at: index)
        }

        // Color
        colorWell?.color = NSColor(
            red: CGFloat(settings.cursorColor.red),
            green: CGFloat(settings.cursorColor.green),
            blue: CGFloat(settings.cursorColor.blue),
            alpha: CGFloat(settings.cursorColor.alpha)
        )

        // Scale
        scaleSlider?.doubleValue = Double(settings.cursorScale)
        updateScaleLabel()

        // Visual effects
        glowCheckbox?.state = settings.glowEnabled ? .on : .off
        shadowCheckbox?.state = settings.shadowEnabled ? .on : .off

        // Contrast mode
        switch settings.contrastMode {
        case .none: contrastModePopup?.selectItem(at: 0)
        case .autoInvert: contrastModePopup?.selectItem(at: 1)
        case .outline: contrastModePopup?.selectItem(at: 2)
        }

        outlineWidthSlider?.doubleValue = Double(settings.outlineWidth)
        samplingRateSlider?.doubleValue = Double(settings.samplingRate)
        launchAtLoginCheckbox?.state = stateController.isLaunchAtLoginEnabled ? .on : .off

        // Update permission status
        updatePermissionStatus()
    }

    private func updatePermissionStatus() {
        stateController.refreshPermissionState()
        let hasPermission = stateController.hasScreenRecordingPermission

        if hasPermission {
            permissionStatusLabel?.stringValue = "✓ Granted"
            permissionStatusLabel?.textColor = .systemGreen
            permissionButton?.isHidden = true
        } else {
            permissionStatusLabel?.stringValue = "✗ Not granted"
            permissionStatusLabel?.textColor = .systemOrange
            permissionButton?.isHidden = false
        }
    }

    private func updateScaleLabel() {
        let scale = scaleSlider?.doubleValue ?? 1.0
        scaleLabel?.stringValue = "\(Int(scale * 100))%"
    }

    @objc private func colorChanged() {
        guard let color = colorWell?.color else { return }
        // Edge case #51: Convert to sRGB color space before extracting components
        // NSColorWell may return colors in different color spaces (P3, Device RGB, etc.)
        guard let sRGBColor = color.usingColorSpace(.sRGB) else {
            // Fallback: try converting via RGB color space
            if let rgbColor = color.usingColorSpace(NSColorSpace.deviceRGB) {
                let cursorColor = CursorColor(
                    red: Float(rgbColor.redComponent),
                    green: Float(rgbColor.greenComponent),
                    blue: Float(rgbColor.blueComponent),
                    alpha: Float(rgbColor.alphaComponent)
                )
                stateController.setCursorColor(cursorColor)
            }
            return
        }

        let cursorColor = CursorColor(
            red: Float(sRGBColor.redComponent),
            green: Float(sRGBColor.greenComponent),
            blue: Float(sRGBColor.blueComponent),
            alpha: Float(sRGBColor.alphaComponent)
        )
        stateController.setCursorColor(cursorColor)
    }

    @objc private func presetChanged() {
        guard let index = presetPopup?.indexOfSelectedItem,
              index < CursorPreset.allCases.count else { return }
        let preset = CursorPreset.allCases[index]
        stateController.updateSettings { settings in
            settings.preset = preset
        }
        // Reload to apply preset defaults
        loadSettings()
    }

    @objc private func scaleChanged() {
        let scale = Float(scaleSlider?.doubleValue ?? 1.0)
        updateScaleLabel()
        stateController.updateSettings { settings in
            settings.cursorScale = scale
        }
    }

    @objc private func glowChanged() {
        let enabled = glowCheckbox?.state == .on
        stateController.updateSettings { settings in
            settings.glowEnabled = enabled
        }
    }

    @objc private func shadowChanged() {
        let enabled = shadowCheckbox?.state == .on
        stateController.updateSettings { settings in
            settings.shadowEnabled = enabled
        }
    }

    @objc private func contrastModeChanged() {
        let mode: ContrastMode
        switch contrastModePopup?.indexOfSelectedItem {
        case 0: mode = .none
        case 1: mode = .autoInvert
        case 2: mode = .outline
        default: return
        }
        stateController.setContrastMode(mode)
    }

    @objc private func outlineWidthChanged() {
        let width = Float(outlineWidthSlider?.doubleValue ?? 2)
        // Edge case #69: Update accessibility value for VoiceOver
        outlineWidthSlider?.setAccessibilityValue("\(Int(outlineWidthSlider?.doubleValue ?? 2)) pixels")
        stateController.setOutlineWidth(width)
    }

    @objc private func samplingRateChanged() {
        let rate = Int(samplingRateSlider?.doubleValue ?? 60)
        // Edge case #69: Update accessibility value for VoiceOver
        samplingRateSlider?.setAccessibilityValue("\(rate) Hz")
        stateController.updateSettings { settings in
            settings.samplingRate = rate
        }
    }

    @objc private func launchAtLoginChanged() {
        let enabled = launchAtLoginCheckbox?.state == .on
        stateController.setLaunchAtLogin(enabled)
    }

    @objc private func resetToDefaults() {
        stateController.resetToDefaults()
        loadSettings()
    }

    @objc private func openPermissionSettings() {
        PermissionManager.shared.openSystemPreferences(for: .screenRecording)
    }

    // Edge case #55: Refresh UI when settings change externally
    @objc private func settingsDidChange(_ notification: Notification) {
        DispatchQueue.main.async { [weak self] in
            self?.stateController.reloadSettings()
            self?.loadSettings()
        }
    }
}
