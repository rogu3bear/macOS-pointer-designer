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

    func testOperatorDoctrineListsCurrentRootGuardrails() throws {
        let checkedFiles = [
            "../../../../ANCHOR.md",
            "../../../../AGENTS.md",
            "../../../../CLAUDE.md"
        ]
        let requiredCommands = [
            "./scripts/check-monorepo-references.sh",
            "./scripts/check-website-boundary.sh",
            "./scripts/check-distribution-boundary.sh",
            "./scripts/check-compatibility-boundary.sh",
            "./scripts/check-local-first.sh",
            "./scripts/check-app-ui-contract.sh",
            "swift test --package-path apps/macos"
        ]

        for file in checkedFiles {
            let text = try loadText(relativeToThisFile: file)

            for command in requiredCommands {
                XCTAssertTrue(
                    text.contains(command),
                    "\(file) must list current root guardrail command: \(command)"
                )
            }
        }
    }

    func testOperatorDoctrineListsCurrentReleaseAuthorityLane() throws {
        let checkedFiles = [
            "../../../../ANCHOR.md",
            "../../../../AGENTS.md",
            "../../../../CLAUDE.md"
        ]
        let requiredCommands = [
            "make setup-notary-profile",
            "make notary-profile-check",
            "make release-candidate",
            "make release-artifact-readiness",
            "make release-readiness"
        ]

        for file in checkedFiles {
            let text = try loadText(relativeToThisFile: file)

            for command in requiredCommands {
                XCTAssertTrue(
                    text.contains(command),
                    "\(file) must list current release authority command: \(command)"
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

    func testAppReadmeAvoidsUnbackedMarketingCounts() throws {
        let readme = try loadText(relativeToThisFile: "../../README.md")
        let forbiddenClaims = [
            "70+ edge cases",
            "dozens of edge cases",
            "production-ready",
            "mass-production ready",
            "AI-powered",
            "fake testimonials",
            "placeholder pricing"
        ]

        for claim in forbiddenClaims {
            XCTAssertFalse(
                readme.localizedCaseInsensitiveContains(claim),
                "README must not use unbacked marketing language: \(claim)"
            )
        }

        XCTAssertTrue(readme.contains("## Verified Behavior Areas"))
        XCTAssertTrue(readme.contains("See `swift test --package-path apps/macos`"))
        XCTAssertTrue(readme.contains("make setup-notary-profile"))
        XCTAssertTrue(readme.contains("make notary-profile-check"))
        XCTAssertTrue(readme.contains("make release-candidate"))
        XCTAssertTrue(readme.contains("make release-artifact-readiness"))
        XCTAssertTrue(readme.contains("make release-readiness"))
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

    func testDistributionBoundaryGuardPreventsPrematureDownloadSurface() throws {
        let script = try loadText(relativeToThisFile: "../../../../scripts/check-distribution-boundary.sh")
        let workflow = try loadText(relativeToThisFile: "../../../../.github/workflows/ci.yml")
        let northStar = try loadText(relativeToThisFile: "../../../../NORTH_STAR.md")
        let requirements = try loadText(relativeToThisFile: "../../REQUIREMENTS.md")
        let rootReadme = try loadText(relativeToThisFile: "../../../../README.md")

        XCTAssertTrue(script.contains("Casks apps/macos/Casks homebrew Formula"))
        XCTAssertTrue(script.contains("--glob '*.md'"))
        XCTAssertTrue(script.contains("--glob '!apps/macos/.build/**'"))
        XCTAssertTrue(script.contains("command -v rg"))
        XCTAssertTrue(script.contains("xargs -0 grep -n -F"))
        XCTAssertTrue(script.contains("brew install --cask cursor-designer-osx"))
        XCTAssertTrue(script.contains("Cursor Designer distribution-boundary check passed."))
        XCTAssertTrue(workflow.contains("./scripts/check-distribution-boundary.sh"))
        XCTAssertTrue(northStar.contains("./scripts/check-distribution-boundary.sh"))
        XCTAssertTrue(requirements.contains("./scripts/check-distribution-boundary.sh"))
        XCTAssertTrue(rootReadme.contains("./scripts/check-distribution-boundary.sh"))
    }

    func testCompatibilityBoundaryGuardPreservesMacOSSupportStory() throws {
        let script = try loadText(relativeToThisFile: "../../../../scripts/check-compatibility-boundary.sh")
        let workflow = try loadText(relativeToThisFile: "../../../../.github/workflows/ci.yml")
        let northStar = try loadText(relativeToThisFile: "../../../../NORTH_STAR.md")
        let requirements = try loadText(relativeToThisFile: "../../REQUIREMENTS.md")
        let package = try loadText(relativeToThisFile: "../../Package.swift")
        let infoPlist = try loadText(relativeToThisFile: "../../Sources/PointerDesigner/Resources/Info.plist")
        let appReadme = try loadText(relativeToThisFile: "../../README.md")
        let rootReadme = try loadText(relativeToThisFile: "../../../../README.md")
        let info = try loadPlist(relativeToThisFile: "../../Sources/PointerDesigner/Resources/Info.plist")

        XCTAssertTrue(script.contains(".macOS(.v13)"))
        XCTAssertTrue(script.contains("LSMinimumSystemVersion"))
        XCTAssertTrue(script.contains("macOS 13.0 (Ventura) or later"))
        XCTAssertTrue(script.contains("Cursor Designer compatibility-boundary check passed."))
        XCTAssertTrue(workflow.contains("./scripts/check-compatibility-boundary.sh"))
        XCTAssertTrue(northStar.contains("./scripts/check-compatibility-boundary.sh"))
        XCTAssertTrue(requirements.contains("./scripts/check-compatibility-boundary.sh"))
        XCTAssertTrue(rootReadme.contains("./scripts/check-compatibility-boundary.sh"))
        XCTAssertTrue(package.contains(".macOS(.v13)"))
        XCTAssertTrue(infoPlist.contains("LSMinimumSystemVersion"))
        XCTAssertTrue(infoPlist.contains("13.0"))
        XCTAssertEqual(info["LSMinimumSystemVersion"] as? String, "13.0")
        XCTAssertTrue(appReadme.contains("macOS 13.0 (Ventura) or later"))
    }

    func testWebsiteBoundaryGuardPreventsPrematureWebsiteSurface() throws {
        let script = try loadText(relativeToThisFile: "../../../../scripts/check-website-boundary.sh")
        let workflow = try loadText(relativeToThisFile: "../../../../.github/workflows/ci.yml")
        let northStar = try loadText(relativeToThisFile: "../../../../NORTH_STAR.md")
        let rootReadme = try loadText(relativeToThisFile: "../../../../README.md")

        XCTAssertTrue(script.contains("apps/website"))
        XCTAssertTrue(script.contains("wrangler.toml"))
        XCTAssertTrue(script.contains("leptos.toml"))
        XCTAssertTrue(script.contains("package.json"))
        XCTAssertTrue(script.contains("website or Cloudflare/Leptos scaffold exists"))
        XCTAssertTrue(script.contains("Do not scaffold a generic SaaS site"))
        XCTAssertTrue(script.contains("technical base only"))
        XCTAssertTrue(script.contains("privacy-preserving download routing"))
        XCTAssertTrue(script.contains("release metadata reads, digest display"))
        XCTAssertTrue(script.contains("add accounts, dashboards, analytics"))
        XCTAssertTrue(script.contains("Use the operator's Leptos Cloudflare template only as the technical base"))
        XCTAssertTrue(script.contains("Avoid stock-layout filler"))
        XCTAssertTrue(script.contains("no fake testimonials"))
        XCTAssertTrue(script.contains("No canonical Cursor Designer website exists"))
        XCTAssertTrue(script.contains("Cursor Designer website boundary check passed."))
        XCTAssertTrue(workflow.contains("./scripts/check-website-boundary.sh"))
        XCTAssertTrue(northStar.contains("A public website must not exist until"))
        XCTAssertTrue(rootReadme.contains("There is no canonical Cursor Designer website"))
        XCTAssertTrue(rootReadme.contains("./scripts/check-website-boundary.sh"))
        XCTAssertTrue(rootReadme.contains("Leptos Cloudflare"))
        XCTAssertTrue(rootReadme.contains("technical base only"))
        XCTAssertTrue(rootReadme.contains("Do not scaffold a generic SaaS site"))
        XCTAssertTrue(rootReadme.contains("static-first"))
        XCTAssertTrue(rootReadme.contains("Leptos UI"))
        XCTAssertTrue(rootReadme.contains("verified release metadata reads"))
        XCTAssertTrue(rootReadme.contains("privacy-preserving download routing"))
        XCTAssertTrue(rootReadme.contains("add accounts, dashboards, analytics"))
        XCTAssertTrue(rootReadme.contains("marketing surface that outruns"))
        XCTAssertTrue(rootReadme.contains("the verified app and release artifact"))
    }

    func testNorthStarDefinesProductionReadinessBar() throws {
        let northStar = try loadText(relativeToThisFile: "../../../../NORTH_STAR.md")
        let rootReadme = try loadText(relativeToThisFile: "../../../../README.md")
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

        let requiredProductTruths = [
            "The pointer is the product",
            "Preserve last-known permission posture for continuity and diagnostics",
            "live macOS permission checks authoritative",
            "There is no canonical Cursor Designer website in this repository yet",
            "Hosted CI is intentionally cheap",
            "cheap boundary smoke only",
            "Use the operator's Leptos Cloudflare template only as the technical base",
            "not as a source of generic SaaS language or filler sections",
            "static-first",
            "Leptos UI",
            "Cloudflare edge delivery",
            "release metadata reads, digest display",
            "privacy-preserving download routing",
            "Do not add accounts, dashboards, analytics",
            "Avoid stock-layout filler",
            "vague \"AI-powered\" copy",
            "no fake testimonials",
            "no placeholder pricing",
            "Homebrew or cask distribution is optional",
            "A public website must not exist until the product has a real release source",
            "Current release-authority blockers are tracked in GitHub issue #71",
            "https://github.com/rogu3bear/macOS-pointer-designer/issues/71",
            "issue open until the final North Star audit passes",
            "99% sure this product is ready to use for mass production",
            "the final North Star audit, public release readiness, and artifact-bound manual",
            "release evidence have all passed",
            "Before declaring the objective complete, build a prompt-to-artifact checklist"
        ]

        for truth in requiredProductTruths {
            XCTAssertTrue(
                northStar.contains(truth),
                "NORTH_STAR.md must preserve product truth: \(truth)"
            )
        }

        let requiredGates = [
            "apps/macos/REQUIREMENTS.md",
            "README.md",
            "apps/macos/MANUAL_RELEASE_CHECKS.md",
            "./scripts/check-website-boundary.sh",
            "./scripts/check-distribution-boundary.sh",
            "./scripts/check-compatibility-boundary.sh",
            "./scripts/check-local-first.sh",
            "./scripts/check-app-ui-contract.sh",
            "make launch-smoke",
            "make dmg-install-check",
            "make dmg-artifact-match-check",
            "mounted DMG app must match the release app",
            "make signing-identity-check",
            "make release-source-state-check",
            "make setup-notary-profile",
            "make notary-profile-check",
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

        for doctrineFile in ["NORTH_STAR.md", "ANCHOR.md", "AGENTS.md", "CLAUDE.md"] {
            XCTAssertTrue(
                rootReadme.contains(doctrineFile),
                "README.md must route operators to \(doctrineFile)"
            )
        }
        XCTAssertTrue(rootReadme.contains("pointer-first product promise"))
        XCTAssertTrue(rootReadme.contains("readiness bar, website standard"))
        XCTAssertTrue(rootReadme.contains("Cursor Designer is not advertised as a stable public download yet"))
        XCTAssertTrue(rootReadme.contains("make setup-notary-profile"))
        XCTAssertTrue(rootReadme.contains("make notary-profile-check"))
        XCTAssertTrue(rootReadme.contains("make release-source-state-check"))
        XCTAssertTrue(rootReadme.contains("make release-candidate"))
        XCTAssertTrue(rootReadme.contains("make release-artifact-readiness"))
        XCTAssertTrue(rootReadme.contains("make release-readiness"))
        XCTAssertTrue(rootReadme.contains("make north-star-audit"))
        XCTAssertTrue(rootReadme.contains("notarized, stapled, Gatekeeper-accepted artifact"))
        XCTAssertTrue(rootReadme.contains("completed manual release evidence"))
        XCTAssertTrue(rootReadme.contains("NOTARY_KEY_PATH"))
        XCTAssertTrue(rootReadme.contains("NOTARY_KEY_ID"))
        XCTAssertTrue(rootReadme.contains("NOTARY_ISSUER_ID"))
        XCTAssertTrue(rootReadme.contains("NOTARY_APPLE_ID"))
        XCTAssertTrue(rootReadme.contains("NOTARY_TEAM_ID"))
        XCTAssertTrue(rootReadme.contains("notarytool` prompts"))
        XCTAssertTrue(rootReadme.contains("Do not commit Apple IDs"))
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
            "make dmg-artifact-match-check REQUIRE_SIGNATURE=1",
            "last-known permission posture",
            "persisted permission posture must not be presented",
            "make signing-identity-check",
            "make release-source-state-check",
            "make setup-notary-profile",
            "make notary-profile-check",
            "make signed-dmg",
            "make release-candidate",
            "make release-artifact-readiness",
            "make release-readiness",
            "make release-metadata-check",
            "mounted DMG app matches the release app",
            "stable release tag matches app version",
            "./scripts/check-website-boundary.sh",
            "./scripts/check-distribution-boundary.sh",
            "./scripts/check-compatibility-boundary.sh",
            "./scripts/check-local-first.sh",
            "./scripts/check-app-ui-contract.sh",
            "Dynamic contrast is active",
            "System-wide pointer replacement is presented as available",
            "Helper installation is presented as required",
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

    func testCIStaysCheapAndDefersMacOSReleaseProofToLocalGates() throws {
        let workflow = try loadText(relativeToThisFile: "../../../../.github/workflows/ci.yml")

        XCTAssertTrue(workflow.contains("runs-on: ubuntu-latest"))
        XCTAssertTrue(workflow.contains("./scripts/check-monorepo-references.sh"))
        XCTAssertTrue(workflow.contains("./scripts/check-website-boundary.sh"))
        XCTAssertTrue(workflow.contains("./scripts/check-distribution-boundary.sh"))
        XCTAssertTrue(workflow.contains("./scripts/check-compatibility-boundary.sh"))
        XCTAssertTrue(workflow.contains("./scripts/check-local-first.sh"))
        XCTAssertTrue(workflow.contains("./scripts/check-app-ui-contract.sh"))
        XCTAssertFalse(workflow.contains("runs-on: macos-14"))
        XCTAssertFalse(workflow.contains("swift test --package-path apps/macos"))
        XCTAssertFalse(workflow.contains("make -C apps/macos preflight"))
        XCTAssertFalse(workflow.contains("make -C apps/macos dmg"))
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
        XCTAssertTrue(script.contains("last-known permission posture"))
        XCTAssertTrue(script.contains("optional Homebrew/cask truth"))
        XCTAssertTrue(script.contains("APP-8"))
        XCTAssertTrue(script.contains("future Leptos/Cloudflare work is limited"))
        XCTAssertTrue(script.contains("static-first Leptos UI"))
        XCTAssertTrue(script.contains("verified release metadata reads, digest display"))
        XCTAssertTrue(script.contains("privacy-preserving download routing"))
        XCTAssertTrue(script.contains("Hosted CI"))
        XCTAssertTrue(script.contains("cheap boundary smoke only"))
        XCTAssertTrue(script.contains("local macOS package, DMG, signing, notarization, permission-flow, and release-evidence gates remain authoritative"))
        XCTAssertTrue(script.contains("release-readiness"))
        XCTAssertTrue(script.contains("release-source-state-check"))
        XCTAssertTrue(script.contains("setup-notary-profile"))
        XCTAssertTrue(script.contains("notary-profile-check"))
        XCTAssertTrue(script.contains("release-metadata-check"))
        XCTAssertTrue(script.contains("artifact-bound human evidence"))
        XCTAssertTrue(script.contains("mounted app bundle ID"))
        XCTAssertTrue(script.contains("app executable SHA-256"))
        XCTAssertTrue(script.contains("check-website-boundary.sh"))
        XCTAssertTrue(script.contains("check-distribution-boundary.sh"))
        XCTAssertTrue(script.contains("check-compatibility-boundary.sh"))
        XCTAssertTrue(script.contains("Website boundary"))
        XCTAssertTrue(script.contains("Distribution boundary"))
        XCTAssertTrue(script.contains("Compatibility boundary"))
        XCTAssertTrue(script.contains("Core macOS behavior"))
        XCTAssertTrue(script.contains("swift test"))
        XCTAssertTrue(script.contains("Current app launch smoke"))
        XCTAssertTrue(script.contains("launch-smoke.sh"))
        XCTAssertTrue(script.contains("manual-release-evidence-check.sh"))
        XCTAssertTrue(script.contains("Manual release evidence"))
        XCTAssertTrue(script.contains("not mass-production ready"))
        XCTAssertTrue(script.contains("No canonical Cursor Designer website exists;"))
    }

    func testLocalFirstGuardChecksAppSourceForNetworkAndTelemetry() throws {
        let script = try loadText(relativeToThisFile: "../../../../scripts/check-local-first.sh")
        let workflow = try loadText(relativeToThisFile: "../../../../.github/workflows/ci.yml")
        let rootReadme = try loadText(relativeToThisFile: "../../../../README.md")
        let requirements = try loadText(relativeToThisFile: "../../REQUIREMENTS.md")

        XCTAssertTrue(script.contains("command -v rg"))
        XCTAssertTrue(script.contains("apps/macos/Sources"))
        XCTAssertTrue(script.contains("URLSession"))
        XCTAssertTrue(script.contains("UpdateChecker.swift"))
        XCTAssertTrue(script.contains("allowsInternetAccess"))
        XCTAssertTrue(script.contains("NSURLConnection"))
        XCTAssertTrue(script.contains("NWConnection"))
        XCTAssertTrue(script.contains("SentrySDK"))
        XCTAssertTrue(script.contains("FirebaseApp"))
        XCTAssertTrue(script.contains("TelemetryDeck"))
        XCTAssertTrue(script.contains(".package(url:"))
        XCTAssertTrue(script.contains("https://"))
        XCTAssertTrue(script.contains("xargs -0 grep -n -F"))
        XCTAssertTrue(script.contains("Cursor Designer local-first app check passed."))
        XCTAssertFalse(workflow.contains("apt-get install"))
        XCTAssertFalse(workflow.contains("ripgrep"))
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
        XCTAssertTrue(script.contains("Last checked: Screen Recording"))
        XCTAssertTrue(script.contains("Live macOS permission checks decide features."))
        XCTAssertTrue(script.contains("System-wide pointer replacement is not enabled in this build."))
        XCTAssertTrue(script.contains("Allow internet access for update checks"))
        XCTAssertTrue(script.contains("Check for Updates"))
        XCTAssertTrue(script.contains("grep -Fq"))
        XCTAssertTrue(script.contains("Cursor Designer app UI contract check passed."))
        XCTAssertTrue(workflow.contains("./scripts/check-app-ui-contract.sh"))
        XCTAssertTrue(rootReadme.contains("./scripts/check-app-ui-contract.sh"))
        XCTAssertTrue(requirements.contains("./scripts/check-app-ui-contract.sh"))
    }

    func testPointerPersistenceResearchDocumentsLeastPermissionBoundary() throws {
        let research = try loadText(relativeToThisFile: "../../POINTER_PERSISTENCE_RESEARCH.md")
        let cursorEngine = try loadText(relativeToThisFile: "../../Sources/PointerDesignerCore/CursorEngine.swift")
        let northStar = try loadText(relativeToThisFile: "../../../../NORTH_STAR.md")
        let requirements = try loadText(relativeToThisFile: "../../REQUIREMENTS.md")

        XCTAssertTrue(research.contains("NSCursor.set()"))
        XCTAssertTrue(research.contains("least-permission durable path starts with a supervised pointer"))
        XCTAssertTrue(research.contains("Screen Recording is only justified for dynamic contrast"))
        XCTAssertTrue(research.contains("Accessibility is only justified"))
        XCTAssertTrue(research.contains("Private WindowServer/CGS cursor replacement should stay"))
        XCTAssertTrue(research.contains("https://developer.apple.com/documentation/appkit/nscursor/set%28%29"))
        XCTAssertTrue(research.contains("https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/EventOverview/MouseTrackingEvents/MouseTrackingEvents.html"))
        XCTAssertTrue(cursorEngine.contains("startPersistenceSupervisor"))
        XCTAssertTrue(cursorEngine.contains("NSEvent.addGlobalMonitorForEvents"))
        XCTAssertTrue(cursorEngine.contains("NSWorkspace.didActivateApplicationNotification"))
        XCTAssertTrue(northStar.contains("POINTER_PERSISTENCE_RESEARCH.md"))
        XCTAssertTrue(requirements.contains("APP-10"))
        XCTAssertTrue(requirements.contains("reapply supervisor"))
    }

    func testUpdateChecksAreExplicitlyInternetGated() throws {
        let preferences = try loadText(relativeToThisFile: "../../Sources/PointerDesigner/PreferencesWindowController.swift")
        let settings = try loadText(relativeToThisFile: "../../Sources/PointerDesignerCore/CursorSettings.swift")
        let checker = try loadText(relativeToThisFile: "../../Sources/PointerDesignerCore/UpdateChecker.swift")
        let northStar = try loadText(relativeToThisFile: "../../../../NORTH_STAR.md")
        let requirements = try loadText(relativeToThisFile: "../../REQUIREMENTS.md")

        XCTAssertTrue(preferences.contains("Allow internet access for update checks"))
        XCTAssertTrue(preferences.contains("Check for Updates"))
        XCTAssertTrue(settings.contains("allowsInternetUpdateChecks"))
        XCTAssertTrue(checker.contains("guard allowsInternetAccess else"))
        XCTAssertTrue(checker.contains("internetAccessNotAllowed"))
        XCTAssertTrue(northStar.contains("Update checks are allowed only"))
        XCTAssertTrue(requirements.contains("APP-9"))
    }

    func testTrustCheckDoesNotClaimCursorApplicationRequiresHelper() throws {
        let trustCheck = try loadText(relativeToThisFile: "../../Scripts/trust-check.sh")

        XCTAssertFalse(trustCheck.localizedCaseInsensitiveContains("Can Apply Cursor:     Run app to verify (requires helper)"))
        XCTAssertFalse(trustCheck.localizedCaseInsensitiveContains("requires helper"))
        XCTAssertFalse(trustCheck.localizedCaseInsensitiveContains("Embedded Helper:"))
        XCTAssertFalse(trustCheck.localizedCaseInsensitiveContains("XPC Mach Service:"))
    }

    func testAppLaunchRefreshesPermissionPostureForPersistence() throws {
        let appDelegate = try loadText(relativeToThisFile: "../../Sources/PointerDesigner/AppDelegate.swift")

        XCTAssertTrue(appDelegate.contains("CursorStateController.shared.refreshPermissionState()"))
        XCTAssertTrue(appDelegate.contains("SettingsManager.shared.currentSettings"))
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
            "../../Scripts/setup-notary-profile.sh": "ERROR: --notary-profile requires a name",
            "../../Scripts/notary-profile-check.sh": "ERROR: --notary-profile requires a name",
            "../../Scripts/release-source-state-check.sh": "ERROR: --app requires a path",
            "../../Scripts/release-metadata-check.sh": "ERROR: --repo requires OWNER/REPO",
            "../../Scripts/release-readiness.sh": "ERROR: --notary-profile requires a name",
            "../../Scripts/manual-release-evidence-check.sh": "ERROR: --evidence requires a path",
            "../../Scripts/manual-release-evidence-template.sh": "ERROR: --dmg requires a path",
            "../../Scripts/north-star-audit.sh": "ERROR: --manual-evidence requires a path"
        ]

        for (scriptPath, requiredMessage) in scriptsByRequiredMessage {
            let script = try loadText(relativeToThisFile: scriptPath)

            XCTAssertTrue(script.contains(requiredMessage), "\(scriptPath) must validate missing option values")
            XCTAssertTrue(script.contains("exit 2"), "\(scriptPath) must treat CLI usage errors as exit 2")
        }

        let manualEvidenceCheck = try loadText(relativeToThisFile: "../../Scripts/manual-release-evidence-check.sh")
        XCTAssertTrue(manualEvidenceCheck.contains("ERROR: --dmg requires a path"))
        XCTAssertTrue(manualEvidenceCheck.contains("ERROR: --commit requires a commit"))

        let manualEvidenceTemplate = try loadText(relativeToThisFile: "../../Scripts/manual-release-evidence-template.sh")
        XCTAssertTrue(manualEvidenceTemplate.contains("ERROR: --release-tag requires a tag"))
        XCTAssertTrue(manualEvidenceTemplate.contains("ERROR: --commit requires a commit"))
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
        let notaryProfileSetup = try loadText(relativeToThisFile: "../../Scripts/setup-notary-profile.sh")
        let signingIdentityCheck = try loadText(relativeToThisFile: "../../Scripts/signing-identity-check.sh")

        XCTAssertTrue(makefile.contains("dmg: release create-dmg"))
        XCTAssertTrue(makefile.contains("signed-dmg: sign create-dmg sign-dmg"))
        XCTAssertTrue(makefile.contains("sign-dmg:"))
        XCTAssertTrue(makefile.contains("signing-identity-check:"))
        XCTAssertTrue(makefile.contains(#"signing-identity-check.sh --sign-identity "$(SIGN_IDENTITY)""#))
        XCTAssertTrue(makefile.contains("setup-notary-profile:"))
        XCTAssertTrue(makefile.contains(#"setup-notary-profile.sh --notary-profile "$(NOTARY_PROFILE)""#))
        XCTAssertTrue(makefile.contains("notary-profile-check:"))
        XCTAssertTrue(makefile.contains(#"notary-profile-check.sh --notary-profile "$(NOTARY_PROFILE)""#))
        XCTAssertTrue(signingIdentityCheck.contains("security find-identity -v -p codesigning"))
        XCTAssertTrue(signingIdentityCheck.contains("Resolved default signing identity"))
        XCTAssertTrue(signingIdentityCheck.contains("multiple Developer ID Application identities are available"))
        XCTAssertTrue(signingIdentityCheck.contains("ERROR: signing identity"))
        XCTAssertTrue(signingIdentityCheck.contains("Do not commit certificates"))
        XCTAssertTrue(notaryProfileCheck.contains("notarytool history --keychain-profile"))
        XCTAssertTrue(notaryProfileCheck.contains("notarytool store-credentials"))
        XCTAssertTrue(notaryProfileCheck.contains("Omit --password"))
        XCTAssertTrue(notaryProfileCheck.contains("App Store Connect API key"))
        XCTAssertTrue(notaryProfileCheck.contains("--key-id"))
        XCTAssertTrue(notaryProfileCheck.contains("--issuer"))
        XCTAssertTrue(notaryProfileCheck.contains("add --issuer for team API keys"))
        XCTAssertTrue(notaryProfileCheck.contains("Do not commit Apple IDs"))
        XCTAssertTrue(notaryProfileSetup.contains("NOTARY_KEY_PATH"))
        XCTAssertTrue(notaryProfileSetup.contains("NOTARY_KEY_ID"))
        XCTAssertTrue(notaryProfileSetup.contains("NOTARY_ISSUER_ID"))
        XCTAssertTrue(notaryProfileSetup.contains("optional for individual API keys"))
        XCTAssertTrue(notaryProfileSetup.contains("required for team API"))
        XCTAssertTrue(notaryProfileSetup.contains("Set NOTARY_ISSUER_ID too when using a team API key."))
        XCTAssertTrue(notaryProfileSetup.contains(#"CMD+=(--issuer "$ISSUER_ID")"#))
        XCTAssertTrue(notaryProfileSetup.contains("NOTARY_APP_SPECIFIC_PASSWORD"))
        XCTAssertTrue(notaryProfileSetup.contains("Preferred Apple ID setup is interactive"))
        XCTAssertTrue(notaryProfileSetup.contains("this notarytool build has no password-stdin"))
        XCTAssertTrue(notaryProfileSetup.contains("Prefer the interactive prompt when possible"))
        XCTAssertTrue(notaryProfileSetup.contains("Run this target from an interactive shell so notarytool can prompt securely."))
        XCTAssertFalse(notaryProfileSetup.contains("read -r -s -p"))
        XCTAssertTrue(notaryProfileSetup.contains("notarytool store-credentials"))
        XCTAssertTrue(notaryProfileSetup.contains("notarytool history --keychain-profile"))
        XCTAssertTrue(notaryProfileSetup.contains("Do not commit Apple IDs"))
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
        let sourceStateCheck = try loadText(relativeToThisFile: "../../Scripts/release-source-state-check.sh")

        XCTAssertTrue(makefile.contains("release-readiness:"))
        XCTAssertTrue(makefile.contains("release-source-state-check:"))
        XCTAssertTrue(makefile.contains("release-source-state-check.sh"))
        XCTAssertTrue(makefile.contains(#"--repo "$(GITHUB_REPO)""#))
        XCTAssertTrue(script.contains(#"--dmg "$DMG_PATH""#))
        XCTAssertTrue(script.contains("--skip-release-metadata"))
        XCTAssertTrue(script.contains("Release artifact readiness passed."))
        XCTAssertTrue(script.contains("Run make release-readiness after publishing stable release metadata."))
        XCTAssertTrue(script.contains("dmg-install-check.sh"))
        XCTAssertTrue(script.contains("release-metadata-check.sh"))
        XCTAssertTrue(script.contains("Stable release metadata matches app version and DMG digest"))
        XCTAssertTrue(script.contains("Release source tree is clean"))
        XCTAssertTrue(script.contains("release-source-state-check.sh"))
        XCTAssertTrue(script.contains("Commit the release tranche, rebuild/sign/notarize the DMG"))
        XCTAssertTrue(script.contains("--require-signature"))
        XCTAssertTrue(script.contains("--repo"))
        XCTAssertTrue(script.contains("codesign --verify --deep --strict"))
        XCTAssertTrue(script.contains("check_hardened_runtime"))
        XCTAssertTrue(script.contains("Runtime Version"))
        XCTAssertTrue(script.contains("Hardened runtime is enabled"))
        XCTAssertTrue(script.contains("spctl --assess --type execute"))
        XCTAssertTrue(script.contains("spctl --assess --type open"))
        XCTAssertTrue(script.contains("--context context:primary-signature"))
        XCTAssertTrue(script.contains("Gatekeeper primary-signature assessment accepts DMG"))
        XCTAssertTrue(script.contains("DMG install surface, mounted app match, and mounted app signature verify"))
        XCTAssertTrue(script.contains("DMG signature verifies"))
        XCTAssertTrue(script.contains(#"codesign --verify --verbose=2 "$DMG_PATH""#))
        XCTAssertTrue(script.contains("stapler validate"))
        XCTAssertTrue(script.contains("notarytool history"))
        XCTAssertTrue(script.contains("Distribution blockers:"))
        XCTAssertTrue(script.contains("Next required proof:"))
        XCTAssertTrue(script.contains("Build and sign the app with a Developer ID Application identity"))
        XCTAssertTrue(script.contains("Store or select a valid notarytool profile with make setup-notary-profile"))
        XCTAssertTrue(script.contains("Notarize the signed DMG"))
        XCTAssertTrue(script.contains("tag matches this app version and its SHA-256 digest matches this local DMG"))
        XCTAssertTrue(script.contains("MANUAL_RELEASE_CHECKS.md"))
        XCTAssertTrue(script.contains("FAIL:"))
        XCTAssertTrue(script.contains(#"output=$("$@" 2>&1)"#))
        XCTAssertTrue(script.contains("printf '%s\\n' \"$output\""))
        XCTAssertTrue(script.contains("failures=("))
        XCTAssertTrue(sourceStateCheck.contains("git -C \"$ROOT_DIR\" status --porcelain=v1 --untracked-files=all -- ."))
        XCTAssertTrue(sourceStateCheck.contains("git -C \"$ROOT_DIR\" show -s --format=%ct HEAD"))
        XCTAssertTrue(sourceStateCheck.contains("stat -f %m \"$app_executable\""))
        XCTAssertTrue(sourceStateCheck.contains("stat -f %m \"$DMG_PATH\""))
        XCTAssertTrue(sourceStateCheck.contains("release readiness requires a clean committed tree"))
        XCTAssertTrue(sourceStateCheck.contains("The signed app and DMG must be built from the same committed state"))
        XCTAssertTrue(sourceStateCheck.contains("release app executable is not newer than the release commit"))
        XCTAssertTrue(sourceStateCheck.contains("release DMG is not newer than the release commit"))
    }

    func testDMGInstallGateChecksMountedArtifactShape() throws {
        let makefile = try loadText(relativeToThisFile: "../../Makefile")
        let script = try loadText(relativeToThisFile: "../../Scripts/dmg-install-check.sh")

        XCTAssertTrue(makefile.contains("dmg-install-check:"))
        XCTAssertTrue(makefile.contains(#"dmg-install-check.sh --dmg "$(DMG_NAME)""#))
        XCTAssertFalse(makefile.contains(#"dmg-install-check.sh --dmg "$(DMG_NAME)" --require-signature"#))
        XCTAssertTrue(makefile.contains("REQUIRE_SIGNATURE ?= false"))
        XCTAssertTrue(makefile.contains("DMG_SIGNATURE_FLAGS = $(if $(filter 1 true yes,$(REQUIRE_SIGNATURE)),--require-signature,)"))
        XCTAssertTrue(makefile.contains(#"dmg-install-check.sh --app "$(APP_BUNDLE)" --dmg "$(DMG_NAME)" $(DMG_SIGNATURE_FLAGS)"#))
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
        let template = try loadText(relativeToThisFile: "../../Scripts/manual-release-evidence-template.sh")
        let makefile = try loadText(relativeToThisFile: "../../Makefile")
        let gitignore = try loadText(relativeToThisFile: "../../.gitignore")

        XCTAssertTrue(requirements.contains("MANUAL_RELEASE_CHECKS.md"))
        XCTAssertTrue(requirements.contains("make manual-release-evidence-check"))
        XCTAssertTrue(requirements.contains("make manual-release-evidence-template"))
        XCTAssertTrue(checklist.contains("make release-readiness"))
        XCTAssertTrue(checklist.contains("make manual-release-evidence-template"))
        XCTAssertTrue(checklist.contains("signed, notarized"))
        XCTAssertTrue(checklist.contains("Gatekeeper-accepted DMG"))
        XCTAssertTrue(checklist.contains("Finder or LaunchServices"))
        XCTAssertTrue(checklist.contains("Screen Recording denied"))
        XCTAssertTrue(checklist.contains("Screen Recording"))
        XCTAssertTrue(checklist.contains("last-known permission posture"))
        XCTAssertTrue(checklist.contains("persisted posture is not presented as a permanent grant"))
        XCTAssertTrue(checklist.contains("Negative preset"))
        XCTAssertTrue(checklist.contains("drag `CursorDesigner.app` to `/Applications`"))
        XCTAssertTrue(checklist.contains("system-wide pointer replacement is not enabled"))
        XCTAssertTrue(checklist.contains("SHA-256 digest"))
        XCTAssertTrue(checklist.contains("mounted app identity"))
        XCTAssertTrue(checklist.contains("executable SHA-256 digest"))
        XCTAssertTrue(checklist.contains("network, telemetry, cloud processing"))
        XCTAssertTrue(checklist.contains("generic SaaS, account, dashboard, analytics"))
        XCTAssertTrue(checklist.contains("placeholder pricing, fake testimonial"))
        XCTAssertTrue(checklist.contains("future Leptos/Cloudflare language"))
        XCTAssertTrue(checklist.contains("privacy-preserving download routing"))
        XCTAssertTrue(checklist.contains("## Evidence Record Template"))
        XCTAssertFalse(checklist.contains("App executable SHA-256:\n  shasum -a 256 CursorDesigner.dmg"))
        XCTAssertTrue(checklist.contains("spctl --assess --type open --context context:primary-signature --verbose=4 CursorDesigner.dmg"))
        XCTAssertTrue(checklist.contains("xcrun stapler validate CursorDesigner.dmg"))
        XCTAssertTrue(checklist.contains("Pass/fail"))
        XCTAssertTrue(checklist.contains("Blocker disposition"))
        XCTAssertTrue(checker.contains("Release tag:"))
        XCTAssertTrue(checker.contains("--dmg"))
        XCTAssertTrue(checker.contains("--commit"))
        XCTAssertTrue(checker.contains("APP-1 menu bar launch:"))
        XCTAssertTrue(checker.contains("APP-2 last-known permission posture:"))
        XCTAssertTrue(checklist.contains("APP-8 local-first, website-boundary, and future Leptos/Cloudflare product truth:"))
        XCTAssertTrue(checker.contains("APP-8 local-first, website-boundary, and future Leptos/Cloudflare product truth:"))
        XCTAssertTrue(checker.contains("Manual release evidence is incomplete"))
        XCTAssertTrue(checker.contains("Pass/fail"))
        XCTAssertTrue(checker.contains("Recorded DMG filename does not match"))
        XCTAssertTrue(checker.contains("Recorded DMG SHA-256 does not match"))
        XCTAssertTrue(checker.contains("Recorded release tag does not match mounted DMG app version"))
        XCTAssertTrue(checker.contains("Recorded app bundle ID does not match mounted DMG app"))
        XCTAssertTrue(checker.contains("Recorded app executable SHA-256 does not match mounted DMG app"))
        XCTAssertTrue(checker.contains("DMG could not be mounted for app identity verification"))
        XCTAssertTrue(checker.contains("Recorded commit does not match"))
        XCTAssertTrue(checker.contains("non-passing evidence recorded for:"))
        XCTAssertTrue(checker.contains("[Pp]ending"))
        XCTAssertTrue(checker.contains("[Nn]ot[[:space:]]+(run|performed|observed|tested|verified|applicable)"))
        XCTAssertTrue(checker.contains("Blocker disposition must be None"))
        XCTAssertTrue(makefile.contains("manual-release-evidence-template:"))
        XCTAssertTrue(template.contains("Release tag:"))
        XCTAssertTrue(template.contains("ERROR: RELEASE_TAG is required for artifact-bound manual release evidence"))
        XCTAssertTrue(template.contains("make manual-release-evidence-template RELEASE_TAG="))
        XCTAssertTrue(template.contains("v<app-version>"))
        XCTAssertTrue(template.contains("EXPECTED_RELEASE_TAG=\"v$APP_VERSION\""))
        XCTAssertTrue(template.contains("ERROR: RELEASE_TAG does not match mounted app version"))
        XCTAssertTrue(template.contains("Commit:"))
        XCTAssertTrue(template.contains("DMG SHA-256:"))
        XCTAssertTrue(template.contains("App bundle ID:"))
        XCTAssertTrue(template.contains("App executable SHA-256:"))
        XCTAssertTrue(template.contains("hdiutil attach"))
        XCTAssertTrue(template.contains("APP-1 menu bar launch:"))
        XCTAssertTrue(template.contains("APP-2 last-known permission posture:"))
        XCTAssertTrue(template.contains("APP-8 local-first, website-boundary, and future Leptos/Cloudflare product truth:"))
        XCTAssertTrue(template.contains("shasum -a 256"))
        XCTAssertTrue(gitignore.contains("ReleaseEvidence/"))
        XCTAssertTrue(gitignore.contains("notarization-output/"))
    }

    func testReleaseRunbookDrivesEndToEndReadinessWithoutClaimingAvailability() throws {
        let runbook = try loadText(relativeToThisFile: "../../RELEASE_RUNBOOK.md")
        let requirements = try loadText(relativeToThisFile: "../../REQUIREMENTS.md")

        XCTAssertTrue(requirements.contains("RELEASE_RUNBOOK.md"))
        XCTAssertTrue(runbook.contains("# Cursor Designer Release Runbook"))
        XCTAssertTrue(runbook.contains("not mass-production ready"))
        XCTAssertTrue(runbook.contains("xcrun notarytool store-credentials"))
        XCTAssertTrue(runbook.contains("make setup-notary-profile"))
        XCTAssertTrue(runbook.contains("NOTARY_KEY_PATH"))
        XCTAssertTrue(runbook.contains("optional for individual API keys"))
        XCTAssertTrue(runbook.contains("required for team"))
        XCTAssertTrue(runbook.contains("add `--issuer` for team API keys"))
        XCTAssertTrue(runbook.contains("NOTARY_APP_SPECIFIC_PASSWORD"))
        XCTAssertTrue(runbook.contains("target interactively so `notarytool` prompts securely"))
        XCTAssertTrue(runbook.contains("no password-stdin mode"))
        XCTAssertTrue(runbook.contains("`notarytool --password`"))
        XCTAssertTrue(runbook.contains("Omit `--password`"))
        XCTAssertTrue(runbook.contains("App Store Connect API key"))
        XCTAssertTrue(runbook.contains("Do not copy the key into this"))
        XCTAssertTrue(runbook.contains("does not expose a profile-list command"))
        XCTAssertTrue(runbook.contains("exact profile name you created with `store-credentials`"))
        XCTAssertTrue(runbook.contains("make release-candidate"))
        XCTAssertTrue(runbook.contains("make release-source-state-check"))
        XCTAssertTrue(runbook.contains("make release-readiness"))
        XCTAssertTrue(runbook.contains("make manual-release-evidence-template"))
        XCTAssertTrue(runbook.contains("make manual-release-evidence-check"))
        XCTAssertTrue(runbook.contains("mounted app identity"))
        XCTAssertTrue(runbook.contains("release tag"))
        XCTAssertTrue(runbook.contains("executable SHA-256"))
        XCTAssertTrue(runbook.contains("make north-star-audit"))
        XCTAssertTrue(runbook.contains("MANUAL_RELEASE_CHECKS.md"))
        XCTAssertTrue(runbook.contains("stable GitHub release"))
        XCTAssertTrue(runbook.contains("GitHub issue #71"))
        XCTAssertTrue(runbook.contains("https://github.com/rogu3bear/macOS-pointer-designer/issues/71"))
        XCTAssertTrue(runbook.contains("Keep that issue open until this runbook's final audit passes"))
        XCTAssertTrue(runbook.contains("Do not create or publish a website"))
        XCTAssertTrue(runbook.contains("Do not commit Apple IDs"))
        XCTAssertTrue(runbook.contains("Gatekeeper-accepted DMG"))
    }

    func testMakefileScriptTargetsAreExecutable() throws {
        let executableScripts = [
            "../../Scripts/setup-notary-profile.sh",
            "../../Scripts/notary-profile-check.sh",
            "../../Scripts/release-source-state-check.sh",
            "../../Scripts/release-readiness.sh",
            "../../Scripts/north-star-audit.sh",
            "../../Scripts/manual-release-evidence-check.sh",
            "../../Scripts/manual-release-evidence-template.sh"
        ]

        for relativePath in executableScripts {
            let scriptURL = try fileURL(relativeToThisFile: relativePath)
            XCTAssertTrue(
                FileManager.default.isExecutableFile(atPath: scriptURL.path),
                "\(relativePath) must be executable because Makefile invokes it directly"
            )
        }
    }

    private func loadPlist(relativeToThisFile relativePath: String) throws -> [String: Any] {
        let plistURL = try fileURL(relativeToThisFile: relativePath)
        let data = try Data(contentsOf: plistURL)
        let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
        return try XCTUnwrap(plist as? [String: Any])
    }

    private func loadText(relativeToThisFile relativePath: String) throws -> String {
        let fileURL = try fileURL(relativeToThisFile: relativePath)
        return try String(contentsOf: fileURL, encoding: .utf8)
    }

    private func fileURL(relativeToThisFile relativePath: String) throws -> URL {
        let testFile = URL(fileURLWithPath: #filePath)
        return testFile
            .deletingLastPathComponent()
            .appendingPathComponent(relativePath)
            .standardizedFileURL
    }
}
