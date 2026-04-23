# WindowDrop Website Runbook

> **Domain:** windowdrop.pro | **Port:** 3410 | **Stack:** Rust/Leptos 0.6 CSR

Canonical checkout: `/Users/star/dev/macOS-pointer-designer/apps/website`

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
| Tunnel | `fe7d370f-93aa-4f87-9cf3-1ef0c7b2bf94` |

## Build & Deploy

```bash
cd site

# Build WASM + server
./scripts/build-release.sh

# Restart
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
| `SITE_LIFETIME_MODE` | No | `web` (Stripe checkout) or `in-app` (App Store) — default: `web` |
| `RESEND_API_KEY` | No | Resend API key for license email delivery |
| `RESEND_FROM_EMAIL` | No | Sender address (default: `WindowDrop <licenses@windowdrop.pro>`) |
| `WINDOWDROP_DMG_URL` | No | Override the default versioned DMG download URL |

## Common Issues

### Service not starting

1. Check binary exists: `ls site/target/release/windowdrop-server`
2. If missing, rebuild: `cd site && ./scripts/build-release.sh`
3. Check logs: `tail -50 ~/.logs/windowdrop-web/*.log`

### 502 from Cloudflare

1. Verify service running: `lsof -i :3410`
2. Verify the Pages deployment and custom-domain state in Cloudflare
3. Test locally: `curl http://localhost:3410/healthz`

## Development

```bash
cd site
trunk serve  # Dev server at localhost:8080
```

## Notes

- CSR only (no SSR hydration) - uses Trunk, not cargo-leptos
- Actual app in `site/` subfolder
- WASM must be rebuilt with `trunk build` before server restart
