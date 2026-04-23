#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

forbidden_patterns=(
  "/Users/star/dev/drop-web"
  "rogu3bear/drop-web"
)

for pattern in "${forbidden_patterns[@]}"; do
  if rg --fixed-strings --line-number \
    --glob '!.git/**' \
    --glob '!scripts/check-monorepo-references.sh' \
    --glob '!apps/website/site/target/**' \
    --glob '!apps/website/site/dist/**' \
    "$pattern" .; then
    echo "Found retired standalone website reference: $pattern" >&2
    exit 1
  fi
done

echo "Monorepo reference check passed."
