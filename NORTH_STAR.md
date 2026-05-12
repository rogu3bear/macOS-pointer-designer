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
- Keep the app useful without the helper, and make the helper an explicit
  system-wide upgrade path rather than a surprise requirement.
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
- Preferences expose color, contrast mode, outline width, sampling rate, helper
  status, and launch-at-login without implying unsafe automation.
- The cursor engine samples local background color only when needed and applies
  bounded, testable rendering behavior.
- If screen recording permission, helper installation, display state, or stored
  settings are unavailable or invalid, the app fails safely and explains itself
  through UI state or diagnostics instead of doing surprising work.

## Direction Of Travel

Prefer work that increases trust in the core utility:

- clearer identity and packaging consistency
- safer helper install and XPC behavior
- better crash recovery and orphan cleanup
- stronger display, color, and permission edge-case handling
- focused local verification for app, helper, settings, and packaging paths
- a future Cursor Designer website only after its domain, release source, and
  deployment owner are confirmed

Avoid work that makes the app broader, louder, or less local than it needs to
be.

## Anti-Goals

- Becoming a general macOS automation tool.
- Importing another product's website, release flow, or deployment story.
- Making the helper mandatory for ordinary preference preview behavior.
- Adding telemetry, trackers, surprise network calls, or hidden background
  services outside the documented app/helper model.
- Rebranding compatibility identifiers without a migration plan and full
  identity verification.
