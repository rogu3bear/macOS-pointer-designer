#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SITE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
PROJECT_ROOT="$(cd "$SITE_DIR/.." && pwd)"
cd "$SITE_DIR"

if [[ -f "$PROJECT_ROOT/ops/release-env.sh" ]]; then
    # shellcheck source=../../ops/release-env.sh
    source "$PROJECT_ROOT/ops/release-env.sh"
fi

load_dotenv() {
    local env_file="$1"
    [[ -f "$env_file" ]] || return 0

    while IFS= read -r line || [[ -n "$line" ]]; do
        [[ "$line" =~ ^[[:space:]]*# ]] && continue
        [[ "$line" =~ ^[[:space:]]*$ ]] && continue
        [[ "$line" =~ ^[A-Za-z_][A-Za-z0-9_]*= ]] || continue

        local key="${line%%=*}"
        local value="${line#*=}"
        export "$key=$value"
    done < "$env_file"
}

if [[ -f "$PROJECT_ROOT/.env" ]]; then
    load_dotenv "$PROJECT_ROOT/.env"
else
    load_dotenv .env
fi

port_free() {
    "$SCRIPT_DIR/port-free.sh" "$1"
}

MODE="${1:-prod}"

case "$MODE" in
    dev)
        port_free 3411
        echo "Starting WindowDrop in development mode (trunk serve)..."
        echo "  -> http://127.0.0.1:3411"
        echo ""
        # Avoid trunk --no-color parse error when env has NO_COLOR=1
        unset TRUNK_NO_COLOR NO_COLOR 2>/dev/null || true
        exec trunk serve
        ;;
    prod|*)
        PORT="${PORT:-3410}"
        port_free "$PORT"
        echo "Starting WindowDrop server on 0.0.0.0:${PORT}..."
        echo ""

        # Build WASM if dist doesn't exist or is stale
        if [ ! -d dist ] || [ ! -f dist/index.html ]; then
            echo "Building WASM assets first..."
            unset TRUNK_NO_COLOR NO_COLOR 2>/dev/null || true
            trunk build --release
        fi

        # Run the server
        cargo run --release --features ssr --bin windowdrop-server
        ;;
esac
