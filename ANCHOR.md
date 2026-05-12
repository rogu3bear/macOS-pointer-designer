# Cursor Designer Anchor

## Purpose

This file captures the truths that should stay stable while the code evolves.
If a proposal conflicts with these anchors, the burden is on the proposal.

## Product Anchors

- This repository is Cursor Designer, a macOS cursor customization app.
- Cursor Designer is not WindowDrop and must not inherit WindowDrop's website,
  release metadata, deployment flow, or product language.
- The primary product surface is the macOS app under `apps/macos`.
- The app is menu bar first. It is not a dock-first design tool or a general
  system automation suite.
- Preferences preview and ordinary app behavior must remain understandable
  without a helper. Helper scaffolding must not be presented as system-wide
  pointer replacement until the app has a supported, tested implementation.

## Identity Anchors

- The user-facing product name is Cursor Designer.
- Existing Swift target and executable names remain `PointerDesigner` and
  `PointerDesignerHelper` for compatibility until an intentional migration
  changes them.
- `apps/macos/Sources/PointerDesignerCore/Identity.swift` is the code-level
  source of truth for bundle IDs, XPC names, launchd labels, UserDefaults keys,
  app-support names, and notification names.
- Identity changes are authority-sensitive. They can affect XPC communication,
  SMAppService registration, launchd, settings migration, helper installation,
  and existing user preferences.

## Architectural Anchors

- Root repo docs and scripts define monorepo identity and guardrails.
- `apps/macos/Sources/PointerDesigner` contains the main AppKit menu bar app.
- `apps/macos/Sources/PointerDesignerCore` contains the reusable cursor engine,
  settings, display, permission, helper, lifecycle, and recovery logic.
- `apps/macos/Sources/PointerDesignerHelper` contains the helper executable.
- `apps/macos/Tests/PointerDesignerTests` is the main local test surface.
- A future website must be a Cursor Designer-specific surface under
  `apps/website` only after the domain, release source, and deployment owner
  are confirmed.

## Safety Anchors

- No telemetry, trackers, surprise network calls, or hidden cloud dependency in
  the app/helper cursor path.
- Do not silently install or require the helper. Helper installation and admin
  access must stay explicit.
- Do not weaken screen recording permission handling to make dynamic contrast
  appear to work without real permission.
- Restore or fail safe when crashes, signals, settings corruption, helper
  unresponsiveness, or display changes interrupt the cursor path.
- Keep compatibility identifiers stable unless the task explicitly includes a
  migration and verification plan.

## Operational Anchors

- From the monorepo root, run `./scripts/check-monorepo-references.sh`,
  `./scripts/check-website-boundary.sh`,
  `./scripts/check-distribution-boundary.sh`,
  `./scripts/check-compatibility-boundary.sh`,
  `./scripts/check-local-first.sh`, and
  `./scripts/check-app-ui-contract.sh` before product or release claims.
- From the monorepo root, run `swift test --package-path apps/macos` for the
  primary test gate.
- From `apps/macos`, `swift build`, `swift test`, and `make preflight` are the
  package-level build, test, and bundle-validation paths.
- Release, DMG, signing, notarization, and Homebrew cask work belong under
  `apps/macos` and must be verified with the package scripts before claims are
  made.

## Decision Questions

Before changing code, ask:

1. Does this strengthen Cursor Designer's cursor visibility, customization, or
   reliability promise?
2. Does it preserve the Cursor Designer product boundary and avoid importing
   another product's website, deployment, or release identity?
3. Does it respect macOS permissions and keep helper behavior explicit?
4. Does it preserve or intentionally migrate the identifiers in `Identity.swift`?
5. Can the change be verified locally with the root guardrails and targeted
   Swift tests or package preflight?

If the answer to any of these is "no", the change probably needs to be smaller
or differently shaped.
