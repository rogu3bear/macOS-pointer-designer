import XCTest
@testable import PointerDesignerCore

final class UpdateCheckerTests: XCTestCase {
    func testVersionComparisonDetectsNewerRelease() {
        XCTAssertTrue(UpdateChecker.isRelease("v1.0.1", newerThan: "1.0.0"))
        XCTAssertTrue(UpdateChecker.isRelease("v2.0.0", newerThan: "1.9.9"))
    }

    func testVersionComparisonDoesNotTreatSameOrOlderReleaseAsNewer() {
        XCTAssertFalse(UpdateChecker.isRelease("v1.0.0", newerThan: "1.0.0"))
        XCTAssertFalse(UpdateChecker.isRelease("v0.9.9", newerThan: "1.0.0"))
    }

    func testUpdateCheckRefusesNetworkWhenInternetAccessIsDisabled() {
        let checker = UpdateChecker()
        let expectation = expectation(description: "update check refused before network")

        checker.checkLatestRelease(allowsInternetAccess: false, currentVersion: "1.0.0") { result in
            XCTAssertEqual(result, .failure(.internetAccessNotAllowed))
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 1.0)
    }
}
