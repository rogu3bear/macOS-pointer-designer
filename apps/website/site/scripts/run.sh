#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

# Load environment
if [ -f .env ]; then
    set -a
    source .env
    set +a
fi

MODE="${1:-prod}"

case "$MODE" in
    dev)
        echo "Starting WindowDrop in development mode (trunk serve)..."
        echo "  -> http://127.0.0.1:8080"
        echo ""
        trunk serve
        ;;
    prod|*)
        echo "Starting WindowDrop server on 0.0.0.0:${PORT:-3410}..."
        echo ""

        # Build WASM if dist doesn't exist or is stale
        if [ ! -d dist ] || [ ! -f dist/index.html ]; then
            echo "Building WASM assets first..."
            trunk build --release
        fi

        # Run the server
        cargo run --release --features ssr --bin windowdrop-server
        ;;
esac
