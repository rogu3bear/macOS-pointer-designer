# Cursor Designer App Requirements

This document turns the repo North Star into an app-side execution checklist.
It is the durable bridge between product intent, implementation work, local
proof, and release blockers for the macOS app in `apps/macos`.

Cursor Designer is not mass-production ready until every requirement below is
either verified by live evidence or explicitly marked blocked.

## Requirement Map

| ID | Requirement | Current proof path | Status |
|----|-------------|--------------------|--------|
| APP-1 | Launch as a menu bar utility on supported macOS versions without extra setup beyond documented permissions. | `make launch-smoke`; `./scripts/check-compatibility-boundary.sh`; `./scripts/check-app-ui-contract.sh`; `swift test --package-path apps/macos`; `make preflight` | Locally verified by launch smoke, compatibility boundary, UI contract, and package gates. |
| APP-2 | Persist pointer settings across quit, relaunch, crash recovery, and migration from legacy app-support paths. | `swift test --package-path apps/macos --filter CursorStateControllerTests`; `swift test --package-path apps/macos --filter AppSupportMigratorTests`; `swift test --package-path apps/macos --filter CrashRecoveryManagerTests` | Unit verified; full UI persistence still needs release-candidate manual proof. |
| APP-3 | Keep the Negative preset and custom color path visible, saved, and tested. | `./scripts/check-app-ui-contract.sh`; `swift test --package-path apps/macos --filter CursorSettingsTests`; `swift test --package-path apps/macos --filter CursorStateControllerTests` | Unit and UI-contract verified. |
| APP-4 | Make dynamic contrast honest with and without Screen Recording permission. | `./scripts/check-app-ui-contract.sh`; `swift test --package-path apps/macos --filter CursorStateControllerTests`; Preferences UI must show active, inactive, or permission-required state. | Controller and Preferences contract verified; real permission flow still needs release-candidate manual proof. |
| APP-5 | Hide, disable, or mark unsupported helper and system-wide replacement paths unavailable. | `./scripts/check-app-ui-contract.sh`; `swift test --package-path apps/macos --filter IdentityTests`; `swift test --package-path apps/macos --filter CursorStateControllerTests`; `./scripts/check-monorepo-references.sh` | Locally verified; system-wide replacement remains unsupported. |
| APP-6 | Produce a validated app bundle and DMG from the repo-local macOS package. | `make preflight`; `make dmg`; `make dmg-install-check`; `make dmg-artifact-match-check` | Locally verified when the gates pass on the candidate artifact. Public artifact gates additionally verify the mounted DMG app matches the release app under assessment. |
| APP-7 | Verify app signing, DMG signing, hardened runtime, Gatekeeper acceptance, notarization, release metadata, manual release evidence, and install instructions before public distribution. | `make signing-identity-check`; `make signed-dmg`; `make release-artifact-readiness`; `make release-readiness`; `make release-metadata-check`; `make manual-release-evidence-check`; `make north-star-audit` | Signing identity, app signing, hardened runtime, mounted app identity/version/executable match, mounted app signature, and DMG signature are locally verified when `make signed-dmg` and `make release-artifact-readiness` reach those checks; public distribution remains blocked until notarization credentials/profile, stapled notarization, Gatekeeper acceptance, manual release evidence, and stable release metadata exist. `make release-metadata-check` also verifies the stable release tag matches app version before comparing the DMG SHA-256 digest. `make north-star-audit` fails until both `make release-readiness` and manual evidence validation pass. |
| APP-8 | Keep wrong-product language, premature website surfaces, premature public distribution instructions, telemetry, trackers, surprise network calls, and placeholder release claims out of user-facing surfaces. | `./scripts/check-monorepo-references.sh`; `./scripts/check-website-boundary.sh`; `./scripts/check-distribution-boundary.sh`; `./scripts/check-local-first.sh`; `swift test --package-path apps/macos --filter IdentityTests` | Guarded locally; repeat before release. |

## Release-Candidate Proof

Run these from the monorepo root unless a command says otherwise:

```bash
./scripts/check-monorepo-references.sh
./scripts/check-website-boundary.sh
./scripts/check-distribution-boundary.sh
./scripts/check-compatibility-boundary.sh
./scripts/check-local-first.sh
./scripts/check-app-ui-contract.sh
swift test --package-path apps/macos
(cd apps/macos && make preflight)
(cd apps/macos && make launch-smoke)
(cd apps/macos && make dmg)
(cd apps/macos && make dmg-install-check)
(cd apps/macos && make dmg-artifact-match-check)
```

For public distribution, add the signed/notarized artifact gates:

```bash
(cd apps/macos && make notary-profile-check NOTARY_PROFILE="<notarytool profile>")
(cd apps/macos && make signing-identity-check SIGN_IDENTITY="<Developer ID Application identity>")
(cd apps/macos && make sign SIGN_IDENTITY="<Developer ID Application identity>")
(cd apps/macos && make create-dmg)
(cd apps/macos && make sign-dmg SIGN_IDENTITY="<Developer ID Application identity>")
(cd apps/macos && make signed-dmg SIGN_IDENTITY="<Developer ID Application identity>")
(cd apps/macos && make release-candidate SIGN_IDENTITY="<Developer ID Application identity>" NOTARY_PROFILE="<notarytool profile>")
(cd apps/macos && make release-artifact-readiness NOTARY_PROFILE="<notarytool profile>")
(cd apps/macos && make release-readiness NOTARY_PROFILE="<notarytool profile>")
(cd apps/macos && make release-metadata-check)
(cd apps/macos && make manual-release-evidence-template RELEASE_TAG="<stable tag>" > ReleaseEvidence/manual-release-evidence.txt)
(cd apps/macos && make manual-release-evidence-check MANUAL_EVIDENCE="<completed evidence file>")
(cd apps/macos && make north-star-audit NOTARY_PROFILE="<notarytool profile>" MANUAL_EVIDENCE="<completed evidence file>")
```

For the ordered e2e release path, use [`RELEASE_RUNBOOK.md`](RELEASE_RUNBOOK.md).

Do not substitute a green test suite for app signing, DMG signing, hardened
runtime, Gatekeeper acceptance, notarization, DMG install, release metadata, or
real permission-flow proof. `make release-readiness` must remain red until
signed/notarized artifacts and stable GitHub release metadata are all verified.

## Manual Release-Candidate Checks

These checks require a signed, notarized app running on macOS and cannot be
honestly proven by unit tests alone. The canonical checklist is
[`MANUAL_RELEASE_CHECKS.md`](MANUAL_RELEASE_CHECKS.md). The release remains
blocked until every row in that checklist is performed against the same
Gatekeeper-accepted DMG that `make release-readiness` verifies and the
completed evidence record passes `make manual-release-evidence-check`. Preserve
the user-facing truth that "Dynamic contrast is active" only when background
sampling can actually run.

## Blockers

The app must stay explicitly not-ready for broad distribution while any of
these are true:

- System-wide pointer replacement is not implemented, supported, and proven.
- Helper installation is scaffolded but not a user-facing capability.
- The DMG is unsigned, unstapled, unnotarized, or rejected by Gatekeeper.
- notarytool profile credentials are missing or notarization fails.
- There is no verified stable GitHub release metadata with a tag matching the
  app version and a SHA-256 digest matching the local DMG for public downloads.
- Homebrew install instructions or casks are not backed by a verified stable
  artifact.

## Documentation Rule

When a requirement changes, update this file in the same branch as the code,
test, script, or release-flow change. The README can explain user workflows,
but this file owns the app-side proof map.
