import Foundation
import AppKit

/// Manages integration with macOS system features and other apps
/// Fixes edge cases: #38, #39, #40, #41, #43, #44
public final class SystemIntegrationManager: SystemIntegrationService {
    public static let shared = SystemIntegrationManager()

    // Edge case #40: Track other cursor apps
    private var knownCursorApps: Set<String> = [
        "com.alexzielenski.Mousecape",
        "com.cursor.Cursor",
        "com.mousecape.helper"
    ]

    // Edge case #41: Screen saver state
    private var isScreenSaverActive = false

    // Edge case #44: Full screen app tracking
    private var isFullScreenAppActive = false
    private var fullScreenAppBundleID: String?

    private init() {
        setupObservers()
        checkInitialState()
    }

    deinit {
        removeObservers()
    }

    /// Shutdown the manager and clean up observers
    /// Call this during app termination
    public func shutdown() {
        removeObservers()

        // Clear tracked state
        positionsLock.lock()
        lastCursorPositions.removeAll()
        positionsLock.unlock()

        isScreenSaverActive = false
        isFullScreenAppActive = false
        fullScreenAppBundleID = nil

        NSLog("SystemIntegrationManager: Shutdown complete")
    }

    // MARK: - Public API

    /// Check if another cursor customization app is running (edge case #40)
    public var isOtherCursorAppRunning: Bool {
        let runningApps = NSWorkspace.shared.runningApplications

        for app in runningApps {
            if let bundleID = app.bundleIdentifier,
               knownCursorApps.contains(bundleID) {
                return true
            }
        }

        return false
    }

    /// Get list of running cursor apps
    public var runningCursorApps: [String] {
        let runningApps = NSWorkspace.shared.runningApplications
        var found: [String] = []

        for app in runningApps {
            if let bundleID = app.bundleIdentifier,
               knownCursorApps.contains(bundleID) {
                found.append(app.localizedName ?? bundleID)
            }
        }

        return found
    }

    /// Check if screen saver is active (edge case #41)
    public var screenSaverActive: Bool {
        return isScreenSaverActive
    }

    /// Check if a full screen app is active (edge case #44)
    public var fullScreenActive: Bool {
        return isFullScreenAppActive
    }

    /// Get system cursor accessibility settings (edge case #38)
    public struct AccessibilityCursorSettings {
        public let cursorSize: CGFloat
        public let shakeToLocate: Bool
        public let customOutlineColor: Bool
    }

    public func getAccessibilityCursorSettings() -> AccessibilityCursorSettings {
        // Read from system preferences
        let defaults = UserDefaults.standard

        // Cursor size from accessibility
        let cursorSize = CGFloat(defaults.float(forKey: "AppleKeyboardUIMode"))

        // Shake to locate preference
        let shakeToLocate = defaults.bool(forKey: "CGDisableCursorLocationMagnification") == false

        return AccessibilityCursorSettings(
            cursorSize: cursorSize > 0 ? cursorSize : 1.0,
            shakeToLocate: shakeToLocate,
            customOutlineColor: false // Would need to read from accessibility prefs
        )
    }

    /// Check if our app should yield to system cursor features (edge case #38, #39)
    public var shouldYieldToSystemFeatures: Bool {
        // Don't interfere with shake to locate
        if isShakeToLocateActive() {
            return true
        }

        // Don't interfere if screen saver is active
        if isScreenSaverActive {
            return true
        }

        return false
    }

    /// Register a custom cursor app bundle ID for conflict detection
    public func registerCursorApp(_ bundleID: String) {
        knownCursorApps.insert(bundleID)
    }

    // MARK: - Edge case #39: Shake to Locate detection

    private let positionsLock = NSLock()
    private var lastCursorPositions: [(point: CGPoint, time: CFAbsoluteTime)] = []

    public func isShakeToLocateActive() -> Bool {
        positionsLock.lock()
        let positions = lastCursorPositions
        positionsLock.unlock()

        // Detect rapid back-and-forth mouse movement that triggers shake to locate
        guard positions.count >= 4 else { return false }

        let recentPositions = Array(positions.suffix(4))
        guard let firstPosition = recentPositions.first,
              let lastPosition = recentPositions.last else { return false }
        let timeSpan = lastPosition.time - firstPosition.time

        // Must happen within 0.5 seconds
        guard timeSpan < 0.5 else { return false }

        // Check for direction reversals
        var reversals = 0
        for i in 1..<recentPositions.count - 1 {
            let prev = recentPositions[i - 1].point
            let curr = recentPositions[i].point
            let next = recentPositions[i + 1].point

            let prevDir = curr.x - prev.x
            let nextDir = next.x - curr.x

            if prevDir * nextDir < 0 { // Direction changed
                reversals += 1
            }
        }

        return reversals >= 2
    }

    public func recordCursorPosition(_ point: CGPoint) {
        positionsLock.lock()
        defer { positionsLock.unlock() }

        let now = CFAbsoluteTimeGetCurrent()
        lastCursorPositions.append((point: point, time: now))

        // Keep only last 10 positions
        if lastCursorPositions.count > 10 {
            lastCursorPositions.removeFirst()
        }

        // Clean old positions
        lastCursorPositions = lastCursorPositions.filter { now - $0.time < 1.0 }
    }

    // MARK: - Private Setup

    private func setupObservers() {
        // Edge case #41: Screen saver notifications
        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(screenSaverDidStart),
            name: NSNotification.Name("com.apple.screensaver.didstart"),
            object: nil
        )

        DistributedNotificationCenter.default().addObserver(
            self,
            selector: #selector(screenSaverDidStop),
            name: NSNotification.Name("com.apple.screensaver.didstop"),
            object: nil
        )

        // Edge case #44: Full screen app tracking
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(activeSpaceDidChange),
            name: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil
        )

        // Edge case #40: App launch/termination
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(appDidLaunch),
            name: NSWorkspace.didLaunchApplicationNotification,
            object: nil
        )

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(appDidTerminate),
            name: NSWorkspace.didTerminateApplicationNotification,
            object: nil
        )

        // Edge case #43: User switch notifications
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(sessionDidBecomeActive),
            name: NSWorkspace.sessionDidBecomeActiveNotification,
            object: nil
        )

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(sessionDidResignActive),
            name: NSWorkspace.sessionDidResignActiveNotification,
            object: nil
        )
    }

    private func removeObservers() {
        DistributedNotificationCenter.default().removeObserver(self)
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }

    private func checkInitialState() {
        // Check if any known cursor apps are already running
        if isOtherCursorAppRunning {
            NotificationCenter.default.post(
                name: .cursorAppConflictDetected,
                object: nil,
                userInfo: ["apps": runningCursorApps]
            )
        }

        // Check initial full screen state
        updateFullScreenState()
    }

    // MARK: - Event Handlers

    @objc private func screenSaverDidStart(_ notification: Notification) {
        isScreenSaverActive = true
        NotificationCenter.default.post(name: .screenSaverStateChanged, object: nil, userInfo: ["active": true])
    }

    @objc private func screenSaverDidStop(_ notification: Notification) {
        isScreenSaverActive = false
        NotificationCenter.default.post(name: .screenSaverStateChanged, object: nil, userInfo: ["active": false])
    }

    @objc private func activeSpaceDidChange(_ notification: Notification) {
        updateFullScreenState()
    }

    @objc private func appDidLaunch(_ notification: Notification) {
        guard let app = notification.userInfo?[NSWorkspace.applicationUserInfoKey] as? NSRunningApplication,
              let bundleID = app.bundleIdentifier else { return }

        if knownCursorApps.contains(bundleID) {
            NotificationCenter.default.post(
                name: .cursorAppConflictDetected,
                object: nil,
                userInfo: ["app": app.localizedName ?? bundleID]
            )
        }
    }

    @objc private func appDidTerminate(_ notification: Notification) {
        // Could notify that conflict is resolved
    }

    @objc private func sessionDidBecomeActive(_ notification: Notification) {
        // Edge case #43: Session became active, refresh cursor
        NotificationCenter.default.post(name: .sessionStateChanged, object: nil, userInfo: ["active": true])
    }

    @objc private func sessionDidResignActive(_ notification: Notification) {
        // Edge case #43: Session resigned, stop processing
        NotificationCenter.default.post(name: .sessionStateChanged, object: nil, userInfo: ["active": false])
    }

    private func updateFullScreenState() {
        // Check if frontmost app is in full screen
        guard let frontApp = NSWorkspace.shared.frontmostApplication else {
            isFullScreenAppActive = false
            fullScreenAppBundleID = nil
            return
        }

        // Check if any window of the front app is full screen
        // This is a heuristic - proper detection would require accessibility APIs
        if let windows = CGWindowListCopyWindowInfo([.optionOnScreenOnly], kCGNullWindowID) as? [[String: Any]] {
            for window in windows {
                if let ownerPID = window[kCGWindowOwnerPID as String] as? Int32,
                   ownerPID == frontApp.processIdentifier,
                   let bounds = window[kCGWindowBounds as String] as? [String: CGFloat],
                   let screen = NSScreen.main {

                    let windowFrame = CGRect(
                        x: bounds["X"] ?? 0,
                        y: bounds["Y"] ?? 0,
                        width: bounds["Width"] ?? 0,
                        height: bounds["Height"] ?? 0
                    )

                    // Full screen if window covers entire screen
                    if windowFrame.width >= screen.frame.width &&
                       windowFrame.height >= screen.frame.height {
                        isFullScreenAppActive = true
                        fullScreenAppBundleID = frontApp.bundleIdentifier
                        NotificationCenter.default.post(name: .fullScreenStateChanged, object: nil, userInfo: ["active": true])
                        return
                    }
                }
            }
        }

        isFullScreenAppActive = false
        fullScreenAppBundleID = nil
        NotificationCenter.default.post(name: .fullScreenStateChanged, object: nil, userInfo: ["active": false])
    }
}

// MARK: - Notifications

public extension Notification.Name {
    static let cursorAppConflictDetected = Notification.Name("com.pointerdesigner.cursorAppConflict")
    static let screenSaverStateChanged = Notification.Name("com.pointerdesigner.screenSaverStateChanged")
    static let fullScreenStateChanged = Notification.Name("com.pointerdesigner.fullScreenStateChanged")
    static let sessionStateChanged = Notification.Name("com.pointerdesigner.sessionStateChanged")
}
