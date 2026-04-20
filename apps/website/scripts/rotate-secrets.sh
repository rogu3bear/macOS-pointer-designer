#!/usr/bin/env bash
set -euo pipefail
#
# AGENTS: operator credentials live in two files:
#   ~/dev/.env  — shared CF identity + CF_DEV_TOKEN
#   repo-local .env under apps/website/ — DROP_-prefixed secrets (gitignored)
#
# CF_DEV_TOKEN (in ~/dev/.env) has full account scope. See ~/dev/.env
# for the permission-group lookup and token-minting API.
#
# Usage: ./scripts/rotate-secrets.sh [--dry-run]

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$REPO_ROOT"
DRY_RUN=false
[[ "${1:-}" == "--dry-run" ]] && DRY_RUN=true

set -a
source "$HOME/dev/.env"
source "$REPO_ROOT/.env"
set +a

[[ -n "${CF_DEV_TOKEN:-}" ]] || { echo "Error: CF_DEV_TOKEN not set." >&2; exit 1; }
[[ -n "${CLOUDFLARE_ACCOUNT_ID:-}" ]] || { echo "Error: CLOUDFLARE_ACCOUNT_ID not set." >&2; exit 1; }

GH_REPO="rogu3bear/macOS-pointer-designer"

put_gh() {
  local name="$1" value="$2"
  if [[ "$DRY_RUN" == "true" ]]; then
    echo "  [dry-run] $name (len=${#value})"
    return
  fi
  gh secret set "$name" --repo "$GH_REPO" --body "$value" 2>/dev/null
  echo "  $name"
}

echo "DROP secret rotation (gh=$GH_REPO)"
[[ "$DRY_RUN" == "true" ]] && echo "  mode: dry-run"
echo ""

put_gh CLOUDFLARE_ACCOUNT_ID "$CLOUDFLARE_ACCOUNT_ID"
put_gh CLOUDFLARE_API_TOKEN "$CF_DEV_TOKEN"

echo ""
echo "Done. GH '$GH_REPO' secrets are in sync."
