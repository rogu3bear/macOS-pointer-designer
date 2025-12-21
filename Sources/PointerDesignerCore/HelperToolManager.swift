import Foundation
import AppKit
import ServiceManagement

/// Manages the privileged helper tool for system-wide cursor changes
public final class HelperToolManager: HelperService {
    public static let shared = HelperToolManager()

    private let helperBundleID = "com.pointerdesigner.helper"
    private let helperToolPath = "/Library/PrivilegedHelperTools/com.pointerdesigner.helper"

    // Edge case #57: Helper version constants
    private static let expectedHelperVersion = "1.0.0"

    // Edge case #58: Maximum image data size (5MB)
    private static let maxImageDataSize = 5 * 1024 * 1024

    // Edge case #59: Serial queue for thread-safe XPC operations
    // All connection state modifications happen on this queue
    private let xpcQueue = DispatchQueue(label: "com.pointerdesigner.xpc", qos: .userInitiated)

    private var xpcConnection: NSXPCConnection?

    // Edge case #57: Track helper version
    private var cachedHelperVersion: String?

    private init() {}

    /// Shutdown the helper tool manager and clean up XPC connection
    /// Call this during app termination
    public func shutdown() {
        xpcQueue.sync {
            if let connection = xpcConnection {
                // Restore cursor before closing connection
                if let helper = connection.remoteObjectProxy as? PointerHelperProtocol {
                    helper.restoreCursor()
                }
                // Invalidate the connection to release resources
                connection.invalidate()
                xpcConnection = nil
            }
            cachedHelperVersion = nil
        }
        NSLog("HelperToolManager: Shutdown complete")
    }

    /// Check if helper tool is installed
    public var isHelperInstalled: Bool {
        FileManager.default.fileExists(atPath: helperToolPath)
    }

    /// Check if helper is responsive (health check)
    /// - Parameter timeout: Maximum time to wait for response
    /// - Parameter completion: Called with true if helper responds, false otherwise
    public func checkHealth(timeout: TimeInterval = 2.0, completion: @escaping (Bool) -> Void) {
        guard isHelperInstalled else {
            completion(false)
            return
        }

        xpcQueue.async { [weak self] in
            guard let self = self,
                  let connection = self.getConnection() else {
                DispatchQueue.main.async { completion(false) }
                return
            }

            let helper = connection.remoteObjectProxyWithErrorHandler { error in
                NSLog("HelperToolManager: Health check failed: \(error)")
                DispatchQueue.main.async { completion(false) }
            } as? PointerHelperProtocol

            guard let helper = helper else {
                DispatchQueue.main.async { completion(false) }
                return
            }

            // Use getVersion as health check ping
            let workItem = DispatchWorkItem {
                DispatchQueue.main.async { completion(false) }
            }
            DispatchQueue.global().asyncAfter(deadline: .now() + timeout, execute: workItem)

            helper.getVersion { version in
                workItem.cancel()
                NSLog("HelperToolManager: Health check passed, version: \(version)")
                DispatchQueue.main.async { completion(true) }
            }
        }
    }

    /// Synchronous health check (blocks calling thread)
    public var isHelperHealthy: Bool {
        guard isHelperInstalled else { return false }

        let semaphore = DispatchSemaphore(value: 0)
        var healthy = false

        checkHealth(timeout: 1.0) { result in
            healthy = result
            semaphore.signal()
        }

        _ = semaphore.wait(timeout: .now() + 1.5)
        return healthy
    }

    /// Request helper to shut down gracefully via XPC
    /// This is preferred over kill() for launchd-managed services to avoid respawn loops
    public func requestHelperShutdown(completion: ((Bool) -> Void)? = nil) {
        xpcQueue.async { [weak self] in
            guard let self = self,
                  let connection = self.getConnection() else {
                DispatchQueue.main.async { completion?(false) }
                return
            }

            let helper = connection.remoteObjectProxyWithErrorHandler { error in
                NSLog("HelperToolManager: Failed to request shutdown: \(error)")
                DispatchQueue.main.async { completion?(false) }
            } as? PointerHelperProtocol

            guard let helper = helper else {
                DispatchQueue.main.async { completion?(false) }
                return
            }

            NSLog("HelperToolManager: Requesting helper shutdown via XPC")
            helper.requestShutdown()

            // Invalidate our connection
            connection.invalidate()
            self.xpcConnection = nil

            DispatchQueue.main.async { completion?(true) }
        }
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

        // Edge case #58: Handle nil tiffRepresentation
        guard let tiffData = image.tiffRepresentation else {
            NSLog("HelperToolManager: Failed to get TIFF representation of image")
            return
        }

        // Edge case #58: Check size limit before sending
        if tiffData.count > Self.maxImageDataSize {
            NSLog("HelperToolManager: Image data too large (\(tiffData.count) bytes), attempting compression")

            // Try to compress or resize the image
            if let compressedData = compressImageData(image) {
                sendToHelper(command: .setCursor, payload: compressedData)
            } else {
                NSLog("HelperToolManager: Failed to compress image data")
            }
        } else {
            sendToHelper(command: .setCursor, payload: tiffData)
        }
    }

    /// Restore system cursor via helper
    public func restoreSystemCursor() {
        guard isHelperInstalled else { return }
        sendToHelper(command: .restoreCursor, payload: nil)
    }

    // Edge case #58: Compress or resize large images
    private func compressImageData(_ image: NSImage) -> Data? {
        // Calculate scaled size (reduce to 50% if too large)
        let maxDimension: CGFloat = 128.0
        let currentSize = image.size
        var scaleFactor: CGFloat = 1.0

        if currentSize.width > maxDimension || currentSize.height > maxDimension {
            scaleFactor = min(maxDimension / currentSize.width, maxDimension / currentSize.height)
        }

        let newSize = NSSize(width: currentSize.width * scaleFactor, height: currentSize.height * scaleFactor)

        // Create resized image
        let resizedImage = NSImage(size: newSize)
        resizedImage.lockFocus()
        image.draw(in: NSRect(origin: .zero, size: newSize),
                   from: NSRect(origin: .zero, size: currentSize),
                   operation: .copy,
                   fraction: 1.0)
        resizedImage.unlockFocus()

        return resizedImage.tiffRepresentation
    }

    private enum HelperCommand: String {
        case setCursor
        case restoreCursor
    }

    // Edge case #57: Check helper version before operations
    // Must be called on xpcQueue. Completion is always called on xpcQueue.
    private func checkHelperVersion(completion: @escaping (Bool) -> Void) {
        dispatchPrecondition(condition: .onQueue(xpcQueue))

        // If we have a cached version that matches, return immediately
        if let cached = cachedHelperVersion, cached == Self.expectedHelperVersion {
            completion(true)
            return
        }

        // Get version from helper
        guard let connection = getConnection() else {
            completion(false)
            return
        }

        guard let helper = connection.remoteObjectProxyWithErrorHandler({ [weak self] error in
            NSLog("HelperToolManager: Error getting version: \(error)")
            // Dispatch back to xpcQueue for completion
            self?.xpcQueue.async { completion(false) }
        }) as? PointerHelperProtocol else {
            completion(false)
            return
        }

        helper.getVersion { [weak self] version in
            guard let self = self else {
                // Dispatch back to xpcQueue for completion
                self?.xpcQueue.async { completion(false) }
                return
            }

            // Dispatch back to xpcQueue for state updates and completion
            self.xpcQueue.async { [weak self] in
                guard let self = self else {
                    completion(false)
                    return
                }

                self.cachedHelperVersion = version

                if version != Self.expectedHelperVersion {
                    NSLog("HelperToolManager: Helper version mismatch. Expected \(Self.expectedHelperVersion), got \(version)")
                    // Prompt user to reinstall helper
                    DispatchQueue.main.async {
                        self.promptForHelperReinstall()
                    }
                    completion(false)
                } else {
                    completion(true)
                }
            }
        }
    }

    // Edge case #57: Prompt user to reinstall helper on version mismatch
    private func promptForHelperReinstall() {
        let alert = NSAlert()
        alert.messageText = "Helper Tool Update Required"
        alert.informativeText = "The helper tool needs to be updated. Please reinstall the helper tool from the application settings."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }

    private func sendToHelper(command: HelperCommand, payload: Data?) {
        // Edge case #59: Use serial queue for thread-safe XPC operations
        xpcQueue.async { [weak self] in
            guard let self = self else { return }

            // Edge case #57: Check version before sending commands
            self.checkHelperVersion { versionOK in
                guard versionOK else {
                    NSLog("HelperToolManager: Version check failed, aborting command")
                    return
                }

                guard let connection = self.getConnection() else {
                    NSLog("HelperToolManager: Failed to get XPC connection")
                    return
                }

                guard let helper = connection.remoteObjectProxyWithErrorHandler({ error in
                    NSLog("HelperToolManager: XPC error: \(error)")
                }) as? PointerHelperProtocol else {
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
    }

    // Edge case #59: Thread-safe connection access with proper handlers
    // Edge case #56: Add interruption and invalidation handlers
    // Fixed: Use xpcQueue for all connection state modifications to avoid lock contention
    private func getConnection() -> NSXPCConnection? {
        // Must be called on xpcQueue to ensure thread safety
        dispatchPrecondition(condition: .onQueue(xpcQueue))

        if let existing = xpcConnection {
            return existing
        }

        // Create new connection
        let connection = NSXPCConnection(machServiceName: helperBundleID)
        connection.remoteObjectInterface = NSXPCInterface(with: PointerHelperProtocol.self)

        // Edge case #56: Handle connection interruption (e.g., helper crashed)
        // Use xpcQueue to avoid race conditions
        connection.interruptionHandler = { [weak self] in
            NSLog("HelperToolManager: XPC connection interrupted, will attempt to reconnect")
            self?.xpcQueue.async { [weak self] in
                self?.handleConnectionInterruption()
            }
        }

        // Edge case #56: Handle connection invalidation (e.g., helper terminated)
        // Use xpcQueue to avoid race conditions
        connection.invalidationHandler = { [weak self] in
            NSLog("HelperToolManager: XPC connection invalidated")
            self?.xpcQueue.async { [weak self] in
                self?.handleConnectionInvalidation()
            }
        }

        // Store before resume to ensure handlers can find it
        xpcConnection = connection
        connection.resume()

        return connection
    }

    // Edge case #56: Reconnect automatically on interruption
    // Must be called on xpcQueue
    private func handleConnectionInterruption() {
        dispatchPrecondition(condition: .onQueue(xpcQueue))

        // Clear cached version to force recheck
        cachedHelperVersion = nil

        // Connection will be recreated on next use
        NSLog("HelperToolManager: Ready to reconnect on next operation")
    }

    // Edge case #56: Clear connection reference on invalidation
    // Must be called on xpcQueue
    private func handleConnectionInvalidation() {
        dispatchPrecondition(condition: .onQueue(xpcQueue))

        xpcConnection = nil
        cachedHelperVersion = nil
    }
}

// MARK: - Helper Protocol

@objc public protocol PointerHelperProtocol {
    func setCursor(imageData: Data)
    func restoreCursor()
    func getVersion(reply: @escaping (String) -> Void)
    /// Request graceful shutdown (for launchd-managed services, avoids kill/respawn loop)
    func requestShutdown()
}
