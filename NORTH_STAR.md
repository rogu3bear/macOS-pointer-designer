# Cursor Designer North Star

## Intent

Cursor Designer exists to make the macOS pointer easier to see, personalize,
and trust across changing desktop backgrounds and displays.

The app should feel like a quiet menu bar utility: present when the user needs
it, local-first, reversible, and respectful of macOS permission boundaries.

## Core User Promise

- Let the user choose a cursor color and contrast behavior without making the
  Mac feel less native.
- Adapt cursor visibility to the current background when the user enables it.
- Keep the app useful without a helper. Do not advertise system-wide pointer
  replacement unless a supported, tested implementation actually enables it.
- Restore cursor state after crashes, quits, and relaunches.
- Keep processing local. Do not add telemetry, trackers, cloud processing, or
  hidden network dependency to the cursor loop.

## Product Shape Today

This repository is a shallow monorepo for Cursor Designer.

1. The macOS package in `apps/macos` is the product.
   It contains the menu bar app, preferences UI, core cursor engine, background
   color detection, settings persistence, helper communication, and tests.
2. The root currently provides monorepo identity, boundary checks, and product
   documentation.
3. There is no canonical Cursor Designer website in this repository yet.

The package still uses `PointerDesigner` and `PointerDesignerHelper` executable
and module names for compatibility. The user-facing product name is Cursor
Designer.

## What Good Looks Like

- A user launches Cursor Designer from the menu bar.
- They can enable or disable cursor customization quickly.
- Preferences expose color, contrast mode, outline width, sampling rate,
  pointer scope, and launch-at-login without implying unsupported automation.
- The cursor engine samples local background color only when needed and applies
  bounded, testable rendering behavior.
- If screen recording permission, helper installation, display state, or stored
  settings are unavailable or invalid, the app fails safely and explains itself
  through UI state or diagnostics instead of doing surprising work.

## Pointer Capability Contract

The pointer is the product. Every feature must make the macOS pointer more
visible, personal, predictable, or recoverable.

Current supported contract:

- The user can choose persistent pointer settings: preset, color, scale, glow,
  shadow, contrast mode, outline color, outline width, brightness threshold,
  hysteresis, sampling rate, adaptive scaling, and launch-at-login.
- The Negative preset is an accessibility preset: black pointer, white outline,
  outline contrast mode, larger scale, no glow, and no shadow.
- Custom pointer rendering is local and reversible. The app may use AppKit
  cursor APIs for app-level behavior and preview surfaces.
- Dynamic contrast requires Screen Recording permission because it samples the
  local desktop background. The app must clearly degrade when permission is not
  present.
- System-wide pointer replacement is not supported in the current build. It
  must stay hidden or explicitly marked unavailable unless a public,
  distribution-safe, tested implementation enables it through the app
  capability model.

Unsupported claims:

- Do not claim persistent system-wide pointer replacement.
- Do not claim helper installation is required for ordinary pointer preference
  preview.
- Do not claim Accessibility, admin access, private APIs, SIP changes, browser
  automation, or cloud work is part of the normal pointer loop unless the exact
  path is implemented, permissioned, and verified.

## Direction Of Travel

Prefer work that increases trust in the core utility:

- clearer identity and packaging consistency
- safer helper and XPC behavior only when a real pointer capability requires it
- better crash recovery and orphan cleanup
- stronger display, color, and permission edge-case handling
- focused local verification for app, helper, settings, and packaging paths
- a future Cursor Designer website only after its domain, release source, and
  deployment owner are confirmed

Avoid work that makes the app broader, louder, or less local than it needs to
be.

## Production Readiness Bar

Cursor Designer is ready for broad distribution only when all of these are
true from live evidence:

1. The app launches as a menu bar utility on supported macOS versions without
   extra setup beyond documented permissions.
2. Pointer settings persist across quit, relaunch, crash recovery, and
   migration from legacy app-support paths.
3. The Negative preset and custom color path are visible in the app, saved in
   settings, and covered by tests.
4. Dynamic contrast behaves honestly with and without Screen Recording
   permission.
5. Unsupported helper and system-wide replacement paths are hidden, disabled,
   or explicitly unavailable in UI and docs.
6. Packaging scripts produce a validated app bundle and DMG from the repo-local
   macOS package.
7. Signing, notarization, Homebrew cask, release metadata, and install
   instructions are either verified or explicitly marked not ready.
8. The repo contains no wrong-product surfaces, stale WindowDrop language,
   telemetry, trackers, surprise network calls, or placeholder release claims.

The phrase "mass production ready" means every item above has direct proof. A
green test suite alone is not enough if packaging, signing, notarization,
installer, permissions, or product claims were not exercised.

## Mass-Production Blockers

These are intentional blockers, not polish notes:

- Persistent system-wide pointer replacement is not implemented or proven.
- Helper installation remains scaffolded and must not be sold as a user-facing
  capability until the supported pointer path exists.
- Release packaging, signing, notarization, Homebrew cask behavior, and DMG
  install flow require live verification before any public launch claim.
- A public website must not exist until the product has a real release source,
  domain, download path, and truthful compatibility story.

## Website Standard

The website is downstream of the app. It must sell and distribute the real
pointer product, not invent a broader product story.

When a Cursor Designer website is created:

- Use the operator's Leptos Cloudflare template only as the technical base,
  not as a source of generic SaaS language or filler sections.
- The first viewport must make the pointer accessibility promise obvious:
  custom colors, Negative preset, local processing, and macOS compatibility.
- Download and release data must come from verified GitHub release or package
  artifacts.
- Do not imply cloud processing, account signup, AI automation, production
  readiness, system-wide replacement, or deploy status that is not backed by
  live evidence.
- Avoid stock-layout filler: no decorative feature cards without substance, no
  vague "AI-powered" copy, no fake testimonials, no placeholder pricing, and no
  screenshots that outrun the app.

## Verification Gates

Use the smallest gate that proves the claim, and do not substitute one kind of
proof for another.

- App proof map: `apps/macos/REQUIREMENTS.md`
- Human-only release proof: `apps/macos/MANUAL_RELEASE_CHECKS.md`
- Product boundary: `./scripts/check-monorepo-references.sh`
- Local-first app surface: `./scripts/check-local-first.sh`
- App UI truth: `./scripts/check-app-ui-contract.sh`
- Core macOS behavior: `swift test --package-path apps/macos`
- Package preflight: from `apps/macos`, `make preflight`
- Launch smoke: from `apps/macos`, `make launch-smoke`
- Unsigned local DMG shape: from `apps/macos`, `make dmg` and
  `make dmg-install-check`
- Signing identity: from `apps/macos`, `make signing-identity-check`
- Signed local DMG: from `apps/macos`, `make signed-dmg`
- Signed and notarized local artifact: from `apps/macos`, `make release-candidate`
- Artifact distribution readiness without public metadata: from `apps/macos`,
  `make release-artifact-readiness`
- Public distribution readiness: from `apps/macos`, `make release-readiness`
  and `make release-metadata-check`
- Website: Leptos/Cloudflare template checks, browser-visible proof, and live
  download metadata verification after a real `apps/website` exists

Before declaring the objective complete, build a prompt-to-artifact checklist
that maps each product claim to a file, command, test, PR, release artifact, or
explicit blocker.

## Anti-Goals

- Becoming a general macOS automation tool.
- Importing another product's website, release flow, or deployment story.
- Making a helper mandatory for ordinary preference preview behavior.
- Adding telemetry, trackers, surprise network calls, or hidden background
  services outside the documented app/helper model.
- Rebranding compatibility identifiers without a migration plan and full
  identity verification.
