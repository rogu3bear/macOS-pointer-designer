import Foundation
import AppKit
import CoreGraphics

// MARK: - Settings Service Protocol

/// Protocol for settings persistence and management
public protocol SettingsService: AnyObject {
    /// Current application settings
    var currentSettings: CursorSettings { get }

    /// Save settings to persistent storage
    func save(_ settings: CursorSettings)

    /// Reset settings to defaults
    func reset()

    /// Reload settings from storage
    func reload()

    /// Export settings as Data for backup/sharing
    func exportSettings() -> Data?

    /// Import settings from Data
    func importSettings(from data: Data) -> Bool

    /// Storage diagnostics
    var storageStatus: [String: Any] { get }
}

// MARK: - Display Service Protocol

/// Protocol for display/screen management
public protocol DisplayService: AnyObject {
    /// Get display info for a point
    func displayInfo(for point: CGPoint) -> DisplayManager.DisplayInfo?

    /// Get scale factor for a point
    func scaleFactor(for point: CGPoint) -> CGFloat

    /// Convert NSPoint to CGPoint for correct display
    func convertToCGPoint(_ nsPoint: NSPoint) -> CGPoint

    /// Check if point is on a valid screen
    func isPointOnScreen(_ point: CGPoint) -> Bool

    /// Get safe sampling rect within screen bounds
    func safeSamplingRect(centeredAt point: CGPoint, size: CGFloat) -> CGRect

    /// Check if display at point supports HDR
    func isHDRDisplay(at point: CGPoint) -> Bool

    /// Refresh cached display information
    func refreshDisplayInfo()
}

// MARK: - Permission Service Protocol

/// Protocol for system permission management
public protocol PermissionService: AnyObject {
    /// Check if screen recording permission is granted
    var hasScreenRecordingPermission: Bool { get }

    /// Check if accessibility permission is granted
    var hasAccessibilityPermission: Bool { get }

    /// Check if background color detection is available
    var isBackgroundDetectionAvailable: Bool { get }

    /// Get status for a specific permission
    func status(for permission: PermissionManager.Permission) -> PermissionManager.PermissionStatus

    /// Request a permission
    func request(_ permission: PermissionManager.Permission, completion: @escaping (PermissionManager.PermissionStatus) -> Void)

    /// Open system preferences for a permission
    func openSystemPreferences(for permission: PermissionManager.Permission)

    /// Prompt user to grant permission with explanation
    func promptForPermission(_ permission: PermissionManager.Permission, from window: NSWindow?)

    /// Safely capture screen at rect (returns nil if no permission)
    func safeScreenCapture(rect: CGRect) -> CGImage?
}

// MARK: - Helper Service Protocol

/// Protocol for privileged helper tool management
public protocol HelperService: AnyObject {
    /// Check if helper tool is installed
    var isHelperInstalled: Bool { get }

    /// Install the helper tool
    func installHelper(completion: @escaping (Bool, Error?) -> Void)

    /// Uninstall the helper tool
    func uninstallHelper(completion: @escaping (Bool, Error?) -> Void)

    /// Set system-wide cursor
    func setCursor(_ image: NSImage)

    /// Restore system default cursor
    func restoreSystemCursor()
}

// MARK: - Cursor Service Protocol

/// Protocol for cursor engine control
public protocol CursorService: AnyObject {
    /// Configure the cursor engine with settings
    func configure(with settings: CursorSettings)

    /// Start cursor customization
    func start()

    /// Stop cursor customization
    func stop()

    /// Refresh cursor appearance
    func refresh()

    /// Check if contrast features are available
    var canUseContrastFeatures: Bool { get }
}

// MARK: - Launch At Login Service Protocol

/// Protocol for launch at login management
public protocol LaunchAtLoginService: AnyObject {
    /// Check if launch at login is enabled
    var isEnabled: Bool { get }

    /// Enable or disable launch at login
    @discardableResult
    func setEnabled(_ enabled: Bool) -> Result<Void, LaunchAtLoginManager.LaunchAtLoginError>

    /// Enable or disable with async completion
    func setEnabled(_ enabled: Bool, completion: @escaping (Result<Void, LaunchAtLoginManager.LaunchAtLoginError>) -> Void)

    /// Get diagnostic information
    var diagnosticInfo: [String: Any] { get }
}

// MARK: - Process Lifecycle Service Protocol

/// Protocol for application process lifecycle management
public protocol ProcessLifecycleService: AnyObject {
    /// Check if the lifecycle manager is running
    var isRunning: Bool { get }

    /// Perform startup sequence
    /// Returns false if app should terminate (e.g., another instance running)
    func startup() -> Bool

    /// Perform clean shutdown
    func shutdown()

    /// Register a handler to be called on termination
    func registerForTermination(_ handler: @escaping () -> Void)
}

// MARK: - System Integration Service Protocol

/// Protocol for system state integration (sleep/wake, fullscreen, etc.)
public protocol SystemIntegrationService: AnyObject {
    /// Check if another cursor customization app is running
    var isOtherCursorAppRunning: Bool { get }

    /// Get list of running cursor apps
    var runningCursorApps: [String] { get }

    /// Check if screen saver is active
    var screenSaverActive: Bool { get }

    /// Check if a fullscreen app is active
    var fullScreenActive: Bool { get }

    /// Check if app should yield to system cursor features
    var shouldYieldToSystemFeatures: Bool { get }

    /// Register a custom cursor app bundle ID for conflict detection
    func registerCursorApp(_ bundleID: String)

    /// Record cursor position for shake detection
    func recordCursorPosition(_ point: CGPoint)

    /// Check if shake-to-locate is active
    func isShakeToLocateActive() -> Bool
}
