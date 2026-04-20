import XCTest
@testable import PointerDesignerCore

/// Tests for Identity constants and wiring invariants
/// These tests catch accidental misconfigurations that would break XPC/launchd integration
final class IdentityTests: XCTestCase {

    // MARK: - Invariant Tests

    func testVerifyInvariantsReturnsNoErrors() {
        let errors = Identity.verifyInvariants()
        XCTAssertTrue(errors.isEmpty, "Identity invariant errors: \(errors.joined(separator: ", "))")
    }

    func testXPCServiceNameEqualsHelperBundleID() {
        // Critical: XPC mach service name MUST match helper bundle ID
        // Mismatch causes "couldn't find service" errors
        XCTAssertEqual(
            Identity.xpcMachServiceName,
            Identity.helperBundleID,
            "XPC mach service name must equal helper bundle ID for XPC connections to work"
        )
    }

    func testLaunchdLabelEqualsHelperBundleID() {
        // Critical: launchd label MUST match helper bundle ID
        // Mismatch causes SMAppService registration failures
        XCTAssertEqual(
            Identity.launchdLabel,
            Identity.helperBundleID,
            "launchd label must equal helper bundle ID for SMAppService registration"
        )
    }

    func testHelperPlistNameContainsHelperBundleID() {
        // Plist filename should be consistent with helper bundle ID
        XCTAssertTrue(
            Identity.helperPlistName.contains(Identity.helperBundleID),
            "Helper plist name should contain helper bundle ID"
        )
    }

    func testHelperToolPathContainsHelperBundleID() {
        // Install path should be consistent with helper bundle ID
        XCTAssertTrue(
            Identity.helperToolPath.contains(Identity.helperBundleID),
            "Helper tool path should contain helper bundle ID"
        )
    }

    // MARK: - Non-Empty Tests

    func testAppBundleIDNotEmpty() {
        XCTAssertFalse(Identity.appBundleID.isEmpty, "appBundleID must not be empty")
    }

    func testHelperBundleIDNotEmpty() {
        XCTAssertFalse(Identity.helperBundleID.isEmpty, "helperBundleID must not be empty")
    }

    func testXPCMachServiceNameNotEmpty() {
        XCTAssertFalse(Identity.xpcMachServiceName.isEmpty, "xpcMachServiceName must not be empty")
    }

    func testLaunchdLabelNotEmpty() {
        XCTAssertFalse(Identity.launchdLabel.isEmpty, "launchdLabel must not be empty")
    }

    func testSettingsKeyNotEmpty() {
        XCTAssertFalse(Identity.settingsKey.isEmpty, "settingsKey must not be empty")
    }

    // MARK: - Format Validation Tests

    func testBundleIDsContainNoDots() {
        // Bundle IDs should have proper reverse-DNS format (contain dots)
        XCTAssertTrue(
            Identity.appBundleID.contains("."),
            "appBundleID should use reverse-DNS format with dots"
        )
        XCTAssertTrue(
            Identity.helperBundleID.contains("."),
            "helperBundleID should use reverse-DNS format with dots"
        )
    }

    func testBundleIDsContainNoWhitespace() {
        XCTAssertFalse(
            Identity.appBundleID.contains(where: { $0.isWhitespace }),
            "appBundleID must not contain whitespace"
        )
        XCTAssertFalse(
            Identity.helperBundleID.contains(where: { $0.isWhitespace }),
            "helperBundleID must not contain whitespace"
        )
        XCTAssertFalse(
            Identity.xpcMachServiceName.contains(where: { $0.isWhitespace }),
            "xpcMachServiceName must not contain whitespace"
        )
    }

    func testQueueLabelsAreUnique() {
        // All queue labels should be distinct to avoid debugging confusion
        let labels = [
            Identity.xpcQueueLabel,
            Identity.cursorEngineQueueLabel,
            Identity.permissionsQueueLabel,
            Identity.signalHandlerQueueLabel,
            Identity.watchdogQueueLabel,
            Identity.orphanCleanerQueueLabel
        ]
        let uniqueLabels = Set(labels)
        XCTAssertEqual(labels.count, uniqueLabels.count, "All queue labels must be unique")
    }

    func testNotificationNamesAreUnique() {
        // All notification names should be distinct
        let names = [
            Identity.settingsDidChangeNotification,
            Identity.settingsSaveFailedNotification,
            Identity.cursorUpdatedNotification,
            Identity.cursorRestoredNotification,
            Identity.processLifecycleStartedNotification,
            Identity.processLifecycleShutdownNotification,
            Identity.displayConfigurationDidChangeNotification,
            Identity.helperBecameUnresponsiveNotification,
            Identity.helperRecoveredNotification,
            Identity.launchAtLoginChangedNotification,
            Identity.cursorAppConflictDetectedNotification,
            Identity.screenSaverStateChangedNotification,
            Identity.fullScreenStateChangedNotification,
            Identity.sessionStateChangedNotification
        ]
        let uniqueNames = Set(names)
        XCTAssertEqual(names.count, uniqueNames.count, "All notification names must be unique")
    }

    // MARK: - Valid Client Bundle IDs Tests

    func testValidClientBundleIDsContainsAppBundleID() {
        XCTAssertTrue(
            Identity.validClientBundleIDs.contains(Identity.appBundleID),
            "validClientBundleIDs must include primary appBundleID"
        )
    }

    func testValidClientBundleIDsContainsAlternateBundleID() {
        XCTAssertTrue(
            Identity.validClientBundleIDs.contains(Identity.appBundleIDAlternate),
            "validClientBundleIDs must include alternate appBundleID"
        )
    }

    // MARK: - Path Tests

    func testHelperToolPathIsAbsolute() {
        XCTAssertTrue(
            Identity.helperToolPath.hasPrefix("/"),
            "helperToolPath must be an absolute path"
        )
    }

    func testHelperPIDPathIsAbsolute() {
        XCTAssertTrue(
            Identity.helperPIDPath.hasPrefix("/"),
            "helperPIDPath must be an absolute path"
        )
    }

    // MARK: - App Support Directory Tests

    func testAppSupportDirNameIsNotEmpty() {
        XCTAssertFalse(Identity.appSupportDirName.isEmpty, "appSupportDirName must not be empty")
    }

    func testLegacyAppSupportDirNameIsNotEmpty() {
        XCTAssertFalse(Identity.legacyAppSupportDirName.isEmpty, "legacyAppSupportDirName must not be empty")
    }

    func testAppSupportDirNamesAreDifferent() {
        // For migration to work, these must be different
        XCTAssertNotEqual(
            Identity.appSupportDirName,
            Identity.legacyAppSupportDirName,
            "Current and legacy app support dir names must be different for migration"
        )
    }
}
