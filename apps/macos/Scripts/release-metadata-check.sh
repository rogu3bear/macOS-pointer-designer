#!/bin/bash
set -euo pipefail

REPO="rogu3bear/macOS-pointer-designer"
EXPECTED_DMG="CursorDesigner.dmg"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --repo)
            REPO="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [--repo OWNER/REPO]"
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 2
            ;;
    esac
done

echo "=== Cursor Designer Release Metadata Check ==="
echo "Repository: $REPO"
echo ""

if ! command -v gh >/dev/null 2>&1; then
    echo "ERROR: GitHub CLI (gh) is required to verify release metadata" >&2
    exit 2
fi

echo ">>> Reading latest release metadata"
LATEST_RELEASES=$(gh release list \
    --repo "$REPO" \
    --limit 10 \
    --json tagName,isDraft,isPrerelease,publishedAt,name)

echo "$LATEST_RELEASES"

STABLE_TAG=$(gh release list \
    --repo "$REPO" \
    --exclude-drafts \
    --exclude-pre-releases \
    --limit 1 \
    --json tagName \
    --jq '.[0].tagName // ""')

if [[ -z "$STABLE_TAG" ]]; then
    echo ""
    echo "ERROR: No stable public release found." >&2
    echo "Release metadata is not ready for stable download claims." >&2
    exit 4
fi

echo ""
echo ">>> Inspecting stable release: $STABLE_TAG"
ASSET_NAMES=$(gh release view "$STABLE_TAG" \
    --repo "$REPO" \
    --json tagName,isDraft,isPrerelease,assets,url \
    --jq '.assets[].name')

if ! grep -Fxq "$EXPECTED_DMG" <<<"$ASSET_NAMES"; then
    echo "ERROR: Stable release $STABLE_TAG does not include $EXPECTED_DMG" >&2
    echo "Assets:" >&2
    echo "$ASSET_NAMES" >&2
    exit 3
fi

DMG_DIGEST=$(gh release view "$STABLE_TAG" \
    --repo "$REPO" \
    --json assets \
    --jq ".assets[] | select(.name == \"$EXPECTED_DMG\") | .digest // \"\"")

if [[ ! "$DMG_DIGEST" =~ ^sha256:[0-9a-fA-F]{64}$ ]]; then
    echo "ERROR: Stable release $STABLE_TAG does not expose a SHA-256 digest for $EXPECTED_DMG" >&2
    echo "Digest: ${DMG_DIGEST:-<missing>}" >&2
    exit 5
fi

echo "Stable release includes $EXPECTED_DMG."
echo "Stable release DMG digest: $DMG_DIGEST"
