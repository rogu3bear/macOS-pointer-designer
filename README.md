# Cursor Designer Monorepo

This repository contains the Cursor Designer product surfaces as a shallow monorepo.

## Layout

```text
apps/
  macos/    Swift package for the macOS app and helper
```

## macOS App

The macOS app lives in `apps/macos`.

```bash
cd apps/macos
swift test
swift build
```

## Website

There is no canonical Cursor Designer website in this repository yet.

Do not import or operate another product's website as the Cursor Designer
website. A future Cursor Designer website should start as a Cursor
Designer-specific surface under `apps/website` only when its domain, release
source, and deployment owner are confirmed.

## Verification

Run the product checks from the monorepo root:

```bash
./scripts/check-monorepo-references.sh
swift test --package-path apps/macos
```
