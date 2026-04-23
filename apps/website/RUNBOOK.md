# WindowDrop Website Runbook

> **Domain:** windowdrop.pro | **Port:** 3410 local preview | **Stack:** Rust/Leptos 0.6 CSR

Canonical checkout: `/Users/star/dev/macOS-pointer-designer/apps/website`
Production host: Cloudflare Pages project `windowdrop`
Current public release: WindowDrop `1.0.1` from `rogu3bear/windowdrop`

## Quick Commands

```bash
# Start/restart service
launchctl kickstart -k gui/$(id -u)/com.windowdrop.server

# Check status
curl -s http://localhost:3410/healthz

# View logs
tail -f ~/.logs/windowdrop-web/*.log
```

## Service Details

| Property | Value |
|----------|-------|
| LaunchAgent | `com.windowdrop.server` |
| Binary | `site/target/release/windowdrop-server` |
| Health endpoint | `/healthz` |
| Pages project | `windowdrop` |
| Release metadata | `ops/release-env.sh` |

## Build & Deploy

```bash
cd /Users/star/dev/macOS-pointer-designer/apps/website

# Build WASM + server using the current release metadata
cd site && ./scripts/build-release.sh

# Deploy the public Pages site through the shared Cloudflare control plane
cd .. && ./ops/deploy-pages.sh

# Optional local preview restart
launchctl kickstart -k gui/$(id -u)/com.windowdrop.server

# Verify
curl http://localhost:3410/healthz
```

## Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `PORT` | No | Server port (default: 3410) |
| `RUST_LOG` | No | Log level (default: `info`) |
| `STRIPE_API_KEY` | Yes | Stripe secret key for checkout |
| `WINDOWDROP_WEB_LICENSE_PRIVATE_KEY_PATH` | Yes | Path to P-256 PKCS#8 PEM for token signing |
| `WINDOWDROP_SITE_URL` | No | Override base URL (default: `https://windowdrop.pro`) |
| `SITE_LIFETIME_MODE` | No | `web` (Stripe checkout) or `in-app` (download/app purchase flow) — default: `in-app` |
| `RESEND_API_KEY` | No | Resend API key for license email delivery |
| `RESEND_FROM_EMAIL` | No | Sender address (default: `WindowDrop <licenses@windowdrop.pro>`) |
| `WINDOWDROP_DMG_URL` | No | Override the current GitHub release DMG URL from `ops/release-env.sh` |
| `WINDOWDROP_ZIP_URL` | No | Override the current GitHub release ZIP URL from `ops/release-env.sh` |
| `WINDOWDROP_CHECKSUMS_URL` | No | Override the current GitHub release checksums URL from `ops/release-env.sh` |

## Common Issues

### Service not starting

1. Check binary exists: `ls site/target/release/windowdrop-server`
2. If missing, rebuild: `cd site && ./scripts/build-release.sh`
3. Check logs: `tail -50 ~/.logs/windowdrop-web/*.log`

### Public site mismatch

1. Confirm `ops/release-env.sh` points at the latest verified release.
2. Rebuild and deploy with `./ops/deploy-pages.sh`.
3. Verify `https://windowdrop.pro/download` and `https://windowdrop.pro/changelog`.

### Web checkout mismatch

1. Keep public Pages in `SITE_LIFETIME_MODE=in-app` unless the web checkout proxy is verified live.
2. For web mode, verify the Axum origin is healthy and `/checkout/lifetime` redirects to Stripe.
3. If the public site is static-only, do not advertise website checkout recovery as live.

## Development

```bash
cd site
trunk serve  # Dev server at localhost:8080
```

## Notes

- CSR only (no SSR hydration) - uses Trunk, not cargo-leptos
- Actual app in `site/` subfolder
- WASM must be rebuilt with current release metadata before deploy/restart
