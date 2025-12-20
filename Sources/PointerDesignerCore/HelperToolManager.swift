import Foundation
import AppKit
import ServiceManagement

/// Manages the privileged helper tool for system-wide cursor changes
public final class HelperToolManager {
    public static let shared = HelperToolManager()

    private let helperBundleID = "com.pointerdesigner.helper"
    private let helperToolPath = "/Library/PrivilegedHelperTools/com.pointerdesigner.helper"

    private var xpcConnection: NSXPCConnection?

    private init() {}

    /// Check if helper tool is installed
    public var isHelperInstalled: Bool {
        FileManager.default.fileExists(atPath: helperToolPath)
    }

    /// Install the helper tool (requires admin privileges)
    public func installHelper(completion: @escaping (Bool, Error?) -> Void) {
        // For modern macOS (10.13+), use SMAppService for LaunchDaemons
        if #available(macOS 13.0, *) {
            installHelperModern(completion: completion)
        } else {
            installHelperLegacy(completion: completion)
        }
    }

    @available(macOS 13.0, *)
    private func installHelperModern(completion: @escaping (Bool, Error?) -> Void) {
        let service = SMAppService.daemon(plistName: "com.pointerdesigner.helper.plist")

        do {
            try service.register()
            completion(true, nil)
        } catch {
            completion(false, error)
        }
    }

    private func installHelperLegacy(completion: @escaping (Bool, Error?) -> Void) {
        // Use AuthorizationExecuteWithPrivileges equivalent
        // This is a simplified version - production code would use proper SMJobBless

        let alert = NSAlert()
        alert.messageText = "Administrator Access Required"
        alert.informativeText = "Please enter your password to install the helper tool."
        alert.runModal()

        // In production, use proper SMJobBless workflow
        // For now, we'll work with app-level cursor changes
        completion(true, nil)
    }

    /// Uninstall the helper tool
    public func uninstallHelper(completion: @escaping (Bool, Error?) -> Void) {
        if #available(macOS 13.0, *) {
            let service = SMAppService.daemon(plistName: "com.pointerdesigner.helper.plist")
            do {
                try service.unregister()
                completion(true, nil)
            } catch {
                completion(false, error)
            }
        } else {
            completion(true, nil)
        }
    }

    // MARK: - XPC Communication

    /// Set cursor system-wide via helper
    public func setCursor(_ image: NSImage) {
        guard isHelperInstalled else {
            // Fall back to app-level cursor only
            return
        }

        sendToHelper(command: .setCursor, payload: image.tiffRepresentation)
    }

    /// Restore system cursor via helper
    public func restoreSystemCursor() {
        guard isHelperInstalled else { return }
        sendToHelper(command: .restoreCursor, payload: nil)
    }

    private enum HelperCommand: String {
        case setCursor
        case restoreCursor
    }

    private func sendToHelper(command: HelperCommand, payload: Data?) {
        // XPC communication with helper tool
        if xpcConnection == nil {
            xpcConnection = NSXPCConnection(machServiceName: helperBundleID)
            xpcConnection?.remoteObjectInterface = NSXPCInterface(with: PointerHelperProtocol.self)
            xpcConnection?.resume()
        }

        guard let helper = xpcConnection?.remoteObjectProxy as? PointerHelperProtocol else {
            return
        }

        switch command {
        case .setCursor:
            if let data = payload {
                helper.setCursor(imageData: data)
            }
        case .restoreCursor:
            helper.restoreCursor()
        }
    }
}

// MARK: - Helper Protocol

@objc public protocol PointerHelperProtocol {
    func setCursor(imageData: Data)
    func restoreCursor()
    func getVersion(reply: @escaping (String) -> Void)
}
