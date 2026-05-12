#!/bin/bash
set -euo pipefail

DMG_PATH="CursorDesigner.dmg"
APP_NAME="CursorDesigner.app"
EXPECTED_BUNDLE_ID="com.pointerdesigner.app"
MOUNT_DIR=""
REQUIRE_SIGNATURE=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --dmg)
            if [[ $# -lt 2 || "$2" == --* ]]; then
                echo "ERROR: --dmg requires a path" >&2
                exit 2
            fi
            DMG_PATH="$2"
            shift 2
            ;;
        --require-signature)
            REQUIRE_SIGNATURE=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [--dmg PATH] [--require-signature]"
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 2
            ;;
    esac
done

cleanup() {
    if [[ -n "$MOUNT_DIR" && -d "$MOUNT_DIR" ]]; then
        hdiutil detach "$MOUNT_DIR" -quiet || true
        rmdir "$MOUNT_DIR" 2>/dev/null || true
    fi
}
trap cleanup EXIT

echo "=== Cursor Designer DMG Install Check ==="
echo "DMG: $DMG_PATH"
echo ""

if [[ ! -f "$DMG_PATH" ]]; then
    echo "ERROR: DMG not found: $DMG_PATH" >&2
    exit 2
fi

echo ">>> Verifying disk image"
hdiutil verify "$DMG_PATH"

MOUNT_DIR=$(mktemp -d "${TMPDIR:-/tmp}/cursor-designer-dmg.XXXXXX")

echo ""
echo ">>> Mounting read-only"
hdiutil attach -readonly -nobrowse -noautoopen -mountpoint "$MOUNT_DIR" "$DMG_PATH" >/dev/null

APP_PATH="$MOUNT_DIR/$APP_NAME"
APPLICATIONS_LINK="$MOUNT_DIR/Applications"
INFO_PLIST="$APP_PATH/Contents/Info.plist"
EXECUTABLE_PATH="$APP_PATH/Contents/MacOS/PointerDesigner"

echo ""
echo ">>> Checking install surface"
if [[ ! -d "$APP_PATH" ]]; then
    echo "ERROR: Missing app bundle in DMG: $APP_NAME" >&2
    exit 3
fi

if [[ ! -L "$APPLICATIONS_LINK" ]]; then
    echo "ERROR: Missing Applications symlink in DMG" >&2
    exit 3
fi

if [[ "$(readlink "$APPLICATIONS_LINK")" != "/Applications" ]]; then
    echo "ERROR: Applications symlink does not point to /Applications" >&2
    exit 3
fi

if [[ ! -f "$INFO_PLIST" ]]; then
    echo "ERROR: Missing Info.plist in mounted app" >&2
    exit 3
fi

if [[ ! -x "$EXECUTABLE_PATH" ]]; then
    echo "ERROR: Missing executable in mounted app: $EXECUTABLE_PATH" >&2
    exit 3
fi

BUNDLE_ID=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$INFO_PLIST")
if [[ "$BUNDLE_ID" != "$EXPECTED_BUNDLE_ID" ]]; then
    echo "ERROR: Unexpected bundle ID in DMG app: $BUNDLE_ID" >&2
    exit 3
fi

echo ""
if [[ "$REQUIRE_SIGNATURE" == "true" ]]; then
    echo ">>> Verifying mounted app signature"
    codesign --verify --deep --strict --verbose=2 "$APP_PATH"
else
    echo ">>> Skipping mounted app signature check"
    echo "Use --require-signature for signed release-candidate artifacts."
fi

echo ""
echo "DMG install check passed."
