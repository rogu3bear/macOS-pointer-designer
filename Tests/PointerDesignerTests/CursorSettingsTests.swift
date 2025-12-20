import XCTest
@testable import PointerDesignerCore

final class CursorSettingsTests: XCTestCase {

    func testDefaultSettings() {
        let defaults = CursorSettings.defaults

        XCTAssertTrue(defaults.isEnabled)
        XCTAssertEqual(defaults.contrastMode, .autoInvert)
        XCTAssertEqual(defaults.outlineWidth, 2.0)
        XCTAssertEqual(defaults.samplingRate, 60)
        XCTAssertFalse(defaults.launchAtLogin)
    }

    func testCursorColorBrightness() {
        let white = CursorColor.white
        let black = CursorColor.black

        XCTAssertEqual(white.brightness, 1.0, accuracy: 0.01)
        XCTAssertEqual(black.brightness, 0.0, accuracy: 0.01)

        let midGray = CursorColor(red: 0.5, green: 0.5, blue: 0.5)
        XCTAssertEqual(midGray.brightness, 0.5, accuracy: 0.01)
    }

    func testCursorColorInversion() {
        let white = CursorColor.white
        let inverted = white.inverted

        XCTAssertEqual(inverted.red, 0.0)
        XCTAssertEqual(inverted.green, 0.0)
        XCTAssertEqual(inverted.blue, 0.0)
    }

    func testCursorColorContrasting() {
        let lightColor = CursorColor(red: 0.9, green: 0.9, blue: 0.9)
        let darkColor = CursorColor(red: 0.1, green: 0.1, blue: 0.1)

        XCTAssertEqual(lightColor.contrasting, .black)
        XCTAssertEqual(darkColor.contrasting, .white)
    }

    func testSettingsEncodingDecoding() throws {
        let original = CursorSettings(
            isEnabled: true,
            cursorColor: CursorColor(red: 0.5, green: 0.3, blue: 0.8),
            contrastMode: .outline,
            outlineWidth: 3.0,
            samplingRate: 30,
            launchAtLogin: true
        )

        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(CursorSettings.self, from: encoded)

        XCTAssertEqual(original, decoded)
    }

    func testContrastModeValues() {
        XCTAssertEqual(ContrastMode.allCases.count, 3)
        XCTAssertTrue(ContrastMode.allCases.contains(.none))
        XCTAssertTrue(ContrastMode.allCases.contains(.autoInvert))
        XCTAssertTrue(ContrastMode.allCases.contains(.outline))
    }
}
