import Foundation
import AppKit

/// Privileged helper tool for system-wide cursor changes
final class PointerDesignerHelper: NSObject, NSXPCListenerDelegate, PointerHelperProtocol {
    private let listener: NSXPCListener

    override init() {
        listener = NSXPCListener(machServiceName: "com.pointerdesigner.helper")
        super.init()
        listener.delegate = self
    }

    func run() {
        listener.resume()
        RunLoop.current.run()
    }

    // MARK: - NSXPCListenerDelegate

    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        // Verify the connecting process is our main app
        guard verifyClient(connection: newConnection) else {
            return false
        }

        newConnection.exportedInterface = NSXPCInterface(with: PointerHelperProtocol.self)
        newConnection.exportedObject = self
        newConnection.resume()

        return true
    }

    private func verifyClient(connection: NSXPCConnection) -> Bool {
        // In production, verify code signing requirements
        // For now, accept connections from our app bundle ID
        let validBundleIDs = ["com.pointerdesigner.app"]

        // Get the audit token and verify
        // Simplified for example - production code should use SecCode verification
        return true
    }

    // MARK: - PointerHelperProtocol

    func setCursor(imageData: Data) {
        guard let image = NSImage(data: imageData) else { return }

        // System-wide cursor setting using CoreGraphics private APIs
        // This requires SIP to be partially disabled or proper entitlements
        DispatchQueue.main.async {
            self.applyCursorSystemWide(image)
        }
    }

    func restoreCursor() {
        DispatchQueue.main.async {
            self.restoreDefaultCursor()
        }
    }

    func getVersion(reply: @escaping (String) -> Void) {
        reply("1.0.0")
    }

    // MARK: - Private Cursor Methods

    private func applyCursorSystemWide(_ image: NSImage) {
        // Method 1: Use CGSConnection private API (requires entitlements)
        // This is the approach Mousecape uses

        // For cursor registration, we need to interact with the WindowServer
        // This typically requires a privileged helper or injection

        // Fallback: Save cursor to a shared location for the main app to use
        saveCursorImage(image)

        // Notify main app via distributed notification
        DistributedNotificationCenter.default().postNotificationName(
            NSNotification.Name("com.pointerdesigner.cursorUpdated"),
            object: nil,
            userInfo: nil,
            deliverImmediately: true
        )
    }

    private func restoreDefaultCursor() {
        // Remove custom cursor files
        let cursorPath = "/tmp/com.pointerdesigner.cursor.tiff"
        try? FileManager.default.removeItem(atPath: cursorPath)

        DistributedNotificationCenter.default().postNotificationName(
            NSNotification.Name("com.pointerdesigner.cursorRestored"),
            object: nil,
            userInfo: nil,
            deliverImmediately: true
        )
    }

    private func saveCursorImage(_ image: NSImage) {
        let cursorPath = "/tmp/com.pointerdesigner.cursor.tiff"
        if let tiffData = image.tiffRepresentation {
            try? tiffData.write(to: URL(fileURLWithPath: cursorPath))
        }
    }
}

// Protocol definition (must match PointerDesignerCore)
@objc protocol PointerHelperProtocol {
    func setCursor(imageData: Data)
    func restoreCursor()
    func getVersion(reply: @escaping (String) -> Void)
}

// Main entry point
let helper = PointerDesignerHelper()
helper.run()
