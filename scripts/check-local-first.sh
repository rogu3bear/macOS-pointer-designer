#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

scan_paths=(
  "apps/macos/Sources"
  "apps/macos/Package.swift"
)

forbidden_patterns=(
  "URLSession"
  "NSURLConnection"
  "CFHTTP"
  "NWConnection"
  "NWListener"
  "NWTCPConnection"
  "WebSocket"
  "SentrySDK"
  "FirebaseApp"
  "Analytics.logEvent"
  "PostHogSDK"
  "Mixpanel"
  "Amplitude"
  "Segment"
)

rg_args=(
  --line-number
  --fixed-strings
  --glob '*.swift'
  --glob 'Package.swift'
)

for pattern in "${forbidden_patterns[@]}"; do
  if rg "${rg_args[@]}" "$pattern" "${scan_paths[@]}"; then
    echo "Found network, telemetry, or tracking API in macOS app source: $pattern" >&2
    echo "Cursor Designer's pointer loop must remain local-first unless a reviewed exception is added." >&2
    exit 1
  fi
done

echo "Cursor Designer local-first app check passed."
