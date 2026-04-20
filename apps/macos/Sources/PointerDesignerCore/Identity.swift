import Foundation

/// Single source of truth for all identity strings used across the app.
/// These values MUST match Info.plist files, launchd plists, and entitlements.
///
/// WARNING: Changing these values will break:
/// - XPC communication between app and helper
/// - SMAppService registration
/// - UserDefaults storage
/// - Existing user preferences
///
/// If you need to change identifiers, you must also update:
/// - Sources/PointerDesigner/Resources/Info.plist
/// - Sources/PointerDesignerHelper/Resources/Info.plist
/// - Sources/PointerDesigner/Resources/com.pointerdesigner.helper.plist
/// - Casks/cursor-designer-osx.rb
public enum Identity {
    // MARK: - Bundle Identifiers

    /// Main application bundle identifier
    /// Must match CFBundleIdentifier in Sources/PointerDesigner/Resources/Info.plist
    public static let appBundleID = "com.pointerdesigner.app"

    /// Alternate app bundle ID (for development/unsigned builds)
    public static let appBundleIDAlternate = "com.pointerdesigner"

    /// Helper tool bundle identifier
    /// Must match CFBundleIdentifier in Sources/PointerDesignerHelper/Resources/Info.plist
    public static let helperBundleID = "com.pointerdesigner.helper"

    // MARK: - XPC / Launchd

    /// XPC mach service name - MUST equal helperBundleID
    /// Used by NSXPCListener and NSXPCConnection
    public static let xpcMachServiceName = "com.pointerdesigner.helper"

    /// Launchd label for the helper daemon - MUST equal helperBundleID
    /// Must match Label in com.pointerdesigner.helper.plist
    public static let launchdLabel = "com.pointerdesigner.helper"

    /// SMAppService plist filename
    public static let helperPlistName = "com.pointerdesigner.helper.plist"

    // MARK: - File Paths

    /// Helper tool install path
    public static let helperToolPath = "/Library/PrivilegedHelperTools/com.pointerdesigner.helper"

    /// Helper PID file path
    public static let helperPIDPath = "/tmp/com.pointerdesigner.helper.pid"

    /// Cursor temp file prefix
    public static let cursorTempPrefix = "com.pointerdesigner.cursor"

    /// Session file name
    public static let sessionFileName = "com.pointerdesigner.session.json"

    // MARK: - UserDefaults Keys

    /// Settings storage key
    public static let settingsKey = "com.pointerdesigner.settings"

    /// Backup settings key
    public static let settingsBackupKey = "com.pointerdesigner.settings.backup"

    /// Legacy color key (for migration)
    public static let legacyCursorColorKey = "com.pointerdesigner.cursorColor"

    /// Legacy enabled key (for migration)
    public static let legacyEnabledKey = "com.pointerdesigner.enabled"

    // MARK: - Notification Names

    /// Settings changed notification
    public static let settingsDidChangeNotification = "com.pointerdesigner.settingsDidChange"

    /// Settings save failed notification
    public static let settingsSaveFailedNotification = "com.pointerdesigner.settingsSaveFailed"

    /// Cursor updated notification (distributed)
    public static let cursorUpdatedNotification = "com.pointerdesigner.cursorUpdated"

    /// Cursor restored notification (distributed)
    public static let cursorRestoredNotification = "com.pointerdesigner.cursorRestored"

    /// Process lifecycle started notification
    public static let processLifecycleStartedNotification = "com.pointerdesigner.lifecycleStarted"

    /// Process lifecycle shutdown notification
    public static let processLifecycleShutdownNotification = "com.pointerdesigner.lifecycleShutdown"

    /// Display configuration changed notification
    public static let displayConfigurationDidChangeNotification = "com.pointerdesigner.displayConfigurationDidChange"

    /// Helper became unresponsive notification
    public static let helperBecameUnresponsiveNotification = "com.pointerdesigner.helperUnresponsive"

    /// Helper recovered notification
    public static let helperRecoveredNotification = "com.pointerdesigner.helperRecovered"

    /// Launch at login changed notification
    public static let launchAtLoginChangedNotification = "com.pointerdesigner.launchAtLoginChanged"

    /// Cursor app conflict detected notification
    public static let cursorAppConflictDetectedNotification = "com.pointerdesigner.cursorAppConflict"

    /// Screen saver state changed notification
    public static let screenSaverStateChangedNotification = "com.pointerdesigner.screenSaverStateChanged"

    /// Full screen state changed notification
    public static let fullScreenStateChangedNotification = "com.pointerdesigner.fullScreenStateChanged"

    /// Session state changed notification
    public static let sessionStateChangedNotification = "com.pointerdesigner.sessionStateChanged"

    // MARK: - Dispatch Queue Labels

    /// XPC queue label
    public static let xpcQueueLabel = "com.pointerdesigner.xpc"

    /// Cursor engine queue label
    public static let cursorEngineQueueLabel = "com.pointerdesigner.cursorengine"

    /// Permissions queue label
    public static let permissionsQueueLabel = "com.pointerdesigner.permissions"

    /// Signal handler queue label
    public static let signalHandlerQueueLabel = "com.pointerdesigner.signalhandler"

    /// Watchdog queue label
    public static let watchdogQueueLabel = "com.pointerdesigner.watchdog"

    /// Orphan cleaner queue label
    public static let orphanCleanerQueueLabel = "com.pointerdesigner.orphancleaner"

    // MARK: - App Support Directory Names

    /// Current app support directory name
    public static let appSupportDirName = "CursorDesigner"

    /// Legacy app support directory name (for migration)
    public static let legacyAppSupportDirName = "PointerDesigner"

    // MARK: - Validation

    /// Valid bundle IDs that the helper will accept connections from
    public static let validClientBundleIDs = [appBundleID, appBundleIDAlternate]

    /// Verify all identity invariants hold
    /// Call this during development to catch misconfigurations
    public static func verifyInvariants() -> [String] {
        var errors: [String] = []

        // XPC service name must equal helper bundle ID
        if xpcMachServiceName != helperBundleID {
            errors.append("xpcMachServiceName (\(xpcMachServiceName)) != helperBundleID (\(helperBundleID))")
        }

        // Launchd label must equal helper bundle ID
        if launchdLabel != helperBundleID {
            errors.append("launchdLabel (\(launchdLabel)) != helperBundleID (\(helperBundleID))")
        }

        // No empty strings
        if appBundleID.isEmpty { errors.append("appBundleID is empty") }
        if helperBundleID.isEmpty { errors.append("helperBundleID is empty") }
        if xpcMachServiceName.isEmpty { errors.append("xpcMachServiceName is empty") }
        if launchdLabel.isEmpty { errors.append("launchdLabel is empty") }

        // No whitespace
        if appBundleID.contains(where: { $0.isWhitespace }) {
            errors.append("appBundleID contains whitespace")
        }
        if helperBundleID.contains(where: { $0.isWhitespace }) {
            errors.append("helperBundleID contains whitespace")
        }

        return errors
    }
}
