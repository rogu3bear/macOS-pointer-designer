#!/usr/bin/env bash
# Kill any process listening on the given port.
# Use before starting trunk serve or the Axum server to avoid port conflicts.
# Usage: ./port-free.sh <port>

set -euo pipefail

port="${1:?Usage: port-free.sh <port>}"

pids=$(lsof -ti ":$port" 2>/dev/null) || true
if [ -n "$pids" ]; then
    echo "Killing process(es) on port $port: $pids"
    echo "$pids" | xargs kill -9 2>/dev/null || true
    sleep 1
fi
