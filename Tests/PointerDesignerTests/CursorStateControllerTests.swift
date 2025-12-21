import XCTest
@testable import PointerDesignerCore

final class CursorStateControllerTests: XCTestCase {
    var mockSettings: MockSettingsService!
    var mockCursor: MockCursorService!
    var mockLaunchAtLogin: MockLaunchAtLoginService!
    var mockPermission: MockPermissionService!
    var controller: CursorStateController!

    override func setUp() {
        super.setUp()
        mockSettings = MockSettingsService()
        mockCursor = MockCursorService()
        mockLaunchAtLogin = MockLaunchAtLoginService()
        mockPermission = MockPermissionService()

        controller = CursorStateController(
            settingsService: mockSettings,
            cursorService: mockCursor,
            launchAtLoginService: mockLaunchAtLogin,
            permissionService: mockPermission
        )
    }

    override func tearDown() {
        controller = nil
        mockSettings = nil
        mockCursor = nil
        mockLaunchAtLogin = nil
        mockPermission = nil
        super.tearDown()
    }

    // MARK: - Enable/Disable Tests

    func testToggleEnabled() {
        // Default settings has isEnabled = true, so toggle should disable
        XCTAssertTrue(controller.isEnabled)

        controller.toggleEnabled()

        XCTAssertFalse(controller.isEnabled)
        XCTAssertEqual(mockCursor.stopCallCount, 1)
        XCTAssertEqual(mockSettings.saveCallCount, 1)
    }

    func testSetEnabledTrue() {
        controller.setEnabled(true)

        XCTAssertTrue(controller.isEnabled)
        XCTAssertEqual(mockCursor.startCallCount, 1)
        XCTAssertEqual(mockCursor.stopCallCount, 0)
    }

    func testSetEnabledFalse() {
        controller.setEnabled(true)
        controller.setEnabled(false)

        XCTAssertFalse(controller.isEnabled)
        XCTAssertEqual(mockCursor.startCallCount, 1)
        XCTAssertEqual(mockCursor.stopCallCount, 1)
    }

    // MARK: - Color Tests

    func testSetCursorColor() {
        let color = CursorColor(red: 1.0, green: 0.5, blue: 0.0)

        controller.setCursorColor(color)

        XCTAssertEqual(mockSettings.lastSavedSettings?.cursorColor, color)
        XCTAssertEqual(mockCursor.configureCallCount, 1)
    }

    func testSetOutlineColor() {
        let color = CursorColor(red: 0.0, green: 1.0, blue: 0.0)

        controller.setOutlineColor(color)

        XCTAssertEqual(mockSettings.lastSavedSettings?.outlineColor, color)
    }

    // MARK: - Contrast Mode Tests

    func testSetContrastModeNone() {
        controller.setContrastMode(.none)

        XCTAssertEqual(mockSettings.lastSavedSettings?.contrastMode, ContrastMode.none)
    }

    func testSetContrastModeAutoInvert() {
        controller.setContrastMode(.autoInvert)

        XCTAssertEqual(mockSettings.lastSavedSettings?.contrastMode, .autoInvert)
    }

    func testSetContrastModeOutline() {
        controller.setContrastMode(.outline)

        XCTAssertEqual(mockSettings.lastSavedSettings?.contrastMode, .outline)
    }

    // MARK: - Settings Tests

    func testSetOutlineWidth() {
        controller.setOutlineWidth(3.5)

        XCTAssertEqual(mockSettings.lastSavedSettings?.outlineWidth, 3.5)
    }

    func testSetBrightnessThreshold() {
        controller.setBrightnessThreshold(0.6)

        XCTAssertEqual(mockSettings.lastSavedSettings?.brightnessThreshold, 0.6)
    }

    func testSetHysteresis() {
        controller.setHysteresis(0.15)

        XCTAssertEqual(mockSettings.lastSavedSettings?.hysteresis, 0.15)
    }

    func testUpdateSettingsWithTransform() {
        controller.updateSettings { settings in
            settings.cursorColor = .black
            settings.contrastMode = .outline
        }

        XCTAssertEqual(mockSettings.lastSavedSettings?.cursorColor, .black)
        XCTAssertEqual(mockSettings.lastSavedSettings?.contrastMode, .outline)
    }

    // MARK: - Reset Tests

    func testResetToDefaults() {
        controller.setCursorColor(.black)
        controller.setContrastMode(.outline)

        controller.resetToDefaults()

        XCTAssertEqual(mockSettings.resetCallCount, 1)
        XCTAssertEqual(mockCursor.configureCallCount, 3) // setCursorColor + setContrastMode + reset
    }

    // MARK: - Launch At Login Tests

    func testSetLaunchAtLoginEnabled() {
        let result = controller.setLaunchAtLogin(true)

        XCTAssertTrue(result.isSuccess)
        XCTAssertTrue(controller.isLaunchAtLoginEnabled)
        XCTAssertEqual(mockLaunchAtLogin.setEnabledCallCount, 1)
    }

    func testSetLaunchAtLoginDisabled() {
        mockLaunchAtLogin.isEnabled = true
        let result = controller.setLaunchAtLogin(false)

        XCTAssertTrue(result.isSuccess)
        XCTAssertFalse(controller.isLaunchAtLoginEnabled)
    }

    func testSetLaunchAtLoginFailure() {
        mockLaunchAtLogin.shouldFail = true

        let result = controller.setLaunchAtLogin(true)

        XCTAssertFalse(result.isSuccess)
        XCTAssertFalse(controller.isLaunchAtLoginEnabled)
    }

    // MARK: - Permission Tests

    func testRefreshPermissionState() {
        mockPermission.hasScreenRecordingPermission = false

        controller.refreshPermissionState()

        XCTAssertFalse(controller.hasScreenRecordingPermission)
    }

    // MARK: - Reload Tests

    func testReloadSettings() {
        mockSettings.currentSettings = CursorSettings(isEnabled: true, cursorColor: .black)

        controller.reloadSettings()

        XCTAssertEqual(mockSettings.reloadCallCount, 1)
        XCTAssertEqual(controller.currentSettings.cursorColor, .black)
    }
}

// MARK: - Helper Extension

private extension Result {
    var isSuccess: Bool {
        switch self {
        case .success: return true
        case .failure: return false
        }
    }
}
