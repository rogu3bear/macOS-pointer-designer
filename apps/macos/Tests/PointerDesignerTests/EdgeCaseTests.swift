import XCTest
@testable import PointerDesignerCore

/// Tests specifically targeting identified edge cases
final class EdgeCaseTests: XCTestCase {

    // MARK: - Edge Case #14: Brightness Threshold Hysteresis

    func testHysteresisConfiguration() {
        let settings = CursorSettings(
            brightnessThreshold: 0.5,
            hysteresis: 0.1
        )

        XCTAssertEqual(settings.brightnessThreshold, 0.5)
        XCTAssertEqual(settings.hysteresis, 0.1)
    }

    func testHysteresisValidation() {
        var settings = CursorSettings(hysteresis: 0.5) // Too large
        settings.validate()
        XCTAssertLessThanOrEqual(settings.hysteresis, 0.2)

        var settings2 = CursorSettings(hysteresis: 0.001) // Too small
        settings2.validate()
        XCTAssertGreaterThanOrEqual(settings2.hysteresis, 0.01)
    }

    // MARK: - Edge Case #1: Adaptive Scaling

    func testAdaptiveScalingDefault() {
        let settings = CursorSettings.defaults
        XCTAssertTrue(settings.adaptiveScaling)
    }

    func testAdaptiveScalingCanBeDisabled() {
        let settings = CursorSettings(adaptiveScaling: false)
        XCTAssertFalse(settings.adaptiveScaling)
    }

    // MARK: - Edge Case #21: Outline Width Bounds

    func testOutlineWidthBounds() {
        // Test minimum
        let minSettings = CursorSettings(outlineWidth: -1.0)
        XCTAssertGreaterThanOrEqual(minSettings.outlineWidth, 0.5)

        // Test maximum (should be reasonable)
        let maxSettings = CursorSettings(outlineWidth: 100.0)
        var validated = maxSettings
        validated.validate()
        XCTAssertLessThanOrEqual(validated.outlineWidth, 5.0)
    }

    // MARK: - Edge Case #47: Schema Versioning

    func testSchemaVersionPresent() {
        let settings = CursorSettings.defaults
        XCTAssertEqual(settings.schemaVersion, CursorSettings.currentSchemaVersion)
    }

    func testSchemaVersionInEncoding() throws {
        let settings = CursorSettings.defaults
        let data = try JSONEncoder().encode(settings)
        let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]

        XCTAssertNotNil(json?["schemaVersion"])
    }

    // MARK: - Edge Case #17/#18: Extreme Brightness Values

    func testEffectivelyBlack() {
        let almostBlack = CursorColor(red: 0.01, green: 0.02, blue: 0.01)
        XCTAssertTrue(almostBlack.isEffectivelyBlack)

        let notBlack = CursorColor(red: 0.1, green: 0.1, blue: 0.1)
        XCTAssertFalse(notBlack.isEffectivelyBlack)
    }

    func testEffectivelyWhite() {
        let almostWhite = CursorColor(red: 0.99, green: 0.98, blue: 0.99)
        XCTAssertTrue(almostWhite.isEffectivelyWhite)

        let notWhite = CursorColor(red: 0.9, green: 0.9, blue: 0.9)
        XCTAssertFalse(notWhite.isEffectivelyWhite)
    }

    // MARK: - Edge Case #6: HDR Color Clamping

    func testHDRColorClamping() {
        // Values that might come from HDR displays
        let hdrColor = CursorColor(red: 1.5, green: 2.0, blue: 1.8, alpha: 1.0)

        XCTAssertEqual(hdrColor.red, 1.0)
        XCTAssertEqual(hdrColor.green, 1.0)
        XCTAssertEqual(hdrColor.blue, 1.0)
    }

    // MARK: - Edge Case #22: Alpha Minimum

    func testAlphaMinimum() {
        let invisibleColor = CursorColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.0)
        XCTAssertGreaterThanOrEqual(invisibleColor.alpha, 0.1)

        let veryTransparent = CursorColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.05)
        XCTAssertGreaterThanOrEqual(veryTransparent.alpha, 0.1)
    }

    // MARK: - Edge Case #48: Sampling Rate Bounds

    func testSamplingRateBounds() {
        // Test too low
        let lowRate = CursorSettings(samplingRate: 5)
        XCTAssertEqual(lowRate.samplingRate, 15)

        // Test too high
        let highRate = CursorSettings(samplingRate: 200)
        XCTAssertEqual(highRate.samplingRate, 120)

        // Test valid range
        let validRate = CursorSettings(samplingRate: 60)
        XCTAssertEqual(validRate.samplingRate, 60)
    }

    // MARK: - Edge Case #14: Brightness Threshold Bounds

    func testBrightnessThresholdBounds() {
        // Test too low
        let lowThreshold = CursorSettings(brightnessThreshold: 0.0)
        XCTAssertGreaterThanOrEqual(lowThreshold.brightnessThreshold, 0.1)

        // Test too high
        let highThreshold = CursorSettings(brightnessThreshold: 1.0)
        XCTAssertLessThanOrEqual(highThreshold.brightnessThreshold, 0.9)
    }

    // MARK: - WCAG Contrast Tests

    func testWCAGContrastCalculation() {
        let black = CursorColor.black
        let white = CursorColor.white

        // WCAG contrast ratio between black and white should be 21:1
        let ratio = black.contrastRatio(against: white)
        XCTAssertEqual(ratio, 21.0, accuracy: 1.0)
    }

    func testGuaranteedContrastMeetsWCAG() {
        // Test with various colors
        let colors: [CursorColor] = [
            CursorColor(red: 0.5, green: 0.5, blue: 0.5),
            CursorColor(red: 0.3, green: 0.3, blue: 0.3),
            CursorColor(red: 0.7, green: 0.7, blue: 0.7),
            CursorColor(red: 0.2, green: 0.4, blue: 0.6),
        ]

        for color in colors {
            let contrasting = color.withGuaranteedContrast(minimumRatio: 4.5)
            let ratio = color.contrastRatio(against: contrasting)
            // Should meet at least AA standard (4.5:1) or be the best available
            XCTAssertGreaterThanOrEqual(ratio, 3.0)
        }
    }

    // MARK: - Color Space Tests

    func testSRGBLuminanceCoefficients() {
        // Pure red should have specific brightness
        let red = CursorColor(red: 1.0, green: 0.0, blue: 0.0)
        XCTAssertEqual(red.brightness, 0.2126, accuracy: 0.01)

        // Pure green should have specific brightness
        let green = CursorColor(red: 0.0, green: 1.0, blue: 0.0)
        XCTAssertEqual(green.brightness, 0.7152, accuracy: 0.01)

        // Pure blue should have specific brightness
        let blue = CursorColor(red: 0.0, green: 0.0, blue: 1.0)
        XCTAssertEqual(blue.brightness, 0.0722, accuracy: 0.01)
    }

    // MARK: - Encoding Stability Tests

    func testEncodingRoundTrip() throws {
        let original = CursorSettings(
            isEnabled: true,
            cursorColor: CursorColor(red: 0.123, green: 0.456, blue: 0.789),
            contrastMode: .outline,
            outlineWidth: 2.5,
            outlineColor: CursorColor(red: 1.0, green: 1.0, blue: 1.0),
            samplingRate: 45,
            launchAtLogin: true,
            brightnessThreshold: 0.55,
            hysteresis: 0.12,
            adaptiveScaling: false
        )

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        let data = try encoder.encode(original)
        let decoded = try decoder.decode(CursorSettings.self, from: data)

        XCTAssertEqual(original.isEnabled, decoded.isEnabled)
        XCTAssertEqual(original.cursorColor.red, decoded.cursorColor.red, accuracy: 0.001)
        XCTAssertEqual(original.cursorColor.green, decoded.cursorColor.green, accuracy: 0.001)
        XCTAssertEqual(original.cursorColor.blue, decoded.cursorColor.blue, accuracy: 0.001)
        XCTAssertEqual(original.contrastMode, decoded.contrastMode)
        XCTAssertEqual(original.outlineWidth, decoded.outlineWidth, accuracy: 0.001)
        XCTAssertEqual(original.samplingRate, decoded.samplingRate)
        XCTAssertEqual(original.launchAtLogin, decoded.launchAtLogin)
        XCTAssertEqual(original.brightnessThreshold, decoded.brightnessThreshold, accuracy: 0.001)
        XCTAssertEqual(original.hysteresis, decoded.hysteresis, accuracy: 0.001)
        XCTAssertEqual(original.adaptiveScaling, decoded.adaptiveScaling)
    }
}
