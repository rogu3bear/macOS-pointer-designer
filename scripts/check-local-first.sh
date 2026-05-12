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
  "TelemetryDeck"
  ".package(url:"
  "http://"
  "https://"
)

rg_args=(
  --line-number
  --fixed-strings
  --glob '*.swift'
  --glob 'Package.swift'
)

for pattern in "${forbidden_patterns[@]}"; do
  if command -v rg >/dev/null 2>&1; then
    matches=$(rg "${rg_args[@]}" "$pattern" "${scan_paths[@]}" || true)
  else
    matches=$({
      find apps/macos/Sources -type f -name '*.swift' -print0
      printf '%s\0' "apps/macos/Package.swift"
    } | xargs -0 grep -n -F -- "$pattern" 2>/dev/null || true)
  fi

  if [[ -n "$matches" ]]; then
    if [[ "$pattern" == "URLSession" || "$pattern" == "https://" ]]; then
      allowed_matches=$(printf '%s\n' "$matches" | grep -F "apps/macos/Sources/PointerDesignerCore/UpdateChecker.swift" || true)
      if [[ "$allowed_matches" == "$matches" ]] &&
         grep -Fq "allowsInternetAccess" "apps/macos/Sources/PointerDesignerCore/UpdateChecker.swift" &&
         grep -Fq "Internet access for update checks is disabled" "apps/macos/Sources/PointerDesignerCore/UpdateChecker.swift"; then
        continue
      fi
    fi

    printf '%s\n' "$matches"
    echo "Found network, telemetry, or tracking API in macOS app source: $pattern" >&2
    echo "Cursor Designer's pointer loop must remain local-first unless a reviewed exception is added." >&2
    exit 1
  fi
done

echo "Cursor Designer local-first app check passed."
