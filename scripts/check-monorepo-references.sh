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

grep_args=(
  -n
  -F
)

for pattern in "${forbidden_patterns[@]}"; do
  if command -v rg >/dev/null 2>&1; then
    matches=$(rg "${rg_args[@]}" "$pattern" . || true)
  else
    matches=$(
      while IFS= read -r -d '' file; do
        if [[ "$file" == "scripts/check-monorepo-references.sh" ]]; then
          continue
        fi

        skip=false
        for allowed_file in "${allowed_doctrine_files[@]}"; do
          if [[ "$file" == "$allowed_file" ]]; then
            skip=true
            break
          fi
        done
        if [[ "$skip" == true ]]; then
          continue
        fi

        grep "${grep_args[@]}" -- "$pattern" "$file" 2>/dev/null | sed "s|^|$file:|" || true
      done < <(git ls-files -co --exclude-standard -z)
    )
  fi

  if [[ -n "$matches" ]]; then
    printf '%s\n' "$matches"
    echo "Found non-Cursor Designer product reference: $pattern" >&2
    exit 1
  fi
done

echo "Cursor Designer product-boundary check passed."
