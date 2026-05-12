#!/bin/bash
set -euo pipefail

DMG_PATH="CursorDesigner.dmg"
RELEASE_TAG=""
COMMIT="$(git rev-parse HEAD)"

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
        --release-tag)
            if [[ $# -lt 2 || "$2" == --* ]]; then
                echo "ERROR: --release-tag requires a tag" >&2
                exit 2
            fi
            RELEASE_TAG="$2"
            shift 2
            ;;
        --commit)
            if [[ $# -lt 2 || "$2" == --* ]]; then
                echo "ERROR: --commit requires a commit" >&2
                exit 2
            fi
            COMMIT="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [--dmg PATH] [--release-tag TAG] [--commit COMMIT]"
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 2
            ;;
    esac
done

if [[ ! -f "$DMG_PATH" ]]; then
    echo "ERROR: DMG not found: $DMG_PATH" >&2
    exit 1
fi

if [[ -z "$RELEASE_TAG" ]]; then
    echo "ERROR: RELEASE_TAG is required for artifact-bound manual release evidence" >&2
    echo "Run: make manual-release-evidence-template RELEASE_TAG=\"v<app-version>\"" >&2
    exit 2
fi

DMG_FILENAME="$(basename "$DMG_PATH")"
DMG_SHA256="$(shasum -a 256 "$DMG_PATH" | awk '{print $1}')"
MOUNT_DIR=""

cleanup() {
    if [[ -n "$MOUNT_DIR" && -d "$MOUNT_DIR" ]]; then
        hdiutil detach "$MOUNT_DIR" -quiet || true
        rmdir "$MOUNT_DIR" 2>/dev/null || true
    fi
}
trap cleanup EXIT

MOUNT_DIR=$(mktemp -d "${TMPDIR:-/tmp}/cursor-designer-evidence.XXXXXX")
hdiutil attach -readonly -nobrowse -noautoopen -mountpoint "$MOUNT_DIR" "$DMG_PATH" >/dev/null

APP_PATH="$MOUNT_DIR/CursorDesigner.app"
INFO_PLIST="$APP_PATH/Contents/Info.plist"
EXECUTABLE_PATH="$APP_PATH/Contents/MacOS/PointerDesigner"

if [[ ! -f "$INFO_PLIST" ]]; then
    echo "ERROR: mounted DMG app is missing Info.plist" >&2
    exit 1
fi

if [[ ! -x "$EXECUTABLE_PATH" ]]; then
    echo "ERROR: mounted DMG app is missing executable: $EXECUTABLE_PATH" >&2
    exit 1
fi

APP_BUNDLE_ID=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$INFO_PLIST")
APP_VERSION=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$INFO_PLIST")
APP_BUILD=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$INFO_PLIST")
APP_EXECUTABLE_SHA256="$(shasum -a 256 "$EXECUTABLE_PATH" | awk '{print $1}')"
EXPECTED_RELEASE_TAG="v$APP_VERSION"

if [[ "$RELEASE_TAG" != "$EXPECTED_RELEASE_TAG" ]]; then
    echo "ERROR: RELEASE_TAG does not match mounted app version" >&2
    echo "Release tag:  $RELEASE_TAG" >&2
    echo "Expected tag: $EXPECTED_RELEASE_TAG" >&2
    exit 2
fi

cat <<EOF
Release tag: $RELEASE_TAG
Commit: $COMMIT
macOS version:
Hardware:
DMG filename: $DMG_FILENAME
DMG SHA-256: $DMG_SHA256
App bundle ID: $APP_BUNDLE_ID
App version: $APP_VERSION
App build: $APP_BUILD
App executable SHA-256: $APP_EXECUTABLE_SHA256

Machine gates:
- make release-readiness:
- spctl --assess --type open --verbose=4 CursorDesigner.dmg:
- xcrun stapler validate CursorDesigner.dmg:

Manual observations:
- APP-1 menu bar launch:
- APP-2 persistence after quit/relaunch:
- APP-2 recovery after force quit:
- APP-3 Negative preset and custom color:
- APP-4 Screen Recording denied:
- APP-4 Screen Recording granted:
- APP-5 unsupported helper/system-wide replacement unavailable:
- APP-6 drag install from DMG:
- APP-8 local-first and website-boundary product truth:

Blocker disposition:
EOF
