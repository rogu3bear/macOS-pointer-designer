import Foundation

/// Protocol for XPC communication between main app and privileged helper
/// Shared between PointerDesignerCore and PointerDesignerHelper
@objc public protocol PointerHelperProtocol {
    /// Set the system cursor to the provided image data
    /// - Parameter imageData: TIFF representation of the cursor image
    func setCursor(imageData: Data)

    /// Restore the system default cursor
    func restoreCursor()

    /// Get the helper tool version for compatibility checking
    /// - Parameter reply: Callback with the version string
    func getVersion(reply: @escaping (String) -> Void)

    /// Request graceful shutdown (for launchd-managed services)
    /// Avoids kill/respawn loop when terminating the helper
    func requestShutdown()
}
