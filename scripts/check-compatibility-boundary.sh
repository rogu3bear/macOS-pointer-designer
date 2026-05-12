#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

PACKAGE_FILE="apps/macos/Package.swift"
INFO_PLIST="apps/macos/Sources/PointerDesigner/Resources/Info.plist"
APP_README="apps/macos/README.md"

if ! grep -Fq ".macOS(.v13)" "$PACKAGE_FILE"; then
  echo "ERROR: Package.swift must declare macOS 13 as the package platform." >&2
  exit 1
fi

if [[ -x /usr/libexec/PlistBuddy ]]; then
  minimum_system_version=$(/usr/libexec/PlistBuddy -c "Print :LSMinimumSystemVersion" "$INFO_PLIST" 2>/dev/null || true)
else
  minimum_system_version=$(awk '
    /<key>LSMinimumSystemVersion<\/key>/ {
      getline
      gsub(/.*<string>|<\/string>.*/, "")
      print
      exit
    }
  ' "$INFO_PLIST")
fi
if [[ "$minimum_system_version" != "13.0" ]]; then
  echo "ERROR: Info.plist LSMinimumSystemVersion must be 13.0." >&2
  echo "Actual: ${minimum_system_version:-<missing>}" >&2
  exit 1
fi

if ! grep -Fq "macOS 13.0 (Ventura) or later" "$APP_README"; then
  echo "ERROR: apps/macos/README.md must state the current supported macOS floor." >&2
  exit 1
fi

if grep -Eiq "macOS (10|11|12)(\\.| |$)|Big Sur|Monterey|Catalina|Mojave" "$APP_README" README.md NORTH_STAR.md; then
  echo "ERROR: Found an unsupported macOS compatibility claim." >&2
  echo "Cursor Designer's current verified compatibility story starts at macOS 13.0." >&2
  exit 1
fi

echo "Cursor Designer compatibility-boundary check passed."
