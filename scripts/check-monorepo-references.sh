#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

if ! command -v rg >/dev/null 2>&1; then
  echo "ripgrep (rg) is required for product-boundary checks." >&2
  exit 127
fi

forbidden_patterns=(
  "/Users/star/dev/drop-web"
  "rogu3bear/drop-web"
  "WindowDrop"
  "windowdrop"
)

allowed_doctrine_files=(
  "NORTH_STAR.md"
  "ANCHOR.md"
  "AGENTS.md"
  "CLAUDE.md"
)

rg_args=(
  --fixed-strings
  --line-number
  --glob '!.git/**'
  --glob '!scripts/check-monorepo-references.sh'
)

for file in "${allowed_doctrine_files[@]}"; do
  rg_args+=(--glob "!$file")
done

for pattern in "${forbidden_patterns[@]}"; do
  if rg "${rg_args[@]}" "$pattern" .; then
    echo "Found non-Cursor Designer product reference: $pattern" >&2
    exit 1
  fi
done

echo "Cursor Designer product-boundary check passed."
