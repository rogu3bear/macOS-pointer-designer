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

    // MARK: - Least Permission Tests

    func testMainAppEntitlementsStayMinimalForPointerCustomization() throws {
        let entitlements = try loadPlist(
            relativeToThisFile: "../../Sources/PointerDesigner/Resources/PointerDesigner.entitlements"
        )

        XCTAssertEqual(entitlements["com.apple.security.app-sandbox"] as? Bool, false)
        XCTAssertNil(entitlements["com.apple.security.automation.apple-events"])
        XCTAssertNil(entitlements["com.apple.security.cs.allow-unsigned-executable-memory"])
        XCTAssertNil(entitlements["com.apple.security.cs.disable-library-validation"])
    }

    func testAccessibilityUsageDescriptionDoesNotOverclaimSystemWidePointerSupport() throws {
        let info = try loadPlist(
            relativeToThisFile: "../../Sources/PointerDesigner/Resources/Info.plist"
        )

        let description = try XCTUnwrap(info["NSAccessibilityUsageDescription"] as? String)
        XCTAssertFalse(description.localizedCaseInsensitiveContains("system-wide cursor customization"))
    }

    func testMainAppInfoPlistDoesNotDeclareUnsupportedPrivilegedHelper() throws {
        let info = try loadPlist(
            relativeToThisFile: "../../Sources/PointerDesigner/Resources/Info.plist"
        )

        XCTAssertNil(info["SMPrivilegedExecutables"])
    }

    func testUserFacingDocsDoNotAdvertiseUnsupportedSystemWideCursorChanges() throws {
        let checkedFiles = [
            "../../../../NORTH_STAR.md",
            "../../../../ANCHOR.md",
            "../../../../AGENTS.md",
            "../../README.md",
            "../../Sources/PointerDesigner/PreferencesWindowController.swift"
        ]
        let forbiddenClaims = [
            "optional system-wide helper support",
            "system-wide upgrade path",
            "System-wide Helper",
            "system-wide cursor changes",
            "Cursor not changing system-wide",
            "Automatically restores system cursor",
            "cursor is stuck"
        ]

        for file in checkedFiles {
            let text = try loadText(relativeToThisFile: file)

            for claim in forbiddenClaims {
                XCTAssertFalse(
                    text.localizedCaseInsensitiveContains(claim),
                    "\(file) must not advertise unsupported pointer capability: \(claim)"
                )
            }
        }
    }

    func testAppReadmeDoesNotAdvertiseUnverifiedDownloadChannels() throws {
        let readme = try loadText(relativeToThisFile: "../../README.md")
        let forbiddenClaims = [
            "brew tap rogu3bear/cursor-designer-osx",
            "brew install --cask cursor-designer-osx",
            "cursor-designer-osx/releases/latest",
            "Homebrew (Recommended)"
        ]

        for claim in forbiddenClaims {
            XCTAssertFalse(
                readme.localizedCaseInsensitiveContains(claim),
                "README must not advertise unverified download channel: \(claim)"
            )
        }
    }

    func testStaleHomebrewCaskIsNotShippedWithoutVerifiedRelease() {
        let testFile = URL(fileURLWithPath: #filePath)
        let caskURL = testFile
            .deletingLastPathComponent()
            .appendingPathComponent("../../Casks/cursor-designer-osx.rb")
            .standardizedFileURL

        XCTAssertFalse(
            FileManager.default.fileExists(atPath: caskURL.path),
            "Do not ship a Homebrew cask until release URL, checksum, notarization, and install behavior are verified"
        )
    }

    func testNorthStarDefinesProductionReadinessBar() throws {
        let northStar = try loadText(relativeToThisFile: "../../../../NORTH_STAR.md")
        let requiredSections = [
            "## Pointer Capability Contract",
            "## Production Readiness Bar",
            "## Mass-Production Blockers",
            "## Website Standard",
            "## Verification Gates"
        ]

        for section in requiredSections {
            XCTAssertTrue(
                northStar.contains(section),
                "NORTH_STAR.md must define \(section)"
            )
        }

        let requiredGates = [
            "apps/macos/REQUIREMENTS.md",
            "apps/macos/MANUAL_RELEASE_CHECKS.md",
            "./scripts/check-local-first.sh",
            "./scripts/check-app-ui-contract.sh",
            "make launch-smoke",
            "make dmg-install-check",
            "make dmg-artifact-match-check",
            "mounted DMG app must match the release app",
            "make signing-identity-check",
            "make signed-dmg",
            "make release-candidate",
            "make release-artifact-readiness",
            "make release-readiness",
            "make release-metadata-check",
            "make manual-release-evidence-check",
            "make north-star-audit"
        ]

        for gate in requiredGates {
            XCTAssertTrue(
                northStar.contains(gate),
                "NORTH_STAR.md must name current app readiness gate: \(gate)"
            )
        }
    }

    func testMacOSRequirementsMapDrivesAppReadinessProof() throws {
        let requirements = try loadText(relativeToThisFile: "../../REQUIREMENTS.md")
        let readme = try loadText(relativeToThisFile: "../../README.md")
        let requiredContent = [
            "APP-1",
            "APP-2",
            "APP-3",
            "APP-4",
            "APP-5",
            "APP-6",
            "APP-7",
            "APP-8",
            "make launch-smoke",
            "make dmg-install-check",
            "make dmg-artifact-match-check",
            "make signing-identity-check",
            "make signed-dmg",
            "make release-candidate",
            "make release-artifact-readiness",
            "make release-readiness",
            "make release-metadata-check",
            "mounted DMG app matches the release app",
            "stable release tag matches app version",
            "./scripts/check-local-first.sh",
            "./scripts/check-app-ui-contract.sh",
            "Dynamic contrast is active",
            "System-wide pointer replacement is not implemented",
            "notarytool profile credentials are missing"
        ]

        for content in requiredContent {
            XCTAssertTrue(
                requirements.localizedCaseInsensitiveContains(content),
                "REQUIREMENTS.md must include app readiness content: \(content)"
            )
        }

        XCTAssertTrue(readme.contains("[`REQUIREMENTS.md`](REQUIREMENTS.md)"))
    }

    func testCIExercisesMacOSPackageAndDMGShape() throws {
        let workflow = try loadText(relativeToThisFile: "../../../../.github/workflows/ci.yml")

        XCTAssertTrue(workflow.contains("swift test --package-path apps/macos"))
        XCTAssertTrue(workflow.contains("make -C apps/macos preflight"))
        XCTAssertTrue(workflow.contains("make -C apps/macos dmg && make -C apps/macos dmg-artifact-match-check"))
    }

    func testNorthStarAuditGateBuildsPromptToArtifactChecklist() throws {
        let makefile = try loadText(relativeToThisFile: "../../Makefile")
        let script = try loadText(relativeToThisFile: "../../Scripts/north-star-audit.sh")

        XCTAssertTrue(makefile.contains("north-star-audit:"))
        XCTAssertTrue(makefile.contains("north-star-audit.sh"))
        XCTAssertTrue(makefile.contains("manual-release-evidence-check:"))
        XCTAssertTrue(makefile.contains("manual-release-evidence-check.sh"))
        XCTAssertTrue(script.contains("Prompt-to-artifact checklist"))
        XCTAssertTrue(script.contains("APP-1"))
        XCTAssertTrue(script.contains("APP-8"))
        XCTAssertTrue(script.contains("release-readiness"))
        XCTAssertTrue(script.contains("release-metadata-check"))
        XCTAssertTrue(script.contains("manual-release-evidence-check.sh"))
        XCTAssertTrue(script.contains("Manual release evidence"))
        XCTAssertTrue(script.contains("not mass-production ready"))
        XCTAssertTrue(script.contains("No canonical Cursor Designer website exists."))
    }

    func testLocalFirstGuardChecksAppSourceForNetworkAndTelemetry() throws {
        let script = try loadText(relativeToThisFile: "../../../../scripts/check-local-first.sh")
        let workflow = try loadText(relativeToThisFile: "../../../../.github/workflows/ci.yml")
        let rootReadme = try loadText(relativeToThisFile: "../../../../README.md")
        let requirements = try loadText(relativeToThisFile: "../../REQUIREMENTS.md")

        XCTAssertTrue(script.contains("command -v rg"))
        XCTAssertTrue(script.contains("apps/macos/Sources"))
        XCTAssertTrue(script.contains("URLSession"))
        XCTAssertTrue(script.contains("NSURLConnection"))
        XCTAssertTrue(script.contains("NWConnection"))
        XCTAssertTrue(script.contains("SentrySDK"))
        XCTAssertTrue(script.contains("FirebaseApp"))
        XCTAssertTrue(script.contains("Cursor Designer local-first app check passed."))
        XCTAssertTrue(workflow.contains("sudo apt-get update && sudo apt-get install -y ripgrep"))
        XCTAssertTrue(workflow.contains("./scripts/check-local-first.sh"))
        XCTAssertTrue(rootReadme.contains("./scripts/check-local-first.sh"))
        XCTAssertTrue(requirements.contains("./scripts/check-local-first.sh"))
    }

    func testAppUIContractGuardChecksPreferencesAndMenuTruth() throws {
        let script = try loadText(relativeToThisFile: "../../../../scripts/check-app-ui-contract.sh")
        let workflow = try loadText(relativeToThisFile: "../../../../.github/workflows/ci.yml")
        let rootReadme = try loadText(relativeToThisFile: "../../../../README.md")
        let requirements = try loadText(relativeToThisFile: "../../REQUIREMENTS.md")

        XCTAssertTrue(script.contains("command -v rg"))
        XCTAssertTrue(script.contains("PreferencesWindowController.swift"))
        XCTAssertTrue(script.contains("NSScrollView"))
        XCTAssertTrue(script.contains("hasVerticalScroller"))
        XCTAssertTrue(script.contains("MenuBarController.swift"))
        XCTAssertTrue(script.contains("Cursor Designer Preferences"))
        XCTAssertTrue(script.contains("Background Sampling Rate"))
        XCTAssertTrue(script.contains("Dynamic contrast is paused until Screen Recording is granted."))
        XCTAssertTrue(script.contains("System-wide pointer replacement is not enabled in this build."))
        XCTAssertTrue(script.contains("Cursor Designer app UI contract check passed."))
        XCTAssertTrue(workflow.contains("./scripts/check-app-ui-contract.sh"))
        XCTAssertTrue(rootReadme.contains("./scripts/check-app-ui-contract.sh"))
        XCTAssertTrue(requirements.contains("./scripts/check-app-ui-contract.sh"))
    }

    func testTrustCheckDoesNotClaimCursorApplicationRequiresHelper() throws {
        let trustCheck = try loadText(relativeToThisFile: "../../Scripts/trust-check.sh")

        XCTAssertFalse(trustCheck.localizedCaseInsensitiveContains("Can Apply Cursor:     Run app to verify (requires helper)"))
        XCTAssertFalse(trustCheck.localizedCaseInsensitiveContains("requires helper"))
        XCTAssertFalse(trustCheck.localizedCaseInsensitiveContains("Embedded Helper:"))
        XCTAssertFalse(trustCheck.localizedCaseInsensitiveContains("XPC Mach Service:"))
    }

    func testTrustCheckUsesStrictShellModeAndValidatesOptions() throws {
        let trustCheck = try loadText(relativeToThisFile: "../../Scripts/trust-check.sh")

        XCTAssertTrue(trustCheck.contains("set -euo pipefail"))
        XCTAssertTrue(trustCheck.contains("ERROR: --app requires a path"))
        XCTAssertTrue(trustCheck.contains("exit 2"))
        XCTAssertTrue(trustCheck.contains("Unknown option: $1"))
    }

    func testReleaseScriptsValidateMissingOptionValues() throws {
        let scriptsByRequiredMessage = [
            "../../Scripts/dmg-install-check.sh": "ERROR: --dmg requires a path",
            "../../Scripts/launch-smoke.sh": "ERROR: --app requires a path",
            "../../Scripts/notary-profile-check.sh": "ERROR: --notary-profile requires a name",
            "../../Scripts/release-metadata-check.sh": "ERROR: --repo requires OWNER/REPO",
            "../../Scripts/release-readiness.sh": "ERROR: --notary-profile requires a name",
            "../../Scripts/manual-release-evidence-check.sh": "ERROR: --evidence requires a path",
            "../../Scripts/north-star-audit.sh": "ERROR: --manual-evidence requires a path"
        ]

        for (scriptPath, requiredMessage) in scriptsByRequiredMessage {
            let script = try loadText(relativeToThisFile: scriptPath)

            XCTAssertTrue(script.contains(requiredMessage), "\(scriptPath) must validate missing option values")
            XCTAssertTrue(script.contains("exit 2"), "\(scriptPath) must treat CLI usage errors as exit 2")
        }
    }

    func testHelperScaffoldDoesNotAcceptUnverifiedClients() throws {
        let helper = try loadText(relativeToThisFile: "../../Sources/PointerDesignerHelper/main.swift")

        XCTAssertTrue(helper.contains("Fail closed unless the caller resolves to one of the app bundle IDs."))
        XCTAssertTrue(helper.contains("Identity.validClientBundleIDs"))
        XCTAssertTrue(helper.contains("Rejected connection from PID"))
        XCTAssertFalse(helper.localizedCaseInsensitiveContains("personal use mode"))
        XCTAssertFalse(helper.contains("return true  // Accept"))
        XCTAssertFalse(helper.contains("Code signing verification not implemented"))
    }

    func testNotarizeTargetDoesNotRebuildAfterSigning() throws {
        let makefile = try loadText(relativeToThisFile: "../../Makefile")
        let notaryProfileCheck = try loadText(relativeToThisFile: "../../Scripts/notary-profile-check.sh")
        let signingIdentityCheck = try loadText(relativeToThisFile: "../../Scripts/signing-identity-check.sh")

        XCTAssertTrue(makefile.contains("dmg: release create-dmg"))
        XCTAssertTrue(makefile.contains("signed-dmg: sign create-dmg sign-dmg"))
        XCTAssertTrue(makefile.contains("sign-dmg:"))
        XCTAssertTrue(makefile.contains("signing-identity-check:"))
        XCTAssertTrue(makefile.contains(#"signing-identity-check.sh --sign-identity "$(SIGN_IDENTITY)""#))
        XCTAssertTrue(makefile.contains("notary-profile-check:"))
        XCTAssertTrue(makefile.contains(#"notary-profile-check.sh --notary-profile "$(NOTARY_PROFILE)""#))
        XCTAssertTrue(signingIdentityCheck.contains("security find-identity -v -p codesigning"))
        XCTAssertTrue(signingIdentityCheck.contains("ERROR: signing identity"))
        XCTAssertTrue(signingIdentityCheck.contains("Do not commit certificates"))
        XCTAssertTrue(notaryProfileCheck.contains("notarytool history --keychain-profile"))
        XCTAssertTrue(notaryProfileCheck.contains("notarytool store-credentials"))
        XCTAssertTrue(notaryProfileCheck.contains("Do not commit Apple IDs"))
        XCTAssertTrue(makefile.contains("sign: signing-identity-check release"))
        XCTAssertTrue(makefile.contains("sign-dmg: signing-identity-check"))
        XCTAssertTrue(makefile.contains("notarize: notary-profile-check signing-identity-check signed-dmg"))
        XCTAssertTrue(makefile.contains("release-artifact-readiness:"))
        XCTAssertTrue(makefile.contains("--skip-release-metadata"))
        XCTAssertTrue(makefile.contains("release-candidate: notarize release-artifact-readiness"))
        XCTAssertFalse(makefile.contains("notarize: sign dmg"))
        XCTAssertTrue(makefile.contains("SIGN_IDENTITY ?="))
        XCTAssertTrue(makefile.contains("NOTARY_PROFILE ?="))
        XCTAssertTrue(makefile.contains("--options runtime"))
        XCTAssertTrue(makefile.contains("--timestamp"))
    }

    func testReleaseReadinessGateChecksSigningAndNotarization() throws {
        let makefile = try loadText(relativeToThisFile: "../../Makefile")
        let script = try loadText(relativeToThisFile: "../../Scripts/release-readiness.sh")

        XCTAssertTrue(makefile.contains("release-readiness:"))
        XCTAssertTrue(makefile.contains(#"--repo "$(GITHUB_REPO)""#))
        XCTAssertTrue(script.contains(#"--dmg "$DMG_PATH""#))
        XCTAssertTrue(script.contains("--skip-release-metadata"))
        XCTAssertTrue(script.contains("Release artifact readiness passed."))
        XCTAssertTrue(script.contains("Run make release-readiness after publishing stable release metadata."))
        XCTAssertTrue(script.contains("dmg-install-check.sh"))
        XCTAssertTrue(script.contains("release-metadata-check.sh"))
        XCTAssertTrue(script.contains("Stable release metadata matches app version and DMG digest"))
        XCTAssertTrue(script.contains("--require-signature"))
        XCTAssertTrue(script.contains("--repo"))
        XCTAssertTrue(script.contains("codesign --verify --deep --strict"))
        XCTAssertTrue(script.contains("check_hardened_runtime"))
        XCTAssertTrue(script.contains("Runtime Version"))
        XCTAssertTrue(script.contains("Hardened runtime is enabled"))
        XCTAssertTrue(script.contains("spctl --assess --type execute"))
        XCTAssertTrue(script.contains("spctl --assess --type open"))
        XCTAssertTrue(script.contains("Gatekeeper assessment accepts DMG"))
        XCTAssertTrue(script.contains("DMG install surface, mounted app match, and mounted app signature verify"))
        XCTAssertTrue(script.contains("DMG signature verifies"))
        XCTAssertTrue(script.contains(#"codesign --verify --verbose=2 "$DMG_PATH""#))
        XCTAssertTrue(script.contains("stapler validate"))
        XCTAssertTrue(script.contains("notarytool history"))
        XCTAssertTrue(script.contains("Distribution blockers:"))
        XCTAssertTrue(script.contains("Next required proof:"))
        XCTAssertTrue(script.contains("Build and sign the app with a Developer ID Application identity"))
        XCTAssertTrue(script.contains("Store or select a valid notarytool profile"))
        XCTAssertTrue(script.contains("Notarize the signed DMG"))
        XCTAssertTrue(script.contains("tag matches this app version and its SHA-256 digest matches this local DMG"))
        XCTAssertTrue(script.contains("MANUAL_RELEASE_CHECKS.md"))
        XCTAssertTrue(script.contains("FAIL:"))
        XCTAssertTrue(script.contains("failures=("))
    }

    func testDMGInstallGateChecksMountedArtifactShape() throws {
        let makefile = try loadText(relativeToThisFile: "../../Makefile")
        let script = try loadText(relativeToThisFile: "../../Scripts/dmg-install-check.sh")

        XCTAssertTrue(makefile.contains("dmg-install-check:"))
        XCTAssertTrue(makefile.contains(#"dmg-install-check.sh --dmg "$(DMG_NAME)""#))
        XCTAssertFalse(makefile.contains(#"dmg-install-check.sh --dmg "$(DMG_NAME)" --require-signature"#))
        XCTAssertTrue(script.contains("--app"))
        XCTAssertTrue(script.contains("Mounted app matches expected app bundle."))
        XCTAssertTrue(script.contains("--require-signature"))
        XCTAssertTrue(script.contains("Use --require-signature for signed release-candidate artifacts."))
        XCTAssertTrue(script.contains("hdiutil verify"))
        XCTAssertTrue(script.contains("hdiutil attach"))
        XCTAssertTrue(script.contains("CursorDesigner.app"))
        XCTAssertTrue(script.contains("Applications"))
        XCTAssertTrue(script.contains("CFBundleIdentifier"))
        XCTAssertTrue(script.contains("CFBundleShortVersionString"))
        XCTAssertTrue(script.contains("CFBundleVersion"))
        XCTAssertTrue(script.contains("shasum -a 256"))
        XCTAssertTrue(script.contains("codesign --verify --deep --strict"))
    }

    func testDMGCreationCleansUpMountedTempArtifacts() throws {
        let script = try loadText(relativeToThisFile: "../../Scripts/create-dmg.sh")

        XCTAssertTrue(script.contains("set -euo pipefail"))
        XCTAssertTrue(script.contains("cleanup()"))
        XCTAssertTrue(script.contains("trap cleanup EXIT"))
        XCTAssertTrue(script.contains(#"hdiutil detach "$DEVICE" -quiet || true"#))
        XCTAssertTrue(script.contains(#"rm -f "$DMG_TEMP""#))
        XCTAssertTrue(script.contains("trap - EXIT"))
    }

    func testAppReadmeDoesNotReferenceMissingContributionGuide() throws {
        let readme = try loadText(relativeToThisFile: "../../README.md")

        XCTAssertFalse(readme.localizedCaseInsensitiveContains("contributing guidelines"))
        XCTAssertFalse(readme.localizedCaseInsensitiveContains("Contributions welcome"))
    }

    func testLaunchSmokeGateStartsBuiltApp() throws {
        let makefile = try loadText(relativeToThisFile: "../../Makefile")
        let script = try loadText(relativeToThisFile: "../../Scripts/launch-smoke.sh")

        XCTAssertTrue(makefile.contains("launch-smoke: release"))
        XCTAssertTrue(script.contains("open -n"))
        XCTAssertTrue(script.contains("pgrep -x"))
        XCTAssertTrue(script.contains("PointerDesigner"))
        XCTAssertTrue(script.contains("kill -TERM"))
    }

    func testReleaseMetadataGateChecksStableDownloadTruth() throws {
        let makefile = try loadText(relativeToThisFile: "../../Makefile")
        let script = try loadText(relativeToThisFile: "../../Scripts/release-metadata-check.sh")

        XCTAssertTrue(makefile.contains("release-metadata-check:"))
        XCTAssertTrue(makefile.contains(#"--app "$(APP_BUNDLE)""#))
        XCTAssertTrue(makefile.contains(#"--dmg "$(DMG_NAME)""#))
        XCTAssertTrue(script.contains("gh release list"))
        XCTAssertTrue(script.contains("isPrerelease"))
        XCTAssertTrue(script.contains("CursorDesigner.dmg"))
        XCTAssertTrue(script.contains("CFBundleShortVersionString"))
        XCTAssertTrue(script.contains("EXPECTED_TAG=\"v$APP_VERSION\""))
        XCTAssertTrue(script.contains("Stable release tag matches app version."))
        XCTAssertTrue(script.contains("sha256:"))
        XCTAssertTrue(script.contains("shasum -a 256"))
        XCTAssertTrue(script.contains("Local DMG digest matches stable release."))
        XCTAssertTrue(script.contains("exit 6"))
        XCTAssertTrue(script.contains("exit 7"))
        XCTAssertTrue(script.contains("Stable release DMG digest"))
        XCTAssertTrue(script.contains("exit 5"))
        XCTAssertTrue(script.contains("No stable public release"))
        XCTAssertTrue(script.contains("exit 4"))
        XCTAssertFalse(script.contains("Release metadata is explicitly not ready for stable download claims."))
    }

    func testManualReleaseChecklistCoversHumanOnlyProof() throws {
        let requirements = try loadText(relativeToThisFile: "../../REQUIREMENTS.md")
        let checklist = try loadText(relativeToThisFile: "../../MANUAL_RELEASE_CHECKS.md")
        let checker = try loadText(relativeToThisFile: "../../Scripts/manual-release-evidence-check.sh")

        XCTAssertTrue(requirements.contains("MANUAL_RELEASE_CHECKS.md"))
        XCTAssertTrue(requirements.contains("make manual-release-evidence-check"))
        XCTAssertTrue(checklist.contains("make release-readiness"))
        XCTAssertTrue(checklist.contains("signed, notarized"))
        XCTAssertTrue(checklist.contains("Gatekeeper-accepted DMG"))
        XCTAssertTrue(checklist.contains("Finder or LaunchServices"))
        XCTAssertTrue(checklist.contains("Screen Recording denied"))
        XCTAssertTrue(checklist.contains("Screen Recording"))
        XCTAssertTrue(checklist.contains("Negative preset"))
        XCTAssertTrue(checklist.contains("drag `CursorDesigner.app` to `/Applications`"))
        XCTAssertTrue(checklist.contains("system-wide pointer replacement is not enabled"))
        XCTAssertTrue(checklist.contains("SHA-256 digest"))
        XCTAssertTrue(checklist.contains("network, telemetry, cloud processing"))
        XCTAssertTrue(checklist.contains("## Evidence Record Template"))
        XCTAssertTrue(checklist.contains("shasum -a 256 CursorDesigner.dmg"))
        XCTAssertTrue(checklist.contains("spctl --assess --type open --verbose=4 CursorDesigner.dmg"))
        XCTAssertTrue(checklist.contains("xcrun stapler validate CursorDesigner.dmg"))
        XCTAssertTrue(checklist.contains("Pass/fail"))
        XCTAssertTrue(checklist.contains("Blocker disposition"))
        XCTAssertTrue(checker.contains("Release tag:"))
        XCTAssertTrue(checker.contains("APP-1 menu bar launch:"))
        XCTAssertTrue(checker.contains("APP-8 local-first product truth:"))
        XCTAssertTrue(checker.contains("Manual release evidence is incomplete"))
        XCTAssertTrue(checker.contains("Pass/fail"))
    }

    private func loadPlist(relativeToThisFile relativePath: String) throws -> [String: Any] {
        let testFile = URL(fileURLWithPath: #filePath)
        let plistURL = testFile
            .deletingLastPathComponent()
            .appendingPathComponent(relativePath)
            .standardizedFileURL
        let data = try Data(contentsOf: plistURL)
        let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
        return try XCTUnwrap(plist as? [String: Any])
    }

    private func loadText(relativeToThisFile relativePath: String) throws -> String {
        let testFile = URL(fileURLWithPath: #filePath)
        let fileURL = testFile
            .deletingLastPathComponent()
            .appendingPathComponent(relativePath)
            .standardizedFileURL
        return try String(contentsOf: fileURL, encoding: .utf8)
    }
}
