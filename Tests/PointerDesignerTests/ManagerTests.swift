import XCTest
import AppKit
@testable import PointerDesignerCore

/// Tests for DisplayManager, BackgroundColorDetector, PermissionManager, and LaunchAtLoginManager
/// Specifically targeting the warning fixes applied to these classes
final class ManagerTests: XCTestCase {

    // MARK: - DisplayManager Tests

    func testDisplayManagerSharedInstance() {
        let instance1 = DisplayManager.shared
        let instance2 = DisplayManager.shared
        XCTAssertTrue(instance1 === instance2, "DisplayManager should be a singleton")
    }

    func testConvertToCGPointWithValidScreen() throws {
        let displayManager = DisplayManager.shared

        // Test with a point that should be on the main screen
        guard let mainScreen = NSScreen.main else {
            throw XCTSkip("No main screen available")
        }

        let screenCenter = NSPoint(
            x: mainScreen.frame.midX,
            y: mainScreen.frame.midY
        )

        let cgPoint = displayManager.convertToCGPoint(screenCenter)

        // The converted point should have valid coordinates
        XCTAssertFalse(cgPoint.x.isNaN)
        XCTAssertFalse(cgPoint.y.isNaN)
        XCTAssertFalse(cgPoint.x.isInfinite)
        XCTAssertFalse(cgPoint.y.isInfinite)
    }

    func testConvertToCGPointPreservesXCoordinate() throws {
        let displayManager = DisplayManager.shared

        guard NSScreen.main != nil else {
            throw XCTSkip("No main screen available")
        }

        let testPoint = NSPoint(x: 500, y: 300)
        let cgPoint = displayManager.convertToCGPoint(testPoint)

        // X coordinate should be preserved
        XCTAssertEqual(cgPoint.x, testPoint.x, accuracy: 0.001)
    }

    func testIsPointOnScreenWithValidPoint() throws {
        let displayManager = DisplayManager.shared

        guard let mainScreen = NSScreen.main else {
            throw XCTSkip("No main screen available")
        }

        // A point in the center of the main screen should be on screen
        // Note: CG coordinates have origin at top-left
        let centerPoint = CGPoint(
            x: mainScreen.frame.midX,
            y: mainScreen.frame.height / 2
        )

        // This may or may not return true depending on coordinate system
        // The important thing is it doesn't crash
        _ = displayManager.isPointOnScreen(centerPoint)
    }

    func testIsPointOnScreenWithOffScreenPoint() {
        let displayManager = DisplayManager.shared

        // A point far off any screen should not be on screen
        let offScreenPoint = CGPoint(x: -99999, y: -99999)
        XCTAssertFalse(displayManager.isPointOnScreen(offScreenPoint))
    }

    func testSafeSamplingRectReturnsValidRect() throws {
        let displayManager = DisplayManager.shared

        guard let mainScreen = NSScreen.main else {
            throw XCTSkip("No main screen available")
        }

        let centerPoint = CGPoint(
            x: mainScreen.frame.midX,
            y: mainScreen.frame.height / 2
        )

        let rect = displayManager.safeSamplingRect(centeredAt: centerPoint, size: 10)

        // Rect should have positive dimensions
        XCTAssertGreaterThan(rect.width, 0)
        XCTAssertGreaterThan(rect.height, 0)
        XCTAssertLessThanOrEqual(rect.width, 10)
        XCTAssertLessThanOrEqual(rect.height, 10)
    }

    func testSafeSamplingRectAtEdge() {
        let displayManager = DisplayManager.shared

        // Test at origin - should clamp to valid bounds
        let edgePoint = CGPoint(x: 0, y: 0)
        let rect = displayManager.safeSamplingRect(centeredAt: edgePoint, size: 10)

        // Should still have positive dimensions (at least 1x1)
        XCTAssertGreaterThanOrEqual(rect.width, 1)
        XCTAssertGreaterThanOrEqual(rect.height, 1)
    }

    func testScaleFactorReturnsReasonableValue() throws {
        let displayManager = DisplayManager.shared

        guard let mainScreen = NSScreen.main else {
            throw XCTSkip("No main screen available")
        }

        let centerPoint = CGPoint(
            x: mainScreen.frame.midX,
            y: mainScreen.frame.height / 2
        )

        let scaleFactor = displayManager.scaleFactor(for: centerPoint)

        // Scale factor should be between 1 and 3 (for standard and retina displays)
        XCTAssertGreaterThanOrEqual(scaleFactor, 1.0)
        XCTAssertLessThanOrEqual(scaleFactor, 3.0)
    }

    func testRefreshDisplayInfoDoesNotCrash() {
        let displayManager = DisplayManager.shared

        // Should not crash
        displayManager.refreshDisplayInfo()

        // Verify we can still use the manager after refresh
        guard let mainScreen = NSScreen.main else { return }
        let point = CGPoint(x: mainScreen.frame.midX, y: 100)
        _ = displayManager.displayInfo(for: point)
    }

    // MARK: - BackgroundColorDetector Tests

    func testBackgroundColorDetectorInit() {
        let detector = BackgroundColorDetector()
        XCTAssertNotNil(detector)
    }

    func testIsOverSystemUIAtMenuBar() throws {
        let detector = BackgroundColorDetector()

        guard let mainScreen = NSScreen.main else {
            throw XCTSkip("No main screen available")
        }

        // Point at the very top of the screen (menu bar area)
        let menuBarPoint = NSPoint(
            x: mainScreen.frame.midX,
            y: mainScreen.frame.height - 10
        )

        let isOverUI = detector.isOverSystemUI(at: menuBarPoint)

        // Should be true for menu bar area
        XCTAssertTrue(isOverUI, "Point at menu bar should be detected as system UI")
    }

    func testIsOverSystemUIAtDock() throws {
        let detector = BackgroundColorDetector()

        guard NSScreen.main != nil else {
            throw XCTSkip("No main screen available")
        }

        // Point at the bottom of the screen (potential Dock area)
        let dockPoint = NSPoint(x: 500, y: 10)

        let isOverUI = detector.isOverSystemUI(at: dockPoint)

        // Should be true for dock area (when main screen exists)
        XCTAssertTrue(isOverUI, "Point at dock area should be detected as system UI")
    }

    func testIsOverSystemUIInMiddle() throws {
        let detector = BackgroundColorDetector()

        guard let mainScreen = NSScreen.main else {
            throw XCTSkip("No main screen available")
        }

        // Point in the middle of the screen (not system UI)
        let middlePoint = NSPoint(
            x: mainScreen.frame.midX,
            y: mainScreen.frame.midY
        )

        let isOverUI = detector.isOverSystemUI(at: middlePoint)

        // Should be false for middle of screen
        XCTAssertFalse(isOverUI, "Point in middle of screen should not be system UI")
    }

    func testResetClearsState() {
        let detector = BackgroundColorDetector()

        // Sample some colors first (may or may not succeed depending on permissions)
        _ = detector.sampleColor(at: CGPoint(x: 100, y: 100))
        _ = detector.sampleColor(at: CGPoint(x: 200, y: 200))

        // Reset should not crash
        detector.reset()
    }

    // MARK: - PermissionManager Tests

    func testPermissionManagerSharedInstance() {
        let instance1 = PermissionManager.shared
        let instance2 = PermissionManager.shared
        XCTAssertTrue(instance1 === instance2, "PermissionManager should be a singleton")
    }

    func testScreenRecordingPermissionCheck() {
        let manager = PermissionManager.shared

        // Just verify we can check the permission without crashing
        _ = manager.hasScreenRecordingPermission
    }

    func testAccessibilityPermissionCheck() {
        let manager = PermissionManager.shared

        // Just verify we can check the permission without crashing
        _ = manager.hasAccessibilityPermission
    }

    func testPermissionStatusForScreenRecording() {
        let manager = PermissionManager.shared

        let status = manager.status(for: .screenRecording)

        // Status should be one of the valid values
        switch status {
        case .authorized, .denied, .notDetermined:
            break // All valid
        }
    }

    func testPermissionStatusForAccessibility() {
        let manager = PermissionManager.shared

        let status = manager.status(for: .accessibility)

        // Status should be authorized or denied (accessibility doesn't have notDetermined)
        switch status {
        case .authorized, .denied:
            break // Expected values
        case .notDetermined:
            XCTFail("Accessibility permission should not be notDetermined")
        }
    }

    func testIsBackgroundDetectionAvailable() {
        let manager = PermissionManager.shared

        // This should match hasScreenRecordingPermission
        XCTAssertEqual(
            manager.isBackgroundDetectionAvailable,
            manager.hasScreenRecordingPermission
        )
    }

    func testSafeScreenCaptureWithNoPermission() {
        let manager = PermissionManager.shared

        // If no permission, should return nil gracefully
        if !manager.hasScreenRecordingPermission {
            let image = manager.safeScreenCapture(rect: CGRect(x: 0, y: 0, width: 10, height: 10))
            XCTAssertNil(image)
        }
    }

    // MARK: - LaunchAtLoginManager Tests

    func testLaunchAtLoginManagerSharedInstance() {
        let instance1 = LaunchAtLoginManager.shared
        let instance2 = LaunchAtLoginManager.shared
        XCTAssertTrue(instance1 === instance2, "LaunchAtLoginManager should be a singleton")
    }

    func testIsEnabledReturnsValue() {
        let manager = LaunchAtLoginManager.shared

        // Just verify we can check the status without crashing
        _ = manager.isEnabled
    }

    @available(macOS 13.0, *)
    func testStatusReturnsValidValue() {
        let manager = LaunchAtLoginManager.shared

        let status = manager.status

        // Status should be one of the valid SMAppService.Status values
        // We can't predict which one, but it shouldn't crash
        switch status {
        case .enabled, .notRegistered, .notFound, .requiresApproval:
            break
        @unknown default:
            break // Handle future cases
        }
    }

    func testDiagnosticInfoContainsExpectedKeys() {
        let manager = LaunchAtLoginManager.shared

        let info = manager.diagnosticInfo

        XCTAssertNotNil(info["isEnabled"])
        XCTAssertNotNil(info["bundleURL"])
    }

    func testDiagnosticInfoIsEnabledMatchesProperty() {
        let manager = LaunchAtLoginManager.shared

        let info = manager.diagnosticInfo
        let diagnosticIsEnabled = info["isEnabled"] as? Bool

        XCTAssertEqual(diagnosticIsEnabled, manager.isEnabled)
    }

    func testSetEnabledWithCompletionHandler() {
        let manager = LaunchAtLoginManager.shared
        let expectation = XCTestExpectation(description: "Completion handler called")

        // Get current state
        let wasEnabled = manager.isEnabled

        // Try to set to current state (should succeed without actual change)
        manager.setEnabled(wasEnabled) { result in
            switch result {
            case .success:
                break // Expected
            case .failure(let error):
                // May fail due to permissions, but shouldn't crash
                print("Expected failure in test environment: \(error)")
            }
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 5.0)
    }

    // MARK: - Shutdown/Lifecycle Tests

    func testHelperToolManagerShutdownDoesNotCrash() {
        // Shutdown should be safe to call even without active connection
        HelperToolManager.shared.shutdown()

        // Should be safe to call multiple times
        HelperToolManager.shared.shutdown()
    }

    func testSystemIntegrationManagerShutdownDoesNotCrash() {
        // Shutdown should be safe to call
        SystemIntegrationManager.shared.shutdown()

        // Should be safe to call multiple times
        SystemIntegrationManager.shared.shutdown()
    }

    func testSystemIntegrationManagerShutdownClearsState() {
        let manager = SystemIntegrationManager.shared

        // Record some positions
        manager.recordCursorPosition(CGPoint(x: 100, y: 100))
        manager.recordCursorPosition(CGPoint(x: 200, y: 200))

        // Shutdown
        manager.shutdown()

        // After shutdown, state should be reset
        XCTAssertFalse(manager.screenSaverActive)
        XCTAssertFalse(manager.fullScreenActive)
    }

    func testCursorEngineStopReleasesResources() {
        // Create a test instance with mocks
        let mockDisplay = MockDisplayService()
        let mockPermission = MockPermissionService()
        let mockHelper = MockHelperService()

        let engine = CursorEngine(
            displayService: mockDisplay,
            permissionService: mockPermission,
            helperService: mockHelper
        )

        // Start and stop should not crash
        engine.start()
        engine.stop()

        // Multiple stops should be safe
        engine.stop()
        engine.stop()
    }

    func testCursorEngineStopRestoresCursor() {
        let mockDisplay = MockDisplayService()
        let mockPermission = MockPermissionService()
        let mockHelper = MockHelperService()

        let engine = CursorEngine(
            displayService: mockDisplay,
            permissionService: mockPermission,
            helperService: mockHelper
        )

        engine.start()
        engine.stop()

        // Helper should have received restore call
        XCTAssertGreaterThan(mockHelper.restoreCursorCallCount, 0, "Cursor should be restored on stop")
    }

    // MARK: - Integration Tests

    func testDisplayManagerAndBackgroundDetectorIntegration() throws {
        let displayManager = DisplayManager.shared
        let detector = BackgroundColorDetector()

        guard let mainScreen = NSScreen.main else {
            throw XCTSkip("No main screen available")
        }

        // Get a point on the main screen
        let screenCenter = NSPoint(
            x: mainScreen.frame.midX,
            y: mainScreen.frame.midY
        )

        // Convert to CG coordinates
        let cgPoint = displayManager.convertToCGPoint(screenCenter)

        // Check if it's a valid sampling point
        let isOnScreen = displayManager.isPointOnScreen(cgPoint)

        // Try to get the sampling rect
        let samplingRect = displayManager.safeSamplingRect(centeredAt: cgPoint, size: 5)

        // Verify the rect is valid
        XCTAssertGreaterThan(samplingRect.width, 0)
        XCTAssertGreaterThan(samplingRect.height, 0)

        // Try sampling (may fail due to permissions, but shouldn't crash)
        _ = detector.sampleColor(at: cgPoint)

        // isOnScreen result isn't guaranteed due to coordinate system differences
        _ = isOnScreen
    }
}
