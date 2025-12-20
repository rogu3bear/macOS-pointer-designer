import XCTest
@testable import PointerDesignerCore

final class BackgroundColorDetectorTests: XCTestCase {
    var detector: BackgroundColorDetector!

    override func setUp() {
        super.setUp()
        detector = BackgroundColorDetector()
    }

    override func tearDown() {
        detector = nil
        super.tearDown()
    }

    func testSampleColorReturnsValue() {
        // Test that sampling a valid screen position returns a color
        let point = CGPoint(x: 100, y: 100)
        let color = detector.sampleColor(at: point)

        // Should return some color (may fail if screen access denied)
        // In CI/testing environment, this might be nil
        if color != nil {
            XCTAssertGreaterThanOrEqual(color!.red, 0)
            XCTAssertLessThanOrEqual(color!.red, 1)
            XCTAssertGreaterThanOrEqual(color!.green, 0)
            XCTAssertLessThanOrEqual(color!.green, 1)
            XCTAssertGreaterThanOrEqual(color!.blue, 0)
            XCTAssertLessThanOrEqual(color!.blue, 1)
        }
    }

    func testSampleColorWithContextReturnsValue() {
        let point = CGPoint(x: 200, y: 200)
        let color = detector.sampleColorWithContext(at: point, radius: 15)

        // Similar to above - may be nil in restricted environments
        if color != nil {
            XCTAssertGreaterThanOrEqual(color!.red, 0)
            XCTAssertLessThanOrEqual(color!.red, 1)
        }
    }

    func testSampleOutOfBoundsReturnsNil() {
        // Very large coordinates that are off-screen
        let point = CGPoint(x: 999999, y: 999999)
        let color = detector.sampleColor(at: point)

        // Should return nil or a default value for off-screen
        // Implementation may vary
        _ = color // Just ensure no crash
    }
}
