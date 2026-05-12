#!/bin/bash
set -euo pipefail

APP_PATH=".build/release/CursorDesigner.app"
DMG_PATH="CursorDesigner.dmg"
NOTARY_PROFILE="notarization"
REPO="rogu3bear/macOS-pointer-designer"
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
SKIP_RELEASE_METADATA=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --app)
            if [[ $# -lt 2 || "$2" == --* ]]; then
                echo "ERROR: --app requires a path" >&2
                exit 2
            fi
            APP_PATH="$2"
            shift 2
            ;;
        --dmg)
            if [[ $# -lt 2 || "$2" == --* ]]; then
                echo "ERROR: --dmg requires a path" >&2
                exit 2
            fi
            DMG_PATH="$2"
            shift 2
            ;;
        --notary-profile)
            if [[ $# -lt 2 || "$2" == --* ]]; then
                echo "ERROR: --notary-profile requires a name" >&2
                exit 2
            fi
            NOTARY_PROFILE="$2"
            shift 2
            ;;
        --repo)
            if [[ $# -lt 2 || "$2" == --* ]]; then
                echo "ERROR: --repo requires OWNER/REPO" >&2
                exit 2
            fi
            REPO="$2"
            shift 2
            ;;
        --skip-release-metadata)
            SKIP_RELEASE_METADATA=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [--app PATH] [--dmg PATH] [--notary-profile NAME] [--repo OWNER/REPO] [--skip-release-metadata]"
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 2
            ;;
    esac
done

if [[ "$SKIP_RELEASE_METADATA" == true ]]; then
    echo "=== Cursor Designer Release Artifact Readiness ==="
else
    echo "=== Cursor Designer Release Readiness ==="
fi
echo "App:             $APP_PATH"
echo "DMG:             $DMG_PATH"
echo "Notary profile:  $NOTARY_PROFILE"
echo "Release repo:    $REPO"
if [[ "$SKIP_RELEASE_METADATA" == true ]]; then
    echo "Release metadata: skipped"
fi
echo ""

failures=()

record_failure() {
    failures+=("$1")
}

has_failure() {
    local expected="$1"

    for failure in "${failures[@]}"; do
        if [[ "$failure" == "$expected" ]]; then
            return 0
        fi
    done

    return 1
}

print_next_required_proof() {
    echo "" >&2
    echo "Next required proof:" >&2

    if has_failure "Code signature verifies" ||
       has_failure "Hardened runtime is enabled" ||
       has_failure "DMG install surface and mounted app signature verify" ||
       has_failure "DMG signature verifies"; then
        echo "- Build and sign the app with a Developer ID Application identity, recreate the DMG from that signed app, sign the DMG, then rerun this gate." >&2
    fi

    if has_failure "notarytool credential profile is available"; then
        echo "- Store or select a valid notarytool profile, then rerun this gate with NOTARY_PROFILE=<profile>." >&2
    fi

    if has_failure "Gatekeeper assessment accepts app" ||
       has_failure "Gatekeeper assessment accepts DMG" ||
       has_failure "Stapled notarization ticket validates"; then
        echo "- Notarize the signed DMG, staple the ticket, and rerun Gatekeeper assessment for both the app and DMG." >&2
    fi

    if has_failure "Stable release metadata includes CursorDesigner.dmg"; then
        echo "- Publish a stable GitHub release with CursorDesigner.dmg and verify its SHA-256 digest matches this local DMG." >&2
    fi

    echo "- After this gate passes, complete MANUAL_RELEASE_CHECKS.md against the same Gatekeeper-accepted DMG." >&2
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

check_hardened_runtime() {
    local app_path="$1"
    local details

    if ! details=$(codesign -dvvv --verbose=4 "$app_path" 2>&1); then
        echo "$details"
        return 1
    fi

    if ! grep -q "Runtime Version" <<<"$details"; then
        echo "ERROR: Hardened runtime is not enabled for $app_path" >&2
        echo "$details" | grep -E "Identifier=|flags=|Authority=|TeamIdentifier=|Timestamp=" >&2 || true
        return 1
    fi

    echo "$details" | grep -E "Runtime Version|Authority=|TeamIdentifier=|Timestamp=" || true
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

    run_check "Hardened runtime is enabled" \
        check_hardened_runtime "$APP_PATH"

    run_check "Gatekeeper assessment accepts app" \
        spctl --assess --type execute --verbose=4 "$APP_PATH"
fi

if [[ -f "$DMG_PATH" ]]; then
    run_check "DMG install surface and mounted app signature verify" \
        "$SCRIPT_DIR/dmg-install-check.sh" --dmg "$DMG_PATH" --require-signature

    run_check "DMG signature verifies" \
        codesign --verify --verbose=2 "$DMG_PATH"

    run_check "Gatekeeper assessment accepts DMG" \
        spctl --assess --type open --verbose=4 "$DMG_PATH"

    run_check "Stapled notarization ticket validates" \
        xcrun stapler validate "$DMG_PATH"
fi

run_check "notarytool credential profile is available" \
    xcrun notarytool history --keychain-profile "$NOTARY_PROFILE"

if [[ "$SKIP_RELEASE_METADATA" == true ]]; then
    echo ""
    echo ">>> Stable release metadata includes CursorDesigner.dmg"
    echo "SKIP: Stable release metadata check deferred until public release verification."
else
    run_check "Stable release metadata includes CursorDesigner.dmg" \
        "$SCRIPT_DIR/release-metadata-check.sh" --repo "$REPO" --dmg "$DMG_PATH"
fi

echo ""
if [[ ${#failures[@]} -gt 0 ]]; then
    echo "Distribution blockers:" >&2
    for failure in "${failures[@]}"; do
        echo "- $failure" >&2
    done
    print_next_required_proof
    exit 1
fi

if [[ "$SKIP_RELEASE_METADATA" == true ]]; then
    echo "Release artifact readiness passed."
    echo "Run make release-readiness after publishing stable release metadata."
else
    echo "Release readiness passed."
fi
