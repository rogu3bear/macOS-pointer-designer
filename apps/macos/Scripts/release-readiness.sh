#!/bin/bash
set -euo pipefail

APP_PATH=".build/release/CursorDesigner.app"
DMG_PATH="CursorDesigner.dmg"
NOTARY_PROFILE="notarization"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --app)
            APP_PATH="$2"
            shift 2
            ;;
        --dmg)
            DMG_PATH="$2"
            shift 2
            ;;
        --notary-profile)
            NOTARY_PROFILE="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [--app PATH] [--dmg PATH] [--notary-profile NAME]"
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 2
            ;;
    esac
done

echo "=== Cursor Designer Release Readiness ==="
echo "App:             $APP_PATH"
echo "DMG:             $DMG_PATH"
echo "Notary profile:  $NOTARY_PROFILE"
echo ""

if [[ ! -d "$APP_PATH" ]]; then
    echo "ERROR: App bundle not found: $APP_PATH" >&2
    exit 2
fi

if [[ ! -f "$DMG_PATH" ]]; then
    echo "ERROR: DMG not found: $DMG_PATH" >&2
    exit 2
fi

echo ">>> Verifying code signature"
codesign --verify --deep --strict --verbose=2 "$APP_PATH"

echo ""
echo ">>> Checking Gatekeeper assessment"
spctl --assess --type execute --verbose=4 "$APP_PATH"

echo ""
echo ">>> Validating stapled notarization ticket"
xcrun stapler validate "$DMG_PATH"

echo ""
echo ">>> Checking notarytool credential profile"
xcrun notarytool history --keychain-profile "$NOTARY_PROFILE" >/dev/null

echo ""
echo "Release readiness passed."
