# Cursor Designer App Requirements

This document turns the repo North Star into an app-side execution checklist.
It is the durable bridge between product intent, implementation work, local
proof, and release blockers for the macOS app in `apps/macos`.

Cursor Designer is not mass-production ready until every requirement below is
either verified by live evidence or explicitly marked blocked.

## Requirement Map

| ID | Requirement | Current proof path | Status |
|----|-------------|--------------------|--------|
| APP-1 | Launch as a menu bar utility on supported macOS versions without extra setup beyond documented permissions. | `make launch-smoke`; `swift test --package-path apps/macos`; `make preflight` | Locally verified by launch smoke and package gates. |
| APP-2 | Persist pointer settings across quit, relaunch, crash recovery, and migration from legacy app-support paths. | `swift test --package-path apps/macos --filter CursorStateControllerTests`; `swift test --package-path apps/macos --filter AppSupportMigratorTests`; `swift test --package-path apps/macos --filter CrashRecoveryManagerTests` | Unit verified; full UI persistence still needs release-candidate manual proof. |
| APP-3 | Keep the Negative preset and custom color path visible, saved, and tested. | `swift test --package-path apps/macos --filter CursorSettingsTests`; `swift test --package-path apps/macos --filter CursorStateControllerTests` | Unit verified. |
| APP-4 | Make dynamic contrast honest with and without Screen Recording permission. | `swift test --package-path apps/macos --filter CursorStateControllerTests`; Preferences UI must show active, inactive, or permission-required state. | Controller and Preferences state verified; real permission flow still needs release-candidate manual proof. |
| APP-5 | Hide, disable, or mark unsupported helper and system-wide replacement paths unavailable. | `swift test --package-path apps/macos --filter IdentityTests`; `swift test --package-path apps/macos --filter CursorStateControllerTests`; `./scripts/check-monorepo-references.sh` | Locally verified; system-wide replacement remains unsupported. |
| APP-6 | Produce a validated app bundle and DMG from the repo-local macOS package. | `make preflight`; `make dmg`; `make dmg-install-check` | Locally verified when the gates pass on the candidate artifact. |
| APP-7 | Verify signing, notarization, release metadata, and install instructions before public distribution. | `make sign`; `make create-dmg`; `make release-readiness`; `make release-metadata-check` | Blocked until notarization credentials/profile and stable release metadata exist. |
| APP-8 | Keep wrong-product language, telemetry, trackers, surprise network calls, and placeholder release claims out of user-facing surfaces. | `./scripts/check-monorepo-references.sh`; `./scripts/check-local-first.sh`; `swift test --package-path apps/macos --filter IdentityTests` | Guarded locally; repeat before release. |

## Release-Candidate Proof

Run these from the monorepo root unless a command says otherwise:

```bash
./scripts/check-monorepo-references.sh
./scripts/check-local-first.sh
swift test --package-path apps/macos
(cd apps/macos && make preflight)
(cd apps/macos && make launch-smoke)
(cd apps/macos && make dmg)
(cd apps/macos && make dmg-install-check)
```

For public distribution, add the signed/notarized artifact gates:

```bash
(cd apps/macos && make sign SIGN_IDENTITY="<Developer ID Application identity>")
(cd apps/macos && make create-dmg)
(cd apps/macos && make release-readiness NOTARY_PROFILE="<notarytool profile>")
(cd apps/macos && make release-metadata-check)
```

Do not substitute a green test suite for signing, notarization, DMG install,
release metadata, or real permission-flow proof.

## Manual Release-Candidate Checks

These checks require a built app running on macOS and cannot be honestly proven
by unit tests alone:

- Launch from Finder or LaunchServices and confirm the menu bar item appears.
- Open Preferences and verify Theme, Cursor Color, Cursor Size, Visual Effects,
  Contrast Mode, Outline Width, Background Sampling Rate, Screen Recording,
  Pointer Scope, and Launch at Login are visible and truthful.
- Toggle contrast mode between None, Auto-Invert, and Outline with Screen
  Recording denied and granted. The UI must say when dynamic contrast is
  inactive, active, or paused for permission. Preserve the user-facing truth
  that "Dynamic contrast is active" only when background sampling can actually
  run.
- Apply the Negative preset, quit, relaunch, and confirm settings persist.
- Drag-install from the DMG, launch the installed app, and confirm the same
  preference behavior from the installed bundle.

## Blockers

The app must stay explicitly not-ready for broad distribution while any of
these are true:

- System-wide pointer replacement is not implemented, supported, and proven.
- Helper installation is scaffolded but not a user-facing capability.
- The DMG is unsigned, unstapled, or rejected by Gatekeeper.
- notarytool profile credentials are missing or notarization fails.
- There is no verified stable GitHub release metadata for public downloads.
- Homebrew install instructions or casks are not backed by a verified stable
  artifact.

## Documentation Rule

When a requirement changes, update this file in the same branch as the code,
test, script, or release-flow change. The README can explain user workflows,
but this file owns the app-side proof map.
