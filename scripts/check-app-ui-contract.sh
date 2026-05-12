#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT_DIR"

PREFERENCES_SOURCE="apps/macos/Sources/PointerDesigner/PreferencesWindowController.swift"
MENU_SOURCE="apps/macos/Sources/PointerDesigner/MenuBarController.swift"
MAIN_SOURCE="apps/macos/Sources/PointerDesigner/main.swift"

require_text() {
  local file="$1"
  local text="$2"

  if command -v rg >/dev/null 2>&1; then
    if rg --fixed-strings --quiet "$text" "$file"; then
      return
    fi
  elif grep -Fq -- "$text" "$file"; then
    return
  fi

  echo "Missing app UI contract text in $file: $text" >&2
  exit 1
}

preferences_text=(
  "NSScrollView"
  "hasVerticalScroller"
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
  "Updates"
  "Allow internet access for update checks"
  "Check for Updates"
  "Update checks are local-off until internet access is allowed."
  "Reset to Defaults"
  "Dynamic contrast is off for contrast mode None."
  "Dynamic contrast is active for Auto-Invert and Outline."
  "Dynamic contrast is paused until Screen Recording is granted."
  "Last checked: Screen Recording"
  "Live macOS permission checks decide features."
  "Pointer Replacement Not Enabled"
  "System-wide pointer replacement is not enabled in this build."
)

menu_text=(
  "final class MenuBarController: NSObject"
  "preferencesTarget"
  "preferencesAction"
  "quitTarget"
  "quitAction"
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

require_text "$MAIN_SOURCE" "withExtendedLifetime(delegate)"

echo "Cursor Designer app UI contract check passed."
