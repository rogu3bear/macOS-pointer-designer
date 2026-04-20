# Cursor Designer Monorepo

This repository contains the Cursor Designer product surfaces as a shallow monorepo.

## Layout

```text
apps/
  macos/    Swift package for the macOS app and helper
  website/  Product website and deployment surfaces
```

## macOS App

The macOS app lives in `apps/macos`.

```bash
cd apps/macos
swift test
swift build
```

## Website

The product website lives in `apps/website`.
This monorepo is now the canonical home for website changes; the former standalone
`drop-web` repo is retired.

```bash
cd apps/website/site
./scripts/build-release.sh
```
