#!/usr/bin/env bash
set -euo pipefail

port="${1:?Usage: port-free.sh <port>}"

current_pids() {
    lsof -ti ":$port" 2>/dev/null || true
}

pids="$(current_pids)"
if [[ -z "$pids" ]]; then
    exit 0
fi

echo "Stopping process(es) on port $port: $pids"
echo "$pids" | xargs kill 2>/dev/null || true

for _ in 1 2 3 4 5; do
    sleep 1
    if [[ -z "$(current_pids)" ]]; then
        exit 0
    fi
done

remaining="$(current_pids)"
if [[ -n "$remaining" ]]; then
    echo "Force-stopping remaining process(es) on port $port: $remaining"
    echo "$remaining" | xargs kill -9 2>/dev/null || true
fi
