#!/bin/bash
# WindowDrop Site Verification Script
# Runs all automated checks to verify the site builds correctly.
# Run from drop-web root: ./ops/verify.sh

set -euo pipefail

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

ROOT_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
SITE_DIR="$(cd "$(dirname "$0")/../site" && pwd)"
if [[ -x "$ROOT_DIR/ops/release-version.sh" ]]; then
    export WINDOWDROP_RELEASE_VERSION="${WINDOWDROP_RELEASE_VERSION:-$("$ROOT_DIR/ops/release-version.sh")}"
fi
cd "$SITE_DIR"

ensure_rust_toolchain() {
    if cargo --version >/dev/null 2>&1; then
        return 0
    fi

    local fallback_toolchain
    fallback_toolchain="${RUSTUP_TOOLCHAIN:-$(rustup default 2>/dev/null | awk '{print $1}')}"

    if [[ -n "$fallback_toolchain" ]] && cargo +"$fallback_toolchain" --version >/dev/null 2>&1; then
        export RUSTUP_TOOLCHAIN="$fallback_toolchain"
        echo "Using fallback Rust toolchain: $RUSTUP_TOOLCHAIN"
        return 0
    fi

    return 1
}

if ! ensure_rust_toolchain; then
    echo -e "${RED}✗ Rust toolchain is unavailable for cargo commands${NC}"
    echo "Set RUSTUP_TOOLCHAIN to an installed concrete toolchain and retry."
    exit 1
fi

echo "🔍 Running WindowDrop Site Verification..."
echo ""

# 1. Client cargo check
echo "1/6 Running cargo check..."
if cargo check 2>&1 | tail -10; then
    echo -e "${GREEN}✓ Client compilation check passed${NC}"
else
    echo -e "${RED}✗ Client compilation check failed${NC}"
    exit 1
fi
echo ""

# 2. Server cargo check
echo "2/6 Running cargo check --features ssr --bin windowdrop-server..."
if cargo check --features ssr --bin windowdrop-server 2>&1 | tail -10; then
    echo -e "${GREEN}✓ Server compilation check passed${NC}"
else
    echo -e "${RED}✗ Server compilation check failed${NC}"
    exit 1
fi
echo ""

# 3. Cargo fmt
echo "3/6 Running cargo fmt --check..."
if cargo fmt -- --check 2>&1; then
    echo -e "${GREEN}✓ Formatting check passed${NC}"
else
    echo -e "${RED}✗ Formatting check failed${NC}"
    exit 1
fi
echo ""

# 4. Client cargo clippy
echo "4/6 Running cargo clippy..."
if cargo clippy -- -D warnings 2>&1 | tail -10; then
    echo -e "${GREEN}✓ Client clippy check passed${NC}"
else
    echo -e "${RED}✗ Client clippy check failed${NC}"
    exit 1
fi
echo ""

# 5. Server cargo clippy + tests
echo "5/6 Running cargo clippy --features ssr --bin windowdrop-server..."
if cargo clippy --features ssr --bin windowdrop-server -- -D warnings 2>&1 | tail -10; then
    echo -e "${GREEN}✓ Server clippy check passed${NC}"
else
    echo -e "${RED}✗ Server clippy check failed${NC}"
    exit 1
fi
echo ""

echo "   Running cargo test --features ssr..."
if cargo test --features ssr 2>&1 | tail -10; then
    echo -e "${GREEN}✓ Tests passed${NC}"
else
    echo -e "${RED}✗ Tests failed${NC}"
    exit 1
fi
echo ""

# 6. Trunk build
echo "6/6 Running trunk build --release..."
unset TRUNK_NO_COLOR NO_COLOR 2>/dev/null || true
if trunk build --release; then
    echo -e "${GREEN}✓ Production build succeeded${NC}"
else
    echo -e "${RED}✗ Production build failed${NC}"
    exit 1
fi
echo ""

# Summary
echo "========================================"
echo -e "${GREEN}✓ All verification checks passed!${NC}"
echo "========================================"
echo ""
echo "Production build output:"
ls -lh dist/*.wasm dist/*.js 2>/dev/null || echo "  (check dist/ folder)"
echo ""
echo "Ready for deployment! 🚀"
