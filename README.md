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

```bash
cd apps/website/site
trunk build --release
cargo build --release --bin windowdrop-server --features ssr
```
