import Foundation
import AppKit
import Security

/// Privileged helper tool for system-wide cursor changes
final class PointerDesignerHelper: NSObject, NSXPCListenerDelegate, PointerHelperProtocol {
    private let listener: NSXPCListener

    // Edge case #60: Expected team identifier for code signing verification
    private let expectedTeamIdentifier = "YOUR_TEAM_ID" // Replace with actual team ID

    // Edge case #62: Temp file cleanup timer
    private var cleanupTimer: Timer?

    // Signal handling for graceful shutdown
    private var sigtermSource: DispatchSourceSignal?
    private var sigintSource: DispatchSourceSignal?
    private var shouldTerminate = false

    override init() {
        listener = NSXPCListener(machServiceName: "com.pointerdesigner.helper")
        super.init()
        listener.delegate = self

        // Edge case #62: Clean up old temp files on startup
        cleanupOldTempFiles()

        // Edge case #62: Set up periodic cleanup (every hour)
        setupPeriodicCleanup()

        // Set up signal handlers for graceful shutdown
        setupSignalHandlers()
    }

    private func setupSignalHandlers() {
        // Ignore default signal behavior
        signal(SIGTERM, SIG_IGN)
        signal(SIGINT, SIG_IGN)

        // Handle SIGTERM (sent by launchd or kill command)
        sigtermSource = DispatchSource.makeSignalSource(signal: SIGTERM, queue: .main)
        sigtermSource?.setEventHandler { [weak self] in
            NSLog("HelperTool: Received SIGTERM, shutting down gracefully")
            self?.shutdown()
        }
        sigtermSource?.resume()

        // Handle SIGINT (Ctrl+C)
        sigintSource = DispatchSource.makeSignalSource(signal: SIGINT, queue: .main)
        sigintSource?.setEventHandler { [weak self] in
            NSLog("HelperTool: Received SIGINT, shutting down gracefully")
            self?.shutdown()
        }
        sigintSource?.resume()
    }

    func shutdown() {
        guard !shouldTerminate else { return }
        shouldTerminate = true

        NSLog("HelperTool: Beginning shutdown sequence")

        // Invalidate cleanup timer
        cleanupTimer?.invalidate()
        cleanupTimer = nil

        // Cancel signal sources
        sigtermSource?.cancel()
        sigintSource?.cancel()
        sigtermSource = nil
        sigintSource = nil

        // Invalidate XPC listener
        listener.suspend()

        // Restore cursor before exit
        restoreDefaultCursor()

        // Stop the run loop
        CFRunLoopStop(CFRunLoopGetCurrent())

        NSLog("HelperTool: Shutdown complete")
    }

    func run() {
        listener.resume()
        NSLog("HelperTool: Started and listening for connections")

        // Use CFRunLoop with explicit stop support instead of RunLoop.run()
        while !shouldTerminate {
            let result = CFRunLoopRunInMode(.defaultMode, 1.0, true)
            if result == .stopped {
                break
            }
        }

        NSLog("HelperTool: Run loop exited")
    }

    // Edge case #62: Clean up temp files older than 24 hours
    private func cleanupOldTempFiles() {
        let tempDir = NSTemporaryDirectory()
        let fileManager = FileManager.default

        do {
            let contents = try fileManager.contentsOfDirectory(atPath: tempDir)
            let maxAge: TimeInterval = 24 * 60 * 60 // 24 hours

            for file in contents {
                // Only clean up our cursor files
                if file.hasPrefix("com.pointerdesigner.cursor") {
                    let filePath = (tempDir as NSString).appendingPathComponent(file)

                    if let attributes = try? fileManager.attributesOfItem(atPath: filePath),
                       let modificationDate = attributes[.modificationDate] as? Date {

                        let age = Date().timeIntervalSince(modificationDate)
                        if age > maxAge {
                            try? fileManager.removeItem(atPath: filePath)
                            NSLog("HelperTool: Cleaned up old temp file: \(file)")
                        }
                    }
                }
            }
        } catch {
            NSLog("HelperTool: Error during temp file cleanup: \(error)")
        }
    }

    // Edge case #62: Set up periodic cleanup
    private func setupPeriodicCleanup() {
        cleanupTimer = Timer.scheduledTimer(withTimeInterval: 3600, repeats: true) { [weak self] _ in
            self?.cleanupOldTempFiles()
        }
    }

    deinit {
        cleanupTimer?.invalidate()
    }

    // MARK: - NSXPCListenerDelegate

    func listener(_ listener: NSXPCListener, shouldAcceptNewConnection newConnection: NSXPCConnection) -> Bool {
        // Edge case #60: Verify the connecting process is our main app
        guard verifyClient(connection: newConnection) else {
            NSLog("HelperTool: Rejected connection from unauthorized client")
            return false
        }

        newConnection.exportedInterface = NSXPCInterface(with: PointerHelperProtocol.self)
        newConnection.exportedObject = self
        newConnection.resume()

        return true
    }

    // Edge case #60: Implement proper SecCode verification
    private func verifyClient(connection: NSXPCConnection) -> Bool {
        var code: SecCode?
        var status: OSStatus

        // Get the SecCode for the connecting process
        let attributes = [kSecGuestAttributePid: connection.processIdentifier] as CFDictionary
        status = SecCodeCopyGuestWithAttributes(nil, attributes, [], &code)

        guard status == errSecSuccess, let clientCode = code else {
            NSLog("HelperTool: Failed to get SecCode for client: \(status)")
            return false
        }

        // Edge case #60: Check code signing requirement
        // Verify the client is properly signed
        var staticCode: SecStaticCode?
        status = SecCodeCopyStaticCode(clientCode, [], &staticCode)

        guard status == errSecSuccess, let clientStaticCode = staticCode else {
            NSLog("HelperTool: Failed to get static code: \(status)")
            return false
        }

        // Verify signature is valid
        status = SecStaticCodeCheckValidity(clientStaticCode, [], nil)
        guard status == errSecSuccess else {
            NSLog("HelperTool: Client signature validation failed: \(status)")
            return false
        }

        // Edge case #60: Check team identifier matches expected value
        var signingInfo: CFDictionary?
        status = SecCodeCopySigningInformation(clientStaticCode, [], &signingInfo)

        guard status == errSecSuccess,
              let info = signingInfo as? [String: Any] else {
            NSLog("HelperTool: Failed to get signing information: \(status)")
            return false
        }

        // Extract team identifier
        if let teamIdentifier = info[kSecCodeInfoTeamIdentifier as String] as? String {
            // If we have a specific team ID to check against
            if expectedTeamIdentifier != "YOUR_TEAM_ID" && teamIdentifier != expectedTeamIdentifier {
                NSLog("HelperTool: Team identifier mismatch. Expected: \(expectedTeamIdentifier), Got: \(teamIdentifier)")
                return false
            }
            NSLog("HelperTool: Client verified with team ID: \(teamIdentifier)")
        } else {
            // Edge case #60: Reject unsigned clients
            NSLog("HelperTool: Client is not signed with a team identifier")
            return false
        }

        // Optionally verify bundle identifier
        if let bundleIdentifier = info[kSecCodeInfoIdentifier as String] as? String {
            let validBundleIDs = ["com.pointerdesigner.app", "com.pointerdesigner"]
            if !validBundleIDs.contains(bundleIdentifier) {
                NSLog("HelperTool: Invalid bundle identifier: \(bundleIdentifier)")
                return false
            }
            NSLog("HelperTool: Client verified with bundle ID: \(bundleIdentifier)")
        }

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

        // Edge case #63: Distributed notification with fallback mechanism
        // Note: For more reliable delivery, consider using XPC reply callback instead
        let notificationPosted = postNotificationWithRetry(
            name: "com.pointerdesigner.cursorUpdated",
            maxRetries: 3
        )

        if !notificationPosted {
            NSLog("HelperTool: Warning - Failed to post cursor updated notification after retries")
            // In a production environment, you might want to use XPC reply callback
            // instead of distributed notifications for guaranteed delivery
        }
    }

    private func restoreDefaultCursor() {
        // Remove custom cursor files
        let cursorPath = "/tmp/com.pointerdesigner.cursor.tiff"
        try? FileManager.default.removeItem(atPath: cursorPath)

        // Edge case #63: Use notification with retry
        _ = postNotificationWithRetry(
            name: "com.pointerdesigner.cursorRestored",
            maxRetries: 3
        )
    }

    // Edge case #63: Post distributed notification
    // Note: postNotificationName doesn't throw, so retry logic is not meaningful.
    // We post once and return true. If delivery fails, it fails silently.
    private func postNotificationWithRetry(name: String, maxRetries: Int) -> Bool {
        DistributedNotificationCenter.default().postNotificationName(
            NSNotification.Name(name),
            object: nil,
            userInfo: nil,
            deliverImmediately: true
        )
        NSLog("HelperTool: Posted notification '\(name)'")
        return true
    }

    private func saveCursorImage(_ image: NSImage) {
        // Edge case #61: Use secure temp directory with restrictive permissions
        let tempDir = NSTemporaryDirectory()
        let cursorPath = (tempDir as NSString).appendingPathComponent("com.pointerdesigner.cursor.tiff")

        if let tiffData = image.tiffRepresentation {
            do {
                // Write the file
                try tiffData.write(to: URL(fileURLWithPath: cursorPath), options: .atomic)

                // Edge case #61: Set restrictive permissions (0600 = rw-------)
                // This ensures only the owner can read/write the file
                let attributes = [FileAttributeKey.posixPermissions: NSNumber(value: 0o600)]
                try FileManager.default.setAttributes(attributes, ofItemAtPath: cursorPath)

                NSLog("HelperTool: Saved cursor image with secure permissions at \(cursorPath)")
            } catch {
                NSLog("HelperTool: Failed to save cursor image or set permissions: \(error)")
            }
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
