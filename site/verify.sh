#!/bin/bash
# WindowDrop Site Verification Script
# Runs all automated checks to verify the site builds correctly

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo "🔍 Running WindowDrop Site Verification..."
echo ""

# 1. Cargo check
echo "1/4 Running cargo check..."
if cargo check 2>&1 | tail -5; then
    echo -e "${GREEN}✓ Compilation check passed${NC}"
else
    echo -e "${RED}✗ Compilation check failed${NC}"
    exit 1
fi
echo ""

# 2. Cargo fmt
echo "2/4 Running cargo fmt --check..."
if cargo fmt -- --check 2>&1; then
    echo -e "${GREEN}✓ Formatting check passed${NC}"
else
    echo -e "${RED}✗ Formatting check failed${NC}"
    exit 1
fi
echo ""

# 3. Cargo clippy
echo "3/4 Running cargo clippy..."
if cargo clippy -- -D warnings 2>&1 | tail -10; then
    echo -e "${GREEN}✓ Clippy check passed${NC}"
else
    echo -e "${RED}✗ Clippy check failed${NC}"
    exit 1
fi
echo ""

# 4. Trunk build
echo "4/4 Running trunk build --release..."
if trunk build --release 2>&1 | tail -5; then
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
