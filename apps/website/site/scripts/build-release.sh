#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SITE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$SITE_DIR"

# Trunk on this machine fails when NO_COLOR is exported as 1.
unset TRUNK_NO_COLOR NO_COLOR 2>/dev/null || true

trunk build --release
cargo build --release --bin windowdrop-server --features ssr
