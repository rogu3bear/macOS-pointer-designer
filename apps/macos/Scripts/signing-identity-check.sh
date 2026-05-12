#!/bin/bash
set -euo pipefail

SIGN_IDENTITY="Developer ID Application"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --sign-identity)
            if [[ $# -lt 2 || "$2" == --* ]]; then
                echo "ERROR: --sign-identity requires a name" >&2
                exit 2
            fi
            SIGN_IDENTITY="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [--sign-identity NAME]"
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 2
            ;;
    esac
done

echo "=== Cursor Designer Signing Identity Check ==="
echo "Signing identity: $SIGN_IDENTITY"
echo ""

IDENTITIES=$(security find-identity -v -p codesigning)

if grep -Fq "\"$SIGN_IDENTITY\"" <<<"$IDENTITIES"; then
    echo "Signing identity is available."
    exit 0
fi

if [[ "$SIGN_IDENTITY" == "Developer ID Application" ]]; then
    matching_identities=$(grep -E '"Developer ID Application: .+ \([A-Z0-9]+\)"' <<<"$IDENTITIES" || true)
    matching_count=$(grep -Ec '"Developer ID Application: .+ \([A-Z0-9]+\)"' <<<"$IDENTITIES" || true)

    if [[ "$matching_count" -eq 1 ]]; then
        resolved_identity=$(sed -E 's/^.*"([^"]+)".*$/\1/' <<<"$matching_identities")
        echo "Resolved default signing identity: $resolved_identity"
        exit 0
    fi

    if [[ "$matching_count" -gt 1 ]]; then
        echo "$IDENTITIES" >&2
        echo "" >&2
        echo "ERROR: multiple Developer ID Application identities are available." >&2
        echo "Set SIGN_IDENTITY to the exact identity printed by security find-identity." >&2
        exit 69
    fi
fi

echo "$IDENTITIES" >&2
echo "" >&2
echo "ERROR: signing identity '$SIGN_IDENTITY' is not available for codesigning." >&2
echo "" >&2
echo "Install or select a valid Developer ID Application certificate, then rerun the release-candidate gate:" >&2
echo "" >&2
echo "  make release-candidate SIGN_IDENTITY=\"Developer ID Application: Example Team (TEAMID)\" NOTARY_PROFILE=\"<profile>\"" >&2
echo "" >&2
echo "Do not commit certificates, private keys, keychains, provisioning profiles, or exported identities." >&2
exit 68
