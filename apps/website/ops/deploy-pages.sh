#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
WEBSITE_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SITE_DIR="$WEBSITE_DIR/site"
REPO_ROOT="$(cd "$WEBSITE_DIR/../.." && pwd)"
CFCTL="${CFCTL:-/Users/star/dev/cloudflare/cfctl}"
JQ="${JQ:-/opt/homebrew/bin/jq}"

# shellcheck source=release-env.sh
source "$SCRIPT_DIR/release-env.sh"

cd "$REPO_ROOT"

if [[ ! -x "$CFCTL" ]]; then
    echo "Cloudflare control plane not found or not executable: $CFCTL" >&2
    exit 1
fi

if [[ ! -x "$JQ" ]]; then
    echo "jq not found or not executable: $JQ" >&2
    exit 1
fi

commit_hash="$(git rev-parse HEAD)"
commit_message="$(git log -1 --pretty=%s)"
dirty="false"
if [[ -n "$(git status --short)" ]]; then
    dirty="true"
fi

"$SITE_DIR/scripts/build-release.sh"

plan_json="$("$CFCTL" wrangler pages deploy "$SITE_DIR/dist" \
    --project-name windowdrop \
    --branch main \
    --commit-hash "$commit_hash" \
    --commit-message "$commit_message" \
    --commit-dirty="$dirty" \
    --plan)"
operation_id="$(printf '%s\n' "$plan_json" | "$JQ" -r '.operation_id')"

if [[ -z "$operation_id" || "$operation_id" == "null" ]]; then
    echo "$plan_json" >&2
    echo "Could not read cfctl operation_id from deploy preview." >&2
    exit 1
fi

printf '%s\n' "$plan_json"

"$CFCTL" wrangler pages deploy "$SITE_DIR/dist" \
    --project-name windowdrop \
    --branch main \
    --commit-hash "$commit_hash" \
    --commit-message "$commit_message" \
    --commit-dirty="$dirty" \
    --ack-plan "$operation_id"
