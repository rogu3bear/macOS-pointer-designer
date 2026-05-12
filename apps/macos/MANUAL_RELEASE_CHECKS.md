# Cursor Designer Manual Release Checks

These checks are required before Cursor Designer can be described as
mass-production ready. They must be run against the signed, notarized,
Gatekeeper-accepted DMG that `make release-readiness` verifies.

Do not use this checklist to waive missing automation. If a check can become a
repeatable script or test, move it into the release gates and keep this file for
human-only macOS permission, Finder, and installed-app behavior.

## Required Candidate

- `make release-readiness` passes for the same local `CursorDesigner.dmg`.
- The stable GitHub release asset digest matches the local DMG digest.
- The DMG opens without bypassing Gatekeeper or changing system security
  settings.

## Checklist

| ID | Requirement | Manual proof |
|----|-------------|--------------|
| APP-1 | Launch as a menu bar utility. | Open `CursorDesigner.app` from Finder or LaunchServices and confirm the menu bar item appears without extra setup beyond documented permissions. |
| APP-2 | Persist settings across normal use. | Change cursor color, cursor size, contrast mode, outline width, sampling rate, pointer scope, and launch-at-login; quit and relaunch; confirm values persist. |
| APP-2 | Recover safely after interruption. | Force quit the running app, relaunch it from the installed bundle, and confirm it restores a safe cursor state without losing saved preferences. |
| APP-3 | Preserve the Negative preset and custom color path. | Apply the Negative preset, confirm black pointer with white outline behavior, then choose a custom color and confirm the UI marks the result as custom. |
| APP-4 | Tell the truth about Screen Recording. | With Screen Recording denied, confirm dynamic contrast is inactive or permission-required and does not claim to be active. |
| APP-4 | Tell the truth after permission is granted. | Grant Screen Recording, restart if macOS requires it, enable Auto-Invert and Outline, and confirm the UI says dynamic contrast is active only while background sampling can run. |
| APP-5 | Keep unsupported helper and system-wide replacement unavailable. | Confirm the Preferences pointer scope surface says system-wide pointer replacement is not enabled in this build and no helper install flow is presented as required. |
| APP-6 | Verify drag-install behavior. | Open the notarized DMG, drag `CursorDesigner.app` to `/Applications`, launch the installed app, and repeat the preference and dynamic contrast checks from the installed bundle. |
| APP-8 | Preserve local-first and website-boundary product truth. | Confirm the app and docs make no network, telemetry, cloud processing, Homebrew, premature website, or stable download claim beyond the verified release artifact. |

## Evidence To Keep With The Release

- macOS version and hardware architecture.
- Release tag, DMG filename, and SHA-256 digest.
- Screen Recording denied and granted observations.
- Finder or LaunchServices launch result.
- Installed `/Applications/CursorDesigner.app` launch result.
- Any blocker, crash, permission mismatch, or misleading copy found during the
  checks.

## Evidence Record Template

Use this template for the release notes or release ticket after
`make release-readiness` passes. Do not fill it with expected results; record
only what was observed against the same signed, notarized, Gatekeeper-accepted
DMG.

To avoid hand-copying the commit and DMG digest, generate the starting record
from the same candidate artifact:

```bash
make manual-release-evidence-template RELEASE_TAG="<stable tag>" > ReleaseEvidence/manual-release-evidence.txt
```

```text
Release tag:
Commit:
macOS version:
Hardware:
DMG filename:
DMG SHA-256:
  shasum -a 256 CursorDesigner.dmg

Machine gates:
- make release-readiness: Pass/fail
- spctl --assess --type open --verbose=4 CursorDesigner.dmg: Pass/fail
- xcrun stapler validate CursorDesigner.dmg: Pass/fail

Manual observations:
- APP-1 menu bar launch:
- APP-2 persistence after quit/relaunch:
- APP-2 recovery after force quit:
- APP-3 Negative preset and custom color:
- APP-4 Screen Recording denied:
- APP-4 Screen Recording granted:
- APP-5 unsupported helper/system-wide replacement unavailable:
- APP-6 drag install from DMG:
- APP-8 local-first and website-boundary product truth:

Blocker disposition:
- None, or list every blocker with owner and decision.
```

The release is blocked if any row above is not performed, fails, or cannot be
truthfully observed on the signed and notarized candidate.
