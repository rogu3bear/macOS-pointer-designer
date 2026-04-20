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
