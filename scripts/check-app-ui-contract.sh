#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

if ! command -v rg >/dev/null 2>&1; then
  echo "ripgrep (rg) is required for app UI contract checks." >&2
  exit 127
fi

PREFERENCES_SOURCE="apps/macos/Sources/PointerDesigner/PreferencesWindowController.swift"
MENU_SOURCE="apps/macos/Sources/PointerDesigner/MenuBarController.swift"

require_text() {
  local file="$1"
  local text="$2"

  if ! rg --fixed-strings --quiet "$text" "$file"; then
    echo "Missing app UI contract text in $file: $text" >&2
    exit 1
  fi
}

preferences_text=(
  "Cursor Designer Preferences"
  "Theme"
  "Cursor Color"
  "Cursor Size"
  "Visual Effects"
  "Glow Effect"
  "Drop Shadow"
  "Contrast Mode"
  "None"
  "Auto-Invert"
  "Outline"
  "Outline Width"
  "Background Sampling Rate"
  "Screen Recording"
  "Open System Settings"
  "Pointer Scope"
  "Custom pointer preview works in Cursor Designer. System-wide pointer replacement is not enabled in this build."
  "Launch at Login"
  "Reset to Defaults"
  "Dynamic contrast is off for contrast mode None."
  "Dynamic contrast is active for Auto-Invert and Outline."
  "Dynamic contrast is paused until Screen Recording is granted."
  "Pointer Replacement Not Enabled"
  "System-wide pointer replacement is not enabled in this build."
)

menu_text=(
  "Enabled"
  "Disabled"
  "Contrast Mode"
  "Themes"
  "Preferences..."
  "Quit"
  "Cursor Designer Menu"
)

for text in "${preferences_text[@]}"; do
  require_text "$PREFERENCES_SOURCE" "$text"
done

for text in "${menu_text[@]}"; do
  require_text "$MENU_SOURCE" "$text"
done

echo "Cursor Designer app UI contract check passed."
