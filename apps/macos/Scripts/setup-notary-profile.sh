#!/bin/bash
set -euo pipefail

NOTARY_PROFILE="notarization"
APPLE_ID="${NOTARY_APPLE_ID:-}"
TEAM_ID="${NOTARY_TEAM_ID:-4JB58L7BTZ}"
FORCE=0

usage() {
    cat <<'USAGE'
Usage:
  setup-notary-profile.sh [--notary-profile NAME] [--apple-id APPLE_ID] [--team-id TEAM_ID] [--force]

Creates and verifies a notarytool Keychain profile without committing secrets.

API key lane:
  NOTARY_KEY_PATH=/private/path/AuthKey_XXXXXXXXXX.p8
  NOTARY_KEY_ID=XXXXXXXXXX
  NOTARY_ISSUER_ID=00000000-0000-0000-0000-000000000000

NOTARY_ISSUER_ID is optional for individual API keys and required for team API
keys.

Apple ID lane:
  NOTARY_APPLE_ID=person@example.com
  NOTARY_TEAM_ID=4JB58L7BTZ
  NOTARY_APP_SPECIFIC_PASSWORD=xxxx-xxxx-xxxx-xxxx

Preferred Apple ID setup is interactive: omit NOTARY_APP_SPECIFIC_PASSWORD and
let notarytool prompt securely. Use NOTARY_APP_SPECIFIC_PASSWORD only from a
private automation environment; this notarytool build has no password-stdin
mode, so the value must be passed to notarytool's --password option.

Do not commit Apple IDs, passwords, API keys, key IDs, issuer IDs, or Keychain
exports.
USAGE
}

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
        --apple-id)
            if [[ $# -lt 2 || "$2" == --* ]]; then
                echo "ERROR: --apple-id requires a value" >&2
                exit 2
            fi
            APPLE_ID="$2"
            shift 2
            ;;
        --team-id)
            if [[ $# -lt 2 || "$2" == --* ]]; then
                echo "ERROR: --team-id requires a value" >&2
                exit 2
            fi
            TEAM_ID="$2"
            shift 2
            ;;
        --force)
            FORCE=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 2
            ;;
    esac
done

if ! command -v xcrun >/dev/null 2>&1; then
    echo "ERROR: xcrun is required for notarytool." >&2
    exit 69
fi

echo "=== Cursor Designer Notary Profile Setup ==="
echo "Notary profile: $NOTARY_PROFILE"
echo ""

if [[ "$FORCE" -eq 0 ]] && xcrun notarytool history --keychain-profile "$NOTARY_PROFILE" >/dev/null 2>&1; then
    echo "Notary profile is already available."
    exit 0
fi

KEY_PATH="${NOTARY_KEY_PATH:-}"
KEY_ID="${NOTARY_KEY_ID:-}"
ISSUER_ID="${NOTARY_ISSUER_ID:-}"

if [[ -n "$KEY_PATH" || -n "$KEY_ID" || -n "$ISSUER_ID" ]]; then
    if [[ -z "$KEY_PATH" || -z "$KEY_ID" ]]; then
        echo "ERROR: API key setup requires NOTARY_KEY_PATH and NOTARY_KEY_ID." >&2
        echo "Set NOTARY_ISSUER_ID too when using a team API key." >&2
        exit 2
    fi
    if [[ ! -f "$KEY_PATH" ]]; then
        echo "ERROR: NOTARY_KEY_PATH does not exist: $KEY_PATH" >&2
        exit 2
    fi

    echo "Storing notary credentials using an App Store Connect API key..."
    CMD=(
        xcrun notarytool store-credentials "$NOTARY_PROFILE"
        --key "$KEY_PATH"
        --key-id "$KEY_ID"
    )
    if [[ -n "$ISSUER_ID" ]]; then
        CMD+=(--issuer "$ISSUER_ID")
    fi
    "${CMD[@]}"
else
    if [[ -z "$APPLE_ID" ]]; then
        echo "ERROR: Apple ID is required. Set NOTARY_APPLE_ID or pass --apple-id." >&2
        exit 2
    fi
    if [[ -z "$TEAM_ID" ]]; then
        echo "ERROR: Team ID is required. Set NOTARY_TEAM_ID or pass --team-id." >&2
        exit 2
    fi

    echo "Storing notary credentials using Apple ID auth..."
    if [[ -n "${NOTARY_APP_SPECIFIC_PASSWORD:-}" ]]; then
        echo "WARNING: notarytool has no password-stdin option on this machine; passing the app-specific password to notarytool --password." >&2
        echo "Prefer the interactive prompt when possible so the password is not visible in process arguments." >&2
        xcrun notarytool store-credentials "$NOTARY_PROFILE" \
            --apple-id "$APPLE_ID" \
            --team-id "$TEAM_ID" \
            --password "$NOTARY_APP_SPECIFIC_PASSWORD"
    else
        if [[ ! -t 0 ]]; then
            echo "ERROR: NOTARY_APP_SPECIFIC_PASSWORD is required in non-interactive mode." >&2
            echo "Run this target from an interactive shell so notarytool can prompt securely." >&2
            exit 2
        fi

        xcrun notarytool store-credentials "$NOTARY_PROFILE" \
            --apple-id "$APPLE_ID" \
            --team-id "$TEAM_ID"
    fi
fi

xcrun notarytool history --keychain-profile "$NOTARY_PROFILE" >/dev/null
echo "Notary profile is ready."
