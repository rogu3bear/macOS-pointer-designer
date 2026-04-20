# WindowDrop Website

Official website for **WindowDrop** - a macOS utility that moves new windows to your cursor position instantly.

This site lives in `apps/website` inside the Cursor Designer monorepo.
The former standalone `drop-web` repo is retired; all website changes should land here.

## At a Glance
- Domain(s): windowdrop.pro, www.windowdrop.pro
- Local port: 3410
- Health: `/healthz`
- Logs: `~/.logs/windowdrop-web/`
- Dev: `cd site && trunk serve`
- Build: `cd site && ./scripts/build-release.sh`

## 🌐 Live Site

**Production**: https://windowdrop.pro

## 🎨 Tech Stack

- **Framework**: [Leptos](https://github.com/leptos-rs/leptos) 0.6 (CSR)
- **Build**: [Trunk](https://trunkrs.dev/) + WebAssembly
- **Server**: Axum (static files, port 3410)
- **Proxy**: Caddy (local reverse proxy)
- **Tunnel**: Cloudflare Tunnel (remote config)
- **Service**: macOS launchd

## 🏗️ Project Structure

```
apps/website/
├── site/
│   ├── src/
│   │   ├── components/   # UI components
│   │   ├── pages/        # Page components
│   │   ├── content/      # FAQ, changelog markdown
│   │   ├── seo/          # Meta components
│   │   ├── main.rs       # WASM entry
│   │   └── bin/server.rs # Axum server
│   ├── styles/           # CSS (base, layout, components)
│   ├── assets/           # Images
│   ├── public/           # robots.txt, sitemap
│   └── Cargo.toml
├── docs/
├── ops/
├── scripts/
└── README.md
```

## 🚀 Development

```bash
cd site
trunk serve          # Dev server at localhost:8080
```

## 📦 Production Build

```bash
cd site
trunk build --release
cargo build --release --bin windowdrop-server --features ssr
```

## 🔧 Deployment

```bash
# Rebuild and restart
cd site && ./scripts/build-release.sh
launchctl kickstart -k gui/$(id -u)/com.windowdrop.server

# Canonical local service entrypoint from apps/website/
./site/scripts/run.sh prod

# Verify
curl http://127.0.0.1:3410/healthz
```

## 🐳 Docker

`docker-compose.yml` loads runtime configuration from `.env` via `env_file`.

```bash
cp .env.example .env
# edit .env

docker compose up --build
curl http://127.0.0.1:3410/healthz
```

## 📝 Configuration

- **Service**: `com.windowdrop.server` (launchd)
- **Port**: 3410

## 🎯 CTA Configuration

The site supports multiple CTA modes configured in `src/config.rs`:

| Mode | Label | Behavior |
|------|-------|----------|
| `TrialDownload` | "Download WindowDrop" | Links to `trial_url` |
| `EarlyAccess` | "Get Early Access" | Links to `trial_url` |
| `NotifyMe` | "Get Notified" | Email capture form (default) |
| `AppStoreLink` | "Download on App Store" | Links to `store_url` |

### Changing CTA Mode

Edit `src/config.rs`:

```rust
pub const CONFIG: SiteConfig = SiteConfig {
    cta_mode: CtaMode::NotifyMe,  // Change this
    trial_url: Some("https://..."),
    // ...
};
```

### Pre-launch (Current)

The site defaults to `NotifyMe` mode with email capture enabled. This captures user intent without committing to pricing.

### Post-launch

When ready to monetize:
1. Update `cta_mode` to `TrialDownload` or `AppStoreLink`
2. Set the appropriate URL
3. Rebuild and deploy

## 📄 License

Proprietary - All rights reserved
