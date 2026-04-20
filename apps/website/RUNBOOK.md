# drop-web Runbook

> **Domain:** windowdrop.pro | **Port:** 3410 | **Stack:** Rust/Leptos 0.6 CSR

## Quick Commands

```bash
# Start/restart service
launchctl kickstart -k gui/$(id -u)/com.windowdrop.server

# Check status
curl -s http://localhost:3410/healthz

# View logs
tail -f ~/.logs/drop-web/*.log
```

## Service Details

| Property | Value |
|----------|-------|
| LaunchAgent | `com.windowdrop.server` |
| Binary | `~/Dev/drop-web/site/target/release/windowdrop-server` |
| Health endpoint | `/healthz` |
| Tunnel | `fe7d370f-93aa-4f87-9cf3-1ef0c7b2bf94` |

## Build & Deploy

```bash
cd site

# Build WASM + server
trunk build --release
cargo build --release --bin windowdrop-server --features ssr

# Restart
launchctl kickstart -k gui/$(id -u)/com.windowdrop.server

# Verify
curl http://localhost:3410/healthz
```

## Common Issues

### Service not starting

1. Check binary exists: `ls site/target/release/windowdrop-server`
2. If missing, rebuild: `cd site && trunk build --release && cargo build --release --bin windowdrop-server --features ssr`
3. Check logs: `tail -50 ~/.logs/drop-web/*.log`

### 502 from Cloudflare

1. Verify service running: `lsof -i :3410`
2. Check tunnel: `cloudflared tunnel info dev-unified`
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
