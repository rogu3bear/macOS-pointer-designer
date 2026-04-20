import XCTest
@testable import PointerDesignerCore

final class CursorSettingsTests: XCTestCase {

    // MARK: - Default Settings Tests

    func testDefaultSettings() {
        let defaults = CursorSettings.defaults

        XCTAssertTrue(defaults.isEnabled)
        XCTAssertEqual(defaults.contrastMode, .autoInvert)
        XCTAssertEqual(defaults.outlineWidth, 2.0)
        XCTAssertEqual(defaults.samplingRate, 60)
        XCTAssertFalse(defaults.launchAtLogin)
        XCTAssertEqual(defaults.schemaVersion, CursorSettings.currentSchemaVersion)
    }

    // MARK: - CursorColor Tests

    func testCursorColorBrightness() {
        let white = CursorColor.white
        let black = CursorColor.black

        XCTAssertEqual(white.brightness, 1.0, accuracy: 0.01)
        XCTAssertEqual(black.brightness, 0.0, accuracy: 0.01)

        let midGray = CursorColor(red: 0.5, green: 0.5, blue: 0.5)
        XCTAssertGreaterThan(midGray.brightness, 0.4)
        XCTAssertLessThan(midGray.brightness, 0.6)
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

    // MARK: - Edge Case #17/#18: Pure Black/White

    func testPureBlackContrasting() {
        let black = CursorColor.black
        XCTAssertTrue(black.isEffectivelyBlack)
        XCTAssertEqual(black.contrasting, .white)
    }

    func testPureWhiteContrasting() {
        let white = CursorColor.white
        XCTAssertTrue(white.isEffectivelyWhite)
        XCTAssertEqual(white.contrasting, .black)
    }

    // MARK: - Edge Case #22: Zero Alpha

    func testZeroAlphaClamped() {
        let color = CursorColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.0)
        // Alpha should be clamped to minimum 0.1
        XCTAssertGreaterThanOrEqual(color.alpha, 0.1)
    }

    // MARK: - Edge Case #23: Negative Values

    func testNegativeValuesClamped() {
        let color = CursorColor(red: -0.5, green: -1.0, blue: -0.3, alpha: 1.0)
        XCTAssertEqual(color.red, 0.0)
        XCTAssertEqual(color.green, 0.0)
        XCTAssertEqual(color.blue, 0.0)
    }

    // MARK: - Edge Case #6: HDR Values

    func testHDRValuesClamped() {
        let color = CursorColor(red: 1.5, green: 2.0, blue: 1.2, alpha: 1.0)
        XCTAssertEqual(color.red, 1.0)
        XCTAssertEqual(color.green, 1.0)
        XCTAssertEqual(color.blue, 1.0)
    }

    // MARK: - Edge Case #48: Sampling Rate Validation

    func testSamplingRateMinimum() {
        let settings = CursorSettings(samplingRate: 0)
        XCTAssertGreaterThanOrEqual(settings.samplingRate, 15)
    }

    func testSamplingRateMaximum() {
        let settings = CursorSettings(samplingRate: 500)
        XCTAssertLessThanOrEqual(settings.samplingRate, 120)
    }

    // MARK: - Edge Case #49: Outline Width Validation

    func testOutlineWidthMinimum() {
        let settings = CursorSettings(outlineWidth: 0.0)
        XCTAssertGreaterThanOrEqual(settings.outlineWidth, 0.5)
    }

    // MARK: - Edge Case #45: Corrupted Data Handling

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

        XCTAssertEqual(original.isEnabled, decoded.isEnabled)
        XCTAssertEqual(original.contrastMode, decoded.contrastMode)
        XCTAssertEqual(original.outlineWidth, decoded.outlineWidth, accuracy: 0.01)
        XCTAssertEqual(original.samplingRate, decoded.samplingRate)
    }

    func testCorruptedDataFallback() throws {
        // Create corrupted JSON with missing required fields
        let corruptedJSON = """
        {"isEnabled": true}
        """.data(using: .utf8)!

        // Should not throw - uses fallback values
        let decoded = try JSONDecoder().decode(CursorSettings.self, from: corruptedJSON)
        XCTAssertTrue(decoded.isEnabled)
        XCTAssertEqual(decoded.contrastMode, .autoInvert) // Default
    }

    func testPartiallyCorruptedDataFallback() throws {
        // JSON with some valid fields and some missing
        let partialJSON = """
        {"schemaVersion": 1, "isEnabled": false, "samplingRate": "invalid"}
        """.data(using: .utf8)!

        let decoded = try JSONDecoder().decode(CursorSettings.self, from: partialJSON)
        XCTAssertFalse(decoded.isEnabled)
        XCTAssertEqual(decoded.samplingRate, 60) // Default due to invalid value
    }

    // MARK: - Contrast Mode Tests

    func testContrastModeValues() {
        XCTAssertEqual(ContrastMode.allCases.count, 3)
        XCTAssertTrue(ContrastMode.allCases.contains(.none))
        XCTAssertTrue(ContrastMode.allCases.contains(.autoInvert))
        XCTAssertTrue(ContrastMode.allCases.contains(.outline))
    }

    // MARK: - Color Utilities

    func testColorInterpolation() {
        let black = CursorColor.black
        let white = CursorColor.white

        let mid = black.interpolated(to: white, amount: 0.5)
        XCTAssertEqual(mid.red, 0.5, accuracy: 0.01)
        XCTAssertEqual(mid.green, 0.5, accuracy: 0.01)
        XCTAssertEqual(mid.blue, 0.5, accuracy: 0.01)
    }

    func testContrastRatio() {
        let black = CursorColor.black
        let white = CursorColor.white

        let ratio = black.contrastRatio(against: white)
        XCTAssertGreaterThan(ratio, 20) // Should be 21:1
    }

    func testGuaranteedContrast() {
        let midGray = CursorColor(red: 0.5, green: 0.5, blue: 0.5)
        let contrasting = midGray.withGuaranteedContrast(minimumRatio: 4.5)

        // Should return black or white
        XCTAssertTrue(contrasting == .black || contrasting == .white)
    }

    // MARK: - Settings Validation

    func testSettingsValidation() {
        var settings = CursorSettings(
            outlineWidth: 100, // Invalid - too large
            samplingRate: 0,   // Invalid - too small
            brightnessThreshold: 2.0 // Invalid - > 1
        )

        settings.validate()

        XCTAssertLessThanOrEqual(settings.outlineWidth, 5.0)
        XCTAssertGreaterThanOrEqual(settings.samplingRate, 15)
        XCTAssertLessThanOrEqual(settings.brightnessThreshold, 0.9)
    }
}
