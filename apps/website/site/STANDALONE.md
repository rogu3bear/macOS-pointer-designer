# WindowDrop Standalone Setup

WindowDrop.pro site - a Rust/Leptos CSR (client-side rendered) application with an Axum static file server.

## Prerequisites

- **Rust** 1.75+ ([rustup.rs](https://rustup.rs))
- **trunk** (installed automatically by setup script)
- **wasm32-unknown-unknown** target (installed automatically)

## Quick Start

```bash
# Setup (installs trunk, wasm target)
./scripts/setup.sh

# Development with hot reload
./scripts/run.sh dev

# Production server
./scripts/run.sh
```

Development server: http://127.0.0.1:8080
Production server: http://127.0.0.1:3410

## Configuration

Copy `.env.example` to `.env` and configure:

| Variable | Default | Description |
|----------|---------|-------------|
| `PORT` | `3410` | Production server port |
| `RUST_LOG` | `info` | Log level |

## Architecture

This is a **CSR (Client-Side Rendered)** Leptos application:

1. **Development**: `trunk serve` builds WASM and serves with hot reload
2. **Production**: Trunk builds to `dist/`, Axum server serves static files

The Axum server (`src/bin/server.rs`) handles:
- Serving the `dist/` directory
- SPA fallback (all routes serve `index.html`)
- Health check at `/healthz`
- Cache control headers (1yr for hashed assets)

## Building for Production

```bash
# Build WASM assets and server binary
./scripts/build-release.sh

# Binary location
./target/release/windowdrop-server

# Run (serves dist/ directory)
PORT=3410 ./target/release/windowdrop-server
```

## Project Structure

```
apps/website/site/
├── src/
│   ├── main.rs          # CSR app entry (WASM)
│   ├── lib.rs           # Component library
│   └── bin/
│       └── server.rs    # Production Axum server
├── dist/                # Built assets (gitignored)
├── assets/              # Source assets
├── public/              # Static files
├── styles/              # CSS
├── index.html           # Trunk entry point
├── Trunk.toml           # Trunk configuration
├── scripts/
│   ├── setup.sh         # Initial setup
│   └── run.sh           # Development/production runner
├── .env.example         # Environment template
└── STANDALONE.md        # This file
```

## Health Check

```bash
# Production server only
curl http://localhost:3410/healthz
```

## Development Notes

- `trunk serve` provides hot reload for WASM
- Development runs on port 8080, production on 3410
- The `dist/` folder is created by `trunk build`
- Server uses SPA fallback for client-side routing
