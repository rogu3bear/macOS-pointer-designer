#!/bin/bash
set -euo pipefail

DMG_PATH="CursorDesigner.dmg"
APP_NAME="CursorDesigner.app"
EXPECTED_BUNDLE_ID="com.pointerdesigner.app"
EXPECTED_APP_PATH=""
MOUNT_DIR=""
REQUIRE_SIGNATURE=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --app)
            if [[ $# -lt 2 || "$2" == --* ]]; then
                echo "ERROR: --app requires a path" >&2
                exit 2
            fi
            EXPECTED_APP_PATH="$2"
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
        --require-signature)
            REQUIRE_SIGNATURE=true
            shift
            ;;
        -h|--help)
            echo "Usage: $0 [--app PATH] [--dmg PATH] [--require-signature]"
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
if [[ -n "$EXPECTED_APP_PATH" ]]; then
    echo "Expected app: $EXPECTED_APP_PATH"
fi
echo ""

if [[ ! -f "$DMG_PATH" ]]; then
    echo "ERROR: DMG not found: $DMG_PATH" >&2
    exit 2
fi

if [[ -n "$EXPECTED_APP_PATH" && ! -d "$EXPECTED_APP_PATH" ]]; then
    echo "ERROR: Expected app bundle not found: $EXPECTED_APP_PATH" >&2
    exit 2
fi

echo ">>> Verifying disk image"
hdiutil verify "$DMG_PATH"

MOUNT_DIR=$(mktemp -d "${TMPDIR:-/tmp}/cursor-designer-dmg.XXXXXX")

echo ""
echo ">>> Mounting read-only"
hdiutil attach -readonly -nobrowse -noautoopen -mountpoint "$MOUNT_DIR" "$DMG_PATH" >/dev/null

MOUNTED_APP_PATH="$MOUNT_DIR/$APP_NAME"
APPLICATIONS_LINK="$MOUNT_DIR/Applications"
INFO_PLIST="$MOUNTED_APP_PATH/Contents/Info.plist"
EXECUTABLE_PATH="$MOUNTED_APP_PATH/Contents/MacOS/PointerDesigner"

echo ""
echo ">>> Checking install surface"
if [[ ! -d "$MOUNTED_APP_PATH" ]]; then
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

if [[ -n "$EXPECTED_APP_PATH" ]]; then
    echo ""
    echo ">>> Comparing mounted app to expected app"
    EXPECTED_INFO_PLIST="$EXPECTED_APP_PATH/Contents/Info.plist"
    EXPECTED_EXECUTABLE_PATH="$EXPECTED_APP_PATH/Contents/MacOS/PointerDesigner"

    if [[ ! -f "$EXPECTED_INFO_PLIST" ]]; then
        echo "ERROR: Missing Info.plist in expected app: $EXPECTED_INFO_PLIST" >&2
        exit 4
    fi

    if [[ ! -x "$EXPECTED_EXECUTABLE_PATH" ]]; then
        echo "ERROR: Missing executable in expected app: $EXPECTED_EXECUTABLE_PATH" >&2
        exit 4
    fi

    for key in CFBundleIdentifier CFBundleShortVersionString CFBundleVersion; do
        mounted_value=$(/usr/libexec/PlistBuddy -c "Print :$key" "$INFO_PLIST")
        expected_value=$(/usr/libexec/PlistBuddy -c "Print :$key" "$EXPECTED_INFO_PLIST")

        if [[ "$mounted_value" != "$expected_value" ]]; then
            echo "ERROR: Mounted app $key does not match expected app." >&2
            echo "Mounted:  $mounted_value" >&2
            echo "Expected: $expected_value" >&2
            exit 4
        fi
    done

    mounted_executable_sha=$(shasum -a 256 "$EXECUTABLE_PATH" | awk '{print $1}')
    expected_executable_sha=$(shasum -a 256 "$EXPECTED_EXECUTABLE_PATH" | awk '{print $1}')

    if [[ "$mounted_executable_sha" != "$expected_executable_sha" ]]; then
        echo "ERROR: Mounted app executable does not match expected app executable." >&2
        echo "Mounted:  $mounted_executable_sha" >&2
        echo "Expected: $expected_executable_sha" >&2
        exit 4
    fi

    echo "Mounted app matches expected app bundle."
fi

echo ""
if [[ "$REQUIRE_SIGNATURE" == "true" ]]; then
    echo ">>> Verifying mounted app signature"
    codesign --verify --deep --strict --verbose=2 "$MOUNTED_APP_PATH"
else
    echo ">>> Skipping mounted app signature check"
    echo "Use --require-signature for signed release-candidate artifacts."
fi

echo ""
echo "DMG install check passed."
