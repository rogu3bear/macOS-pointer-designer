import Foundation
import ServiceManagement

/// Manages launch at login functionality
/// Fixes edge case #50: Proper error handling for SMAppService
public final class LaunchAtLoginManager {
    public static let shared = LaunchAtLoginManager()

    public enum LaunchAtLoginError: Error, LocalizedError {
        case registrationFailed(Error)
        case unregistrationFailed(Error)
        case notSupported
        case requiresFullDiskAccess

        public var errorDescription: String? {
            switch self {
            case .registrationFailed(let error):
                return "Failed to enable launch at login: \(error.localizedDescription)"
            case .unregistrationFailed(let error):
                return "Failed to disable launch at login: \(error.localizedDescription)"
            case .notSupported:
                return "Launch at login is not supported on this system"
            case .requiresFullDiskAccess:
                return "Launch at login requires Full Disk Access permission"
            }
        }
    }

    private init() {}

    /// Check if app is set to launch at login
    public var isEnabled: Bool {
        if #available(macOS 13.0, *) {
            return SMAppService.mainApp.status == .enabled
        } else {
            return legacyIsEnabled
        }
    }

    /// Get detailed status
    @available(macOS 13.0, *)
    public var status: SMAppService.Status {
        return SMAppService.mainApp.status
    }

    /// Enable or disable launch at login with error handling
    /// Edge case #50: Returns Result instead of swallowing errors
    @discardableResult
    public func setEnabled(_ enabled: Bool) -> Result<Void, LaunchAtLoginError> {
        if #available(macOS 13.0, *) {
            return setEnabledModern(enabled)
        } else {
            return setEnabledLegacy(enabled)
        }
    }

    /// Enable or disable with completion handler (for async contexts)
    public func setEnabled(_ enabled: Bool, completion: @escaping (Result<Void, LaunchAtLoginError>) -> Void) {
        DispatchQueue.global(qos: .userInitiated).async {
            let result = self.setEnabled(enabled)
            DispatchQueue.main.async {
                completion(result)
            }
        }
    }

    // MARK: - Modern (macOS 13+)

    @available(macOS 13.0, *)
    private func setEnabledModern(_ enabled: Bool) -> Result<Void, LaunchAtLoginError> {
        let service = SMAppService.mainApp

        do {
            if enabled {
                // Check current status first
                if service.status == .enabled {
                    return .success(())
                }

                try service.register()

                // Verify registration succeeded
                if service.status == .enabled {
                    NotificationCenter.default.post(name: .launchAtLoginChanged, object: nil, userInfo: ["enabled": true])
                    return .success(())
                } else {
                    return .failure(.registrationFailed(NSError(domain: "SMAppService", code: -1, userInfo: [NSLocalizedDescriptionKey: "Registration reported success but status is not enabled"])))
                }
            } else {
                // Check current status first
                if service.status == .notRegistered || service.status == .notFound {
                    return .success(())
                }

                try service.unregister()
                NotificationCenter.default.post(name: .launchAtLoginChanged, object: nil, userInfo: ["enabled": false])
                return .success(())
            }
        } catch {
            // Edge case #50: Provide detailed error information
            if enabled {
                return .failure(.registrationFailed(error))
            } else {
                return .failure(.unregistrationFailed(error))
            }
        }
    }

    // MARK: - Legacy (macOS 12 and earlier)
    // Note: These use deprecated LSSharedFileList APIs (deprecated in macOS 10.11)
    // but are required for backward compatibility with pre-macOS 13 systems.

    @available(macOS, deprecated: 10.11, message: "Using deprecated LSSharedFileList for macOS 12 compatibility")
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

    @available(macOS, deprecated: 10.11, message: "Using deprecated LSSharedFileList for macOS 12 compatibility")
    private func setEnabledLegacy(_ enabled: Bool) -> Result<Void, LaunchAtLoginError> {
        guard let loginItems = LSSharedFileListCreate(
            nil,
            kLSSharedFileListSessionLoginItems.takeRetainedValue(),
            nil
        )?.takeRetainedValue() else {
            return .failure(.notSupported)
        }

        let bundleURL = Bundle.main.bundleURL as CFURL

        if enabled {
            let result = LSSharedFileListInsertItemURL(
                loginItems,
                kLSSharedFileListItemLast.takeRetainedValue(),
                nil,
                nil,
                bundleURL,
                nil,
                nil
            )

            if result != nil {
                NotificationCenter.default.post(name: .launchAtLoginChanged, object: nil, userInfo: ["enabled": true])
                return .success(())
            } else {
                return .failure(.registrationFailed(NSError(domain: "LSSharedFileList", code: -1, userInfo: nil)))
            }
        } else {
            guard let items = LSSharedFileListCopySnapshot(loginItems, nil)?.takeRetainedValue() as? [LSSharedFileListItem] else {
                return .failure(.notSupported)
            }

            for item in items {
                if let itemURL = LSSharedFileListItemCopyResolvedURL(item, 0, nil)?.takeRetainedValue() as URL?,
                   itemURL == Bundle.main.bundleURL {
                    LSSharedFileListItemRemove(loginItems, item)
                    NotificationCenter.default.post(name: .launchAtLoginChanged, object: nil, userInfo: ["enabled": false])
                    return .success(())
                }
            }

            // Item not found, which is fine for disabling
            return .success(())
        }
    }

    // MARK: - Diagnostics

    /// Get diagnostic information about launch at login status
    public var diagnosticInfo: [String: Any] {
        var info: [String: Any] = [
            "isEnabled": isEnabled,
            "bundleURL": Bundle.main.bundleURL.path
        ]

        if #available(macOS 13.0, *) {
            let status = SMAppService.mainApp.status
            info["status"] = String(describing: status)
            info["statusRaw"] = status.rawValue
        }

        return info
    }
}

// MARK: - Notifications

public extension Notification.Name {
    static let launchAtLoginChanged = Notification.Name("com.pointerdesigner.launchAtLoginChanged")
}
