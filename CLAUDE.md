# CLAUDE.md

Cursor Designer is the macOS cursor customization app in this repository. Claude
and Codex are peer operator agents here; authority comes from the operator,
repo-local doctrine, live git state, and the assigned slice.

Read `ANCHOR.md` and `NORTH_STAR.md` before making changes that could affect
product identity, scope, helper behavior, permissions, release, packaging, or a
future website.

## Core Truths

- The product is Cursor Designer.
- The active app lives in `apps/macos`.
- The Swift package still uses `PointerDesigner` and `PointerDesignerHelper`
  target/executable names for compatibility.
- `apps/macos/Sources/PointerDesignerCore/Identity.swift` is the code-level
  identity authority for bundle IDs, helper IDs, XPC names, launchd labels,
  UserDefaults keys, notification names, and app-support paths.
- There is no canonical Cursor Designer website in this repo yet.

## Core Commands

From the monorepo root:

```bash
./scripts/check-monorepo-references.sh
./scripts/check-website-boundary.sh
./scripts/check-distribution-boundary.sh
./scripts/check-compatibility-boundary.sh
./scripts/check-local-first.sh
./scripts/check-app-ui-contract.sh
swift test --package-path apps/macos
```

From `apps/macos`:

```bash
swift build
swift test
make preflight
make release
make dmg
make setup-notary-profile
make notary-profile-check
make release-candidate
make release-artifact-readiness
make release-readiness
```

Run only the commands that match the claim being made. Do not claim release,
signing, notarization, or installed-helper behavior unless those paths were
actually exercised.
The release authority targets require private Apple/notary inputs from the
operator; do not invent credentials or publish release metadata.

## Guardrails

- Do not conflate Cursor Designer with WindowDrop.
- Do not add another product's website, release metadata, deploy pipeline, or
  product copy to this repo.
- Do not add public download, Homebrew, cask, or stable release instructions
  unless the signed, notarized artifact and stable release metadata are
  verified by the repo gates.
- Keep helper installation explicit and permission-aware.
- Keep screen recording permission behavior truthful.
- Treat persisted permission posture as continuity/diagnostics only; live macOS
  permission checks remain authoritative.
- Treat the `NORTH_STAR.md` production readiness bar as binding. Do not claim
  mass-production readiness without live evidence for every item.
- Keep app/helper behavior local-first and free of telemetry, trackers, and
  surprise network calls.
- Do not rename identity constants or compatibility executable names without an
  explicit migration plan and verification.
- Treat a dirty tree as live operator intent; classify it before editing.

## Documentation

- Product/scope changes must reconcile `ANCHOR.md` and `NORTH_STAR.md`.
- App behavior, architecture, commands, helper behavior, or troubleshooting
  changes must reconcile `apps/macos/README.md`.
- Monorepo layout or website-status changes must reconcile root `README.md`.
- Keep this file and `AGENTS.md` consistent.

## Output Contract

Every response after work should include:

- Summary
- Files touched
- Verification
- Residual risk or skipped checks

Use local evidence and exact paths. Avoid vague CI claims.
Keep hosted CI cheap unless the operator explicitly authorizes a release-grade
CI lane.
