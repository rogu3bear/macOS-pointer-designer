#!/bin/bash
set -euo pipefail

NOTARY_PROFILE="notarization"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --notary-profile)
            NOTARY_PROFILE="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [--notary-profile NAME]"
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 2
            ;;
    esac
done

echo "=== Cursor Designer Notary Profile Check ==="
echo "Notary profile: $NOTARY_PROFILE"
echo ""

if xcrun notarytool history --keychain-profile "$NOTARY_PROFILE" >/dev/null; then
    echo "Notary profile is available."
    exit 0
fi

echo ""
echo "ERROR: notarytool profile '$NOTARY_PROFILE' is not available." >&2
echo "" >&2
echo "Create it interactively, then rerun the release-candidate gate:" >&2
echo "" >&2
echo "  xcrun notarytool store-credentials \"$NOTARY_PROFILE\" \\" >&2
echo "    --apple-id <apple-id> \\" >&2
echo "    --team-id <team-id>" >&2
echo "" >&2
echo "Do not commit Apple IDs, app-specific passwords, API keys, or keychain exports." >&2
exit 69
