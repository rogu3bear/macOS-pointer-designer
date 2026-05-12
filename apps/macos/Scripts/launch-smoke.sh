#!/bin/bash
set -euo pipefail

APP_PATH=".build/release/CursorDesigner.app"
PROCESS_NAME="PointerDesigner"
LAUNCHED_PID=""

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
        -h|--help)
            echo "Usage: $0 [--app PATH]"
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 2
            ;;
    esac
done

cleanup() {
    if [[ -n "$LAUNCHED_PID" ]] && kill -0 "$LAUNCHED_PID" 2>/dev/null; then
        kill -TERM "$LAUNCHED_PID" 2>/dev/null || true
        for _ in {1..20}; do
            if ! kill -0 "$LAUNCHED_PID" 2>/dev/null; then
                return
            fi
            sleep 0.1
        done
        kill -KILL "$LAUNCHED_PID" 2>/dev/null || true
    fi
}
trap cleanup EXIT

echo "=== Cursor Designer Launch Smoke ==="
echo "App: $APP_PATH"
echo ""

if [[ ! -d "$APP_PATH" ]]; then
    echo "ERROR: App bundle not found: $APP_PATH" >&2
    exit 2
fi

if [[ ! -x "$APP_PATH/Contents/MacOS/$PROCESS_NAME" ]]; then
    echo "ERROR: App executable not found: $APP_PATH/Contents/MacOS/$PROCESS_NAME" >&2
    exit 2
fi

if pgrep -x "$PROCESS_NAME" >/dev/null; then
    echo "ERROR: $PROCESS_NAME is already running; close it before launch smoke." >&2
    exit 2
fi

echo ">>> Launching app"
open -n "$APP_PATH"

for _ in {1..40}; do
    LAUNCHED_PID=$(pgrep -nx "$PROCESS_NAME" || true)
    if [[ -n "$LAUNCHED_PID" ]]; then
        break
    fi
    sleep 0.25
done

if [[ -z "$LAUNCHED_PID" ]]; then
    echo "ERROR: $PROCESS_NAME did not start" >&2
    exit 3
fi

sleep 2

if ! kill -0 "$LAUNCHED_PID" 2>/dev/null; then
    echo "ERROR: $PROCESS_NAME exited during launch smoke" >&2
    exit 3
fi

echo "Launch smoke passed with PID $LAUNCHED_PID."
