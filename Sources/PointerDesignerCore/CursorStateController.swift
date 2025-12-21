import Foundation
import Combine

/// Business logic controller for cursor state management
/// Extracts logic from UI layer for better testability and separation of concerns
public final class CursorStateController: ObservableObject {
    /// Shared instance for UI components to use
    /// This is the single point where singleton dependencies are resolved
    public static let shared = CursorStateController(
        settingsService: SettingsManager.shared,
        cursorService: CursorEngine.shared,
        launchAtLoginService: LaunchAtLoginManager.shared,
        permissionService: PermissionManager.shared
    )

    // Injected dependencies
    private let settingsService: SettingsService
    private let cursorService: CursorService
    private let launchAtLoginService: LaunchAtLoginService
    private let permissionService: PermissionService

    // Published state for UI binding
    @Published public private(set) var isEnabled: Bool = false
    @Published public private(set) var currentSettings: CursorSettings
    @Published public private(set) var isLaunchAtLoginEnabled: Bool = false
    @Published public private(set) var hasScreenRecordingPermission: Bool = false

    /// Initializer for dependency injection (testing)
    public init(
        settingsService: SettingsService,
        cursorService: CursorService,
        launchAtLoginService: LaunchAtLoginService,
        permissionService: PermissionService
    ) {
        self.settingsService = settingsService
        self.cursorService = cursorService
        self.launchAtLoginService = launchAtLoginService
        self.permissionService = permissionService
        self.currentSettings = settingsService.currentSettings
        self.isEnabled = settingsService.currentSettings.isEnabled
        self.isLaunchAtLoginEnabled = launchAtLoginService.isEnabled
        self.hasScreenRecordingPermission = permissionService.hasScreenRecordingPermission
    }

    // MARK: - Public API

    /// Toggle cursor customization on/off
    public func toggleEnabled() {
        setEnabled(!isEnabled)
    }

    /// Set cursor customization enabled state
    public func setEnabled(_ enabled: Bool) {
        isEnabled = enabled

        var settings = currentSettings
        settings.isEnabled = enabled
        updateSettings(settings)

        if enabled {
            cursorService.start()
        } else {
            cursorService.stop()
        }
    }

    /// Set the cursor color
    public func setCursorColor(_ color: CursorColor) {
        var settings = currentSettings
        settings.cursorColor = color
        updateSettings(settings)
    }

    /// Set the contrast mode
    public func setContrastMode(_ mode: ContrastMode) {
        var settings = currentSettings
        settings.contrastMode = mode
        updateSettings(settings)
    }

    /// Set outline color
    public func setOutlineColor(_ color: CursorColor?) {
        var settings = currentSettings
        settings.outlineColor = color
        updateSettings(settings)
    }

    /// Set outline width
    public func setOutlineWidth(_ width: Float) {
        var settings = currentSettings
        settings.outlineWidth = width
        updateSettings(settings)
    }

    /// Set brightness threshold
    public func setBrightnessThreshold(_ threshold: Float) {
        var settings = currentSettings
        settings.brightnessThreshold = threshold
        updateSettings(settings)
    }

    /// Set hysteresis value
    public func setHysteresis(_ hysteresis: Float) {
        var settings = currentSettings
        settings.hysteresis = hysteresis
        updateSettings(settings)
    }

    /// Apply a cursor preset/theme
    public func applyPreset(_ preset: CursorPreset) {
        var settings = currentSettings
        settings.applyPreset(preset)
        updateSettings(settings)
    }

    /// Set glow enabled
    public func setGlowEnabled(_ enabled: Bool) {
        var settings = currentSettings
        settings.glowEnabled = enabled
        if enabled {
            settings.preset = .custom
        }
        updateSettings(settings)
    }

    /// Set shadow enabled
    public func setShadowEnabled(_ enabled: Bool) {
        var settings = currentSettings
        settings.shadowEnabled = enabled
        if enabled {
            settings.preset = .custom
        }
        updateSettings(settings)
    }

    /// Set cursor scale
    public func setCursorScale(_ scale: Float) {
        var settings = currentSettings
        settings.cursorScale = scale
        settings.preset = .custom
        updateSettings(settings)
    }

    /// Update settings with a transform block
    public func updateSettings(_ transform: (inout CursorSettings) -> Void) {
        var settings = currentSettings
        transform(&settings)
        updateSettings(settings)
    }

    /// Reset all settings to defaults
    public func resetToDefaults() {
        settingsService.reset()
        currentSettings = settingsService.currentSettings
        isEnabled = currentSettings.isEnabled
        cursorService.configure(with: currentSettings)

        if isEnabled {
            cursorService.start()
        } else {
            cursorService.stop()
        }
    }

    /// Set launch at login preference
    @discardableResult
    public func setLaunchAtLogin(_ enabled: Bool) -> Result<Void, LaunchAtLoginManager.LaunchAtLoginError> {
        let result = launchAtLoginService.setEnabled(enabled)
        if case .success = result {
            isLaunchAtLoginEnabled = enabled
        }
        return result
    }

    /// Refresh permission state
    public func refreshPermissionState() {
        hasScreenRecordingPermission = permissionService.hasScreenRecordingPermission
    }

    /// Reload settings from storage
    public func reloadSettings() {
        settingsService.reload()
        currentSettings = settingsService.currentSettings
        isEnabled = currentSettings.isEnabled
        cursorService.configure(with: currentSettings)
    }

    // MARK: - Private Helpers

    private func updateSettings(_ settings: CursorSettings) {
        currentSettings = settings
        settingsService.save(settings)
        cursorService.configure(with: settings)
    }
}
