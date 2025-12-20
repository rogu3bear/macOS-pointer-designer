import Foundation
import ServiceManagement

/// Manages launch at login functionality
public final class LaunchAtLoginManager {
    public static let shared = LaunchAtLoginManager()

    private init() {}

    /// Check if app is set to launch at login
    public var isEnabled: Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        } else {
            return legacyIsEnabled
        }
    }

    /// Enable or disable launch at login
    public func setEnabled(_ enabled: Bool) {
        if #available(macOS 13.0, *) {
            setEnabledModern(enabled)
        } else {
            setEnabledLegacy(enabled)
        }
    }

    // MARK: - Modern (macOS 13+)

    @available(macOS 13.0, *)
    private func setEnabledModern(_ enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Failed to set launch at login: \(error)")
        }
    }

    // MARK: - Legacy (macOS 12 and earlier)

    private var legacyIsEnabled: Bool {
        guard let loginItems = LSSharedFileListCreate(
            nil,
            kLSSharedFileListSessionLoginItems.takeRetainedValue(),
            nil
        )?.takeRetainedValue() else {
            return false
        }

        guard let items = LSSharedFileListCopySnapshot(loginItems, nil)?.takeRetainedValue() as? [LSSharedFileListItem] else {
            return false
        }

        let bundleURL = Bundle.main.bundleURL

        for item in items {
            if let itemURL = LSSharedFileListItemCopyResolvedURL(item, 0, nil)?.takeRetainedValue() as URL?,
               itemURL == bundleURL {
                return true
            }
        }

        return false
    }

    private func setEnabledLegacy(_ enabled: Bool) {
        guard let loginItems = LSSharedFileListCreate(
            nil,
            kLSSharedFileListSessionLoginItems.takeRetainedValue(),
            nil
        )?.takeRetainedValue() else {
            return
        }

        let bundleURL = Bundle.main.bundleURL as CFURL

        if enabled {
            LSSharedFileListInsertItemURL(
                loginItems,
                kLSSharedFileListItemLast.takeRetainedValue(),
                nil,
                nil,
                bundleURL,
                nil,
                nil
            )
        } else {
            guard let items = LSSharedFileListCopySnapshot(loginItems, nil)?.takeRetainedValue() as? [LSSharedFileListItem] else {
                return
            }

            for item in items {
                if let itemURL = LSSharedFileListItemCopyResolvedURL(item, 0, nil)?.takeRetainedValue() as URL?,
                   itemURL == Bundle.main.bundleURL {
                    LSSharedFileListItemRemove(loginItems, item)
                    break
                }
            }
        }
    }
}
