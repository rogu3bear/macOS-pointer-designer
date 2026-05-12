#!/bin/bash
set -euo pipefail

NOTARY_PROFILE="notarization"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --notary-profile)
            if [[ $# -lt 2 || "$2" == --* ]]; then
                echo "ERROR: --notary-profile requires a name" >&2
                exit 2
            fi
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
echo "Omit --password so notarytool prompts instead of writing secrets to shell history." >&2
echo "For an App Store Connect API key lane, use --key and --key-id from a private operator path; add --issuer for team API keys." >&2
echo "Repo wrapper: make setup-notary-profile NOTARY_PROFILE=\"$NOTARY_PROFILE\" with private NOTARY_* environment variables." >&2
echo "Do not commit Apple IDs, app-specific passwords, API keys, or keychain exports." >&2
exit 69
