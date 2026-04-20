#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

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

# Create .env from example if missing
if [ ! -f .env ] && [ -f .env.example ]; then
    cp .env.example .env
    echo "Created .env from .env.example"
elif [ -f .env ]; then
    echo ".env already exists"
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
