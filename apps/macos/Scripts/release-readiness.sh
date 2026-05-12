#!/bin/bash
set -euo pipefail

APP_PATH=".build/release/CursorDesigner.app"
DMG_PATH="CursorDesigner.dmg"
NOTARY_PROFILE="notarization"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"

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

failures=()

record_failure() {
    failures+=("$1")
}

run_check() {
    local label="$1"
    shift

    echo ""
    echo ">>> $label"
    if "$@"; then
        echo "PASS: $label"
    else
        local status=$?
        echo "FAIL: $label (exit $status)" >&2
        record_failure "$label"
    fi
}

if [[ ! -d "$APP_PATH" ]]; then
    echo "ERROR: App bundle not found: $APP_PATH" >&2
    record_failure "App bundle exists"
fi

if [[ ! -f "$DMG_PATH" ]]; then
    echo "ERROR: DMG not found: $DMG_PATH" >&2
    record_failure "DMG exists"
fi

if [[ -d "$APP_PATH" ]]; then
    run_check "Code signature verifies" \
        codesign --verify --deep --strict --verbose=2 "$APP_PATH"

    run_check "Gatekeeper assessment accepts app" \
        spctl --assess --type execute --verbose=4 "$APP_PATH"
fi

if [[ -f "$DMG_PATH" ]]; then
    run_check "DMG install surface and mounted app signature verify" \
        "$SCRIPT_DIR/dmg-install-check.sh" --dmg "$DMG_PATH" --require-signature

    run_check "Stapled notarization ticket validates" \
        xcrun stapler validate "$DMG_PATH"
fi

run_check "notarytool credential profile is available" \
    xcrun notarytool history --keychain-profile "$NOTARY_PROFILE"

echo ""
if [[ ${#failures[@]} -gt 0 ]]; then
    echo "Distribution blockers:" >&2
    for failure in "${failures[@]}"; do
        echo "- $failure" >&2
    done
    exit 1
fi

echo "Release readiness passed."
