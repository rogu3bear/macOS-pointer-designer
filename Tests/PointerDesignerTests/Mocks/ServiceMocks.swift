import Foundation
import AppKit
@testable import PointerDesignerCore

// MARK: - Mock Settings Service

public final class MockSettingsService: SettingsService {
    public var currentSettings: CursorSettings = .defaults
    public var saveCallCount = 0
    public var resetCallCount = 0
    public var reloadCallCount = 0
    public var exportCallCount = 0
    public var importCallCount = 0
    public var lastSavedSettings: CursorSettings?

    public var storageStatus: [String: Any] {
        return ["mock": true]
    }

    public func save(_ settings: CursorSettings) {
        saveCallCount += 1
        lastSavedSettings = settings
        currentSettings = settings
    }

    public func reset() {
        resetCallCount += 1
        currentSettings = .defaults
    }

    public func reload() {
        reloadCallCount += 1
    }

    public func exportSettings() -> Data? {
        exportCallCount += 1
        return try? JSONEncoder().encode(currentSettings)
    }

    public func importSettings(from data: Data) -> Bool {
        importCallCount += 1
        if let settings = try? JSONDecoder().decode(CursorSettings.self, from: data) {
            currentSettings = settings
            return true
        }
        return false
    }
}

// MARK: - Mock Display Service

public final class MockDisplayService: DisplayService {
    public var mockDisplayInfo: DisplayManager.DisplayInfo?
    public var mockScaleFactor: CGFloat = 2.0
    public var mockIsHDR = false
    public var mockIsPointOnScreen = true

    public func displayInfo(for point: CGPoint) -> DisplayManager.DisplayInfo? {
        return mockDisplayInfo
    }

    public func scaleFactor(for point: CGPoint) -> CGFloat {
        return mockScaleFactor
    }

    public func convertToCGPoint(_ nsPoint: NSPoint) -> CGPoint {
        return CGPoint(x: nsPoint.x, y: nsPoint.y)
    }

    public func isPointOnScreen(_ point: CGPoint) -> Bool {
        return mockIsPointOnScreen
    }

    public func safeSamplingRect(centeredAt point: CGPoint, size: CGFloat) -> CGRect {
        let halfSize = size / 2
        return CGRect(x: point.x - halfSize, y: point.y - halfSize, width: size, height: size)
    }

    public func isHDRDisplay(at point: CGPoint) -> Bool {
        return mockIsHDR
    }

    public func refreshDisplayInfo() {
        // No-op in mock
    }
}

// MARK: - Mock Permission Service

public final class MockPermissionService: PermissionService {
    public var hasScreenRecordingPermission = true
    public var hasAccessibilityPermission = true
    public var isBackgroundDetectionAvailable: Bool { hasScreenRecordingPermission }

    public var statusCallCount = 0
    public var requestCallCount = 0
    public var openPrefsCallCount = 0
    public var promptCallCount = 0

    public func status(for permission: PermissionManager.Permission) -> PermissionManager.PermissionStatus {
        statusCallCount += 1
        switch permission {
        case .screenRecording:
            return hasScreenRecordingPermission ? .authorized : .denied
        case .accessibility:
            return hasAccessibilityPermission ? .authorized : .denied
        }
    }

    public func request(_ permission: PermissionManager.Permission, completion: @escaping (PermissionManager.PermissionStatus) -> Void) {
        requestCallCount += 1
        completion(.authorized)
    }

    public func openSystemPreferences(for permission: PermissionManager.Permission) {
        openPrefsCallCount += 1
    }

    public func promptForPermission(_ permission: PermissionManager.Permission, from window: NSWindow? = nil) {
        promptCallCount += 1
    }

    public func safeScreenCapture(rect: CGRect) -> CGImage? {
        guard hasScreenRecordingPermission else { return nil }
        // Return a simple test image
        return nil
    }
}

// MARK: - Mock Helper Service

public final class MockHelperService: HelperService {
    public var isHelperInstalled = false
    public var installCallCount = 0
    public var uninstallCallCount = 0
    public var setCursorCallCount = 0
    public var restoreCursorCallCount = 0
    public var lastCursorImage: NSImage?

    public func installHelper(completion: @escaping (Bool, Error?) -> Void) {
        installCallCount += 1
        isHelperInstalled = true
        completion(true, nil)
    }

    public func uninstallHelper(completion: @escaping (Bool, Error?) -> Void) {
        uninstallCallCount += 1
        isHelperInstalled = false
        completion(true, nil)
    }

    public func setCursor(_ image: NSImage) {
        setCursorCallCount += 1
        lastCursorImage = image
    }

    public func restoreSystemCursor() {
        restoreCursorCallCount += 1
    }
}

// MARK: - Mock Cursor Service

public final class MockCursorService: CursorService {
    public var configureCallCount = 0
    public var startCallCount = 0
    public var stopCallCount = 0
    public var refreshCallCount = 0
    public var canUseContrastFeatures = true
    public var isRunning = false
    public var lastSettings: CursorSettings?

    public func configure(with settings: CursorSettings) {
        configureCallCount += 1
        lastSettings = settings
    }

    public func start() {
        startCallCount += 1
        isRunning = true
    }

    public func stop() {
        stopCallCount += 1
        isRunning = false
    }

    public func refresh() {
        refreshCallCount += 1
    }
}

// MARK: - Mock Launch At Login Service

public final class MockLaunchAtLoginService: LaunchAtLoginService {
    public var isEnabled = false
    public var setEnabledCallCount = 0
    public var setEnabledAsyncCallCount = 0
    public var shouldFail = false

    public var diagnosticInfo: [String: Any] {
        return ["isEnabled": isEnabled, "mock": true]
    }

    public func setEnabled(_ enabled: Bool) -> Result<Void, LaunchAtLoginManager.LaunchAtLoginError> {
        setEnabledCallCount += 1
        if shouldFail {
            return .failure(.notSupported)
        }
        isEnabled = enabled
        return .success(())
    }

    public func setEnabled(_ enabled: Bool, completion: @escaping (Result<Void, LaunchAtLoginManager.LaunchAtLoginError>) -> Void) {
        setEnabledAsyncCallCount += 1
        let result = setEnabled(enabled)
        completion(result)
    }
}

// MARK: - Mock System Integration Service

public final class MockSystemIntegrationService: SystemIntegrationService {
    public var isOtherCursorAppRunning = false
    public var runningCursorApps: [String] = []
    public var screenSaverActive = false
    public var fullScreenActive = false
    public var shouldYieldToSystemFeatures = false

    public var recordPositionCallCount = 0
    public var isShakeToLocateResult = false
    public var registeredCursorApps: [String] = []

    public func registerCursorApp(_ bundleID: String) {
        registeredCursorApps.append(bundleID)
    }

    public func recordCursorPosition(_ point: CGPoint) {
        recordPositionCallCount += 1
    }

    public func isShakeToLocateActive() -> Bool {
        return isShakeToLocateResult
    }
}
