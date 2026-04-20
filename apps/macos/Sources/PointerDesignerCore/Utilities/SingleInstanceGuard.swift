import Foundation
import AppKit

// MARK: - Protocols for Testability

/// Protocol wrapping NSRunningApplication for testability
public protocol RunningApplicationProtocol: AnyObject {
    var bundleIdentifier: String? { get }
    var processIdentifier: pid_t { get }
    var localizedName: String? { get }
    func activate(options: NSApplication.ActivationOptions) -> Bool
}

extension NSRunningApplication: RunningApplicationProtocol {}

/// Protocol for workspace access
public protocol WorkspaceProvider: AnyObject {
    var runningApplications: [RunningApplicationProtocol] { get }
}

/// Adapter to make NSWorkspace conform to WorkspaceProvider
public final class SystemWorkspaceProvider: WorkspaceProvider {
    public static let shared = SystemWorkspaceProvider()

    private init() {}

    public var runningApplications: [RunningApplicationProtocol] {
        return NSWorkspace.shared.runningApplications
    }
}

// MARK: - SingleInstanceGuard

/// Ensures only one instance of the application is running
public final class SingleInstanceGuard {
    public enum Result {
        case ok
        case alreadyRunning(existingApp: RunningApplicationProtocol)
    }

    private let workspace: WorkspaceProvider
    private let bundleIdentifier: String
    private let currentPID: pid_t

    /// Default initializer using system workspace
    public convenience init() {
        self.init(
            workspace: SystemWorkspaceProvider.shared,
            bundleIdentifier: Bundle.main.bundleIdentifier ?? Identity.appBundleIDAlternate,
            currentPID: ProcessInfo.processInfo.processIdentifier
        )
    }

    /// Initializer for dependency injection (testing)
    public init(workspace: WorkspaceProvider, bundleIdentifier: String, currentPID: pid_t) {
        self.workspace = workspace
        self.bundleIdentifier = bundleIdentifier
        self.currentPID = currentPID
    }

    // MARK: - Public API

    /// Check if another instance is already running
    /// Returns .ok if this is the only instance, .alreadyRunning if another exists
    public func check() -> Result {
        let runningApps = workspace.runningApplications
        let instances = runningApps.filter { $0.bundleIdentifier == bundleIdentifier }

        // Find another instance (not current process)
        if let existingInstance = instances.first(where: { $0.processIdentifier != currentPID }) {
            return .alreadyRunning(existingApp: existingInstance)
        }

        return .ok
    }

    /// Check and activate existing instance if found
    /// Returns true if this instance should continue, false if it should terminate
    public func ensureSingleInstance(showAlert: Bool = true) -> Bool {
        switch check() {
        case .ok:
            return true

        case .alreadyRunning(let existingApp):
            // Activate existing instance
            _ = existingApp.activate(options: [.activateIgnoringOtherApps])

            if showAlert {
                DispatchQueue.main.async {
                    self.showAlreadyRunningAlert(appName: existingApp.localizedName ?? "Cursor Designer")
                }
            }

            NSLog("SingleInstanceGuard: Another instance detected (PID: \(existingApp.processIdentifier))")
            return false
        }
    }

    // MARK: - Private

    private func showAlreadyRunningAlert(appName: String) {
        let alert = NSAlert()
        alert.messageText = "\(appName) Already Running"
        alert.informativeText = "\(appName) is already running. The existing instance has been activated."
        alert.alertStyle = .informational
        alert.runModal()
    }
}
