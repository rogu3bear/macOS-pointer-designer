#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

forbidden_patterns=(
  "/Users/star/dev/drop-web"
  "rogu3bear/drop-web"
  "WindowDrop"
  "windowdrop"
)

for pattern in "${forbidden_patterns[@]}"; do
  if rg --fixed-strings --line-number \
    --glob '!.git/**' \
    --glob '!scripts/check-monorepo-references.sh' \
    "$pattern" .; then
    echo "Found non-Cursor Designer product reference: $pattern" >&2
    exit 1
  fi
done

echo "Cursor Designer product-boundary check passed."
