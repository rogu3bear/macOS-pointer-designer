#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

if find Casks apps/macos/Casks homebrew Formula \
  -type f \( -name '*.rb' -o -iname '*cask*' -o -iname '*brew*' \) \
  -print -quit 2>/dev/null | grep -q .; then
  echo "ERROR: Homebrew or cask files exist before a verified stable release artifact." >&2
  echo "Homebrew distribution is blocked until release URL, checksum, notarization, and install behavior are verified." >&2
  exit 1
fi

scan_paths=(
  "."
)

rg_args=(
  --line-number
  --fixed-strings
  --glob '*.md'
  --glob '!.git/**'
  --glob '!apps/macos/.build/**'
)

forbidden_patterns=(
  "brew tap rogu3bear/cursor-designer-osx"
  "brew install --cask cursor-designer-osx"
  "Homebrew (Recommended)"
  "cursor-designer-osx/releases/latest"
)

for pattern in "${forbidden_patterns[@]}"; do
  if command -v rg >/dev/null 2>&1; then
    matches=$(rg "${rg_args[@]}" "$pattern" "${scan_paths[@]}" || true)
  else
    matches=$(find "${scan_paths[@]}" \
      -path './.git' -prune -o \
      -path './apps/macos/.build' -prune -o \
      -type f -name '*.md' -print0 \
      | xargs -0 grep -n -F -- "$pattern" 2>/dev/null || true)
  fi

  if [[ -n "$matches" ]]; then
    printf '%s\n' "$matches"
    echo "ERROR: unverified public distribution instruction found: $pattern" >&2
    echo "Stable download and Homebrew claims require a notarized artifact, matching release digest, and manual release evidence." >&2
    exit 1
  fi
done

echo "Cursor Designer distribution-boundary check passed."
