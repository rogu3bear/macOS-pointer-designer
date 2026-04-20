#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SITE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_ROOT="$(cd "$SITE_DIR/.." && pwd)"
cd "$SITE_DIR"

echo "=== WindowDrop Setup ==="

# Check for Rust
if ! command -v cargo &> /dev/null; then
    echo "Error: Rust not found. Install from https://rustup.rs"
    exit 1
fi

echo "Rust: $(rustc --version)"

# Check for trunk (for WASM development)
if ! command -v trunk &> /dev/null; then
    echo "Installing trunk..."
    cargo install trunk
else
    echo "trunk: $(trunk --version)"
fi

# Check for wasm32 target
if ! rustup target list --installed | grep -q wasm32-unknown-unknown; then
    echo "Adding wasm32-unknown-unknown target..."
    rustup target add wasm32-unknown-unknown
else
    echo "wasm32-unknown-unknown target: installed"
fi

# Create the canonical monorepo .env if missing, with site/.env as fallback.
if [ ! -f "$PROJECT_ROOT/.env" ] && [ -f "$PROJECT_ROOT/.env.example" ]; then
    cp "$PROJECT_ROOT/.env.example" "$PROJECT_ROOT/.env"
    echo "Created $PROJECT_ROOT/.env from $PROJECT_ROOT/.env.example"
elif [ -f "$PROJECT_ROOT/.env" ]; then
    echo "$PROJECT_ROOT/.env already exists"
elif [ ! -f .env ] && [ -f .env.example ]; then
    cp .env.example .env
    echo "Created site/.env from site/.env.example"
elif [ -f .env ]; then
    echo "site/.env already exists"
fi

# Verify build works (quick check)
echo ""
echo "Verifying cargo check..."
cargo check 2>&1 | tail -3

echo ""
echo "Setup complete!"
echo ""
echo "Development: ./scripts/run.sh dev     (trunk serve with hot reload)"
echo "Production:  ./scripts/run.sh         (axum server on port 3410)"
