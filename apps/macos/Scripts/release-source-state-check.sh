#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/../../.." && pwd)"
APP_PATH=""
DMG_PATH=""

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
        -h|--help)
            echo "Usage: $0 [--app PATH] [--dmg PATH]"
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 2
            ;;
    esac
done

if ! git -C "$ROOT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "ERROR: release source state check must run inside a git work tree" >&2
    exit 2
fi

head_commit="$(git -C "$ROOT_DIR" rev-parse HEAD)"
head_time="$(git -C "$ROOT_DIR" show -s --format=%ct HEAD)"
dirty_status="$(git -C "$ROOT_DIR" status --porcelain=v1 --untracked-files=all -- .)"

echo "Release commit: $head_commit"

if [[ -n "$dirty_status" ]]; then
    echo "ERROR: release readiness requires a clean committed tree." >&2
    echo "The signed app and DMG must be built from the same committed state that manual release evidence records." >&2
    echo "" >&2
    echo "Uncommitted or untracked files:" >&2
    printf '%s\n' "$dirty_status" >&2
    echo "" >&2
    echo "Commit the release tranche, rebuild/sign/notarize the DMG from that commit, then rerun release-readiness." >&2
    exit 1
fi

if [[ -n "$APP_PATH" ]]; then
    app_executable="$APP_PATH/Contents/MacOS/PointerDesigner"

    if [[ ! -x "$app_executable" ]]; then
        echo "ERROR: release app executable not found or not executable: $app_executable" >&2
        exit 1
    fi

    app_time="$(stat -f %m "$app_executable")"
    if (( app_time <= head_time )); then
        echo "ERROR: release app executable is not newer than the release commit." >&2
        echo "Rebuild the app from HEAD before running release readiness." >&2
        exit 1
    fi
fi

if [[ -n "$DMG_PATH" ]]; then
    if [[ ! -f "$DMG_PATH" ]]; then
        echo "ERROR: release DMG not found: $DMG_PATH" >&2
        exit 1
    fi

    dmg_time="$(stat -f %m "$DMG_PATH")"
    if (( dmg_time <= head_time )); then
        echo "ERROR: release DMG is not newer than the release commit." >&2
        echo "Recreate, sign, notarize, and staple the DMG from HEAD before running release readiness." >&2
        exit 1
    fi
fi

echo "Release source tree is clean."
