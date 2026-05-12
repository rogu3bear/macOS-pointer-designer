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

DMG_FILENAME="$(basename "$DMG_PATH")"
DMG_SHA256="$(shasum -a 256 "$DMG_PATH" | awk '{print $1}')"

cat <<EOF
Release tag: $RELEASE_TAG
Commit: $COMMIT
macOS version:
Hardware:
DMG filename: $DMG_FILENAME
DMG SHA-256: $DMG_SHA256

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
