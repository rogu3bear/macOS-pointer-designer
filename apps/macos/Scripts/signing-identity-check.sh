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
