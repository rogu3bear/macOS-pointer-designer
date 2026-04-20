#!/bin/bash
# Trust Check Script for Cursor Designer
# Prints diagnostic info about app identity, permissions, and helper status
#
# Usage:
#   ./Scripts/trust-check.sh                          # Check /Applications/CursorDesigner.app
#   ./Scripts/trust-check.sh --app /path/to/App.app   # Check specific app bundle
#   ./Scripts/trust-check.sh --app .build/release/CursorDesigner.app  # Check build output

set -e

# Parse arguments
BUNDLE_PATH="/Applications/CursorDesigner.app"
while [[ $# -gt 0 ]]; do
    case $1 in
        --app)
            BUNDLE_PATH="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [--app /path/to/CursorDesigner.app]"
            echo ""
            echo "Options:"
            echo "  --app PATH    Path to app bundle to check (default: /Applications/CursorDesigner.app)"
            echo "  -h, --help    Show this help message"
            exit 0
            ;;
        *)
            echo "Unknown option: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# Helper function to read plist keys reliably
read_plist_key() {
    local plist="$1"
    local key="$2"

    if [[ ! -f "$plist" ]]; then
        echo "NOT FOUND"
        return 0
    fi

    # PlistBuddy is reliable for bundle plists
    local val
    val=$(/usr/libexec/PlistBuddy -c "Print :$key" "$plist" 2>/dev/null) || true
    if [[ -n "$val" ]]; then
        echo "$val"
    else
        echo "NOT FOUND"
    fi
}

echo "=== Cursor Designer Trust Check ==="
echo ""
echo "Checking: $BUNDLE_PATH"
echo ""

# App bundle info
echo "=== App Bundle ==="
INFO_PLIST="$BUNDLE_PATH/Contents/Info.plist"

if [[ ! -d "$BUNDLE_PATH" ]]; then
    echo "ERROR: App bundle not found at: $BUNDLE_PATH"
    exit 2
fi

if [[ ! -f "$INFO_PLIST" ]]; then
    echo "ERROR: Missing Info.plist at: $INFO_PLIST"
    echo "This is not a valid app bundle."
    exit 2
fi

# Read bundle metadata using PlistBuddy
APP_BUNDLE_ID="$(read_plist_key "$INFO_PLIST" CFBundleIdentifier)"
APP_NAME="$(read_plist_key "$INFO_PLIST" CFBundleDisplayName)"
[[ "$APP_NAME" == "NOT FOUND" ]] && APP_NAME="$(read_plist_key "$INFO_PLIST" CFBundleName)"
APP_VERSION="$(read_plist_key "$INFO_PLIST" CFBundleShortVersionString)"
APP_BUILD="$(read_plist_key "$INFO_PLIST" CFBundleVersion)"
APP_EXECUTABLE="$(read_plist_key "$INFO_PLIST" CFBundleExecutable)"

echo "App Name:             $APP_NAME"
echo "App Bundle ID:        $APP_BUNDLE_ID"
echo "App Version:          $APP_VERSION (build $APP_BUILD)"

# Check executable exists
MAIN_EXEC="$BUNDLE_PATH/Contents/MacOS/$APP_EXECUTABLE"
if [[ -f "$MAIN_EXEC" ]]; then
    echo "Main Executable:      EXISTS ($APP_EXECUTABLE)"
else
    echo "Main Executable:      MISSING ($MAIN_EXEC)"
fi

# Check embedded helper
EMBEDDED_HELPER="$BUNDLE_PATH/Contents/Library/LaunchServices/com.pointerdesigner.helper"
if [[ -f "$EMBEDDED_HELPER" ]]; then
    echo "Embedded Helper:      EXISTS"
else
    echo "Embedded Helper:      MISSING"
fi

# Check embedded helper plist
EMBEDDED_HELPER_PLIST="$BUNDLE_PATH/Contents/Library/LaunchServices/com.pointerdesigner.helper.plist"
if [[ -f "$EMBEDDED_HELPER_PLIST" ]]; then
    EMBEDDED_LABEL="$(read_plist_key "$EMBEDDED_HELPER_PLIST" Label)"
    echo "Embedded Helper Plist: EXISTS (Label: $EMBEDDED_LABEL)"
else
    echo "Embedded Helper Plist: MISSING"
fi

# Installed helper info
echo ""
echo "=== Installed Helper ==="
HELPER_PATH="/Library/PrivilegedHelperTools/com.pointerdesigner.helper"
if [[ -f "$HELPER_PATH" ]]; then
    echo "Helper ID:            com.pointerdesigner.helper"
    echo "Helper Path:          $HELPER_PATH (EXISTS)"
    HELPER_PID=$(cat /tmp/com.pointerdesigner.helper.pid 2>/dev/null || echo "")
    if [[ -n "$HELPER_PID" ]] && kill -0 "$HELPER_PID" 2>/dev/null; then
        echo "Helper Running:       YES (PID $HELPER_PID)"
    else
        echo "Helper Running:       NO"
    fi
else
    echo "Helper ID:            com.pointerdesigner.helper"
    echo "Helper Path:          $HELPER_PATH (NOT INSTALLED)"
    echo "Helper Running:       N/A"
fi

echo ""
echo "XPC Mach Service:     com.pointerdesigner.helper"

# App Support paths
echo ""
echo "=== App Support Paths ==="
NEW_SUPPORT="$HOME/Library/Application Support/CursorDesigner"
OLD_SUPPORT="$HOME/Library/Application Support/PointerDesigner"

NEW_EXISTS=0
OLD_EXISTS=0

if [[ -d "$NEW_SUPPORT" ]]; then
    NEW_SIZE=$(du -sh "$NEW_SUPPORT" 2>/dev/null | cut -f1 || echo "?")
    NEW_COUNT=$(find "$NEW_SUPPORT" -type f 2>/dev/null | wc -l | tr -d ' ' || echo "?")
    echo "New Path:             $NEW_SUPPORT"
    echo "  Status:             EXISTS"
    echo "  Size:               $NEW_SIZE"
    echo "  File count:         $NEW_COUNT"
    NEW_EXISTS=1
else
    echo "New Path:             $NEW_SUPPORT (not found)"
fi

if [[ -d "$OLD_SUPPORT" ]]; then
    OLD_SIZE=$(du -sh "$OLD_SUPPORT" 2>/dev/null | cut -f1 || echo "?")
    OLD_COUNT=$(find "$OLD_SUPPORT" -type f 2>/dev/null | wc -l | tr -d ' ' || echo "?")
    echo "Old Path:             $OLD_SUPPORT"
    echo "  Status:             EXISTS"
    echo "  Size:               $OLD_SIZE"
    echo "  File count:         $OLD_COUNT"
    OLD_EXISTS=1
else
    echo "Old Path:             $OLD_SUPPORT (not found)"
fi

# Warning if both exist
if [[ $NEW_EXISTS -eq 1 ]] && [[ $OLD_EXISTS -eq 1 ]]; then
    echo ""
    echo "  *** WARNING: Both old and new App Support directories exist! ***"
    echo "  Migration policy should handle this case."
    echo "  Check for unique files in old that may need merging."
fi

# Screen Recording permission (best effort)
echo ""
echo "=== Permissions ==="

# Check TCC database (may not work without SIP disabled)
TCC_DB="$HOME/Library/Application Support/com.apple.TCC/TCC.db"
if [[ -f "$TCC_DB" ]]; then
    SCREEN_PERM=$(sqlite3 "$TCC_DB" "SELECT allowed FROM access WHERE service='kTCCServiceScreenCapture' AND client='com.pointerdesigner.app'" 2>/dev/null || echo "UNKNOWN")
    if [[ "$SCREEN_PERM" == "1" ]]; then
        echo "Screen Recording:     GRANTED"
    elif [[ "$SCREEN_PERM" == "0" ]]; then
        echo "Screen Recording:     DENIED"
    else
        echo "Screen Recording:     UNKNOWN (check System Settings)"
    fi
else
    echo "Screen Recording:     UNKNOWN (TCC.db not accessible)"
fi

# Capability check
echo ""
echo "=== Capability Check ==="
echo "Can Sample:           Run app to verify (requires Screen Recording)"
echo "Can Apply Cursor:     Run app to verify (requires helper)"

echo ""
echo "=== Identity Consistency Check ==="

# Check for identifier mismatches
EXPECTED_APP_ID="com.pointerdesigner.app"
EXPECTED_HELPER_ID="com.pointerdesigner.helper"

ERRORS=0

if [[ "$APP_BUNDLE_ID" != "$EXPECTED_APP_ID" ]]; then
    echo "ERROR: App bundle ID mismatch!"
    echo "  Expected: $EXPECTED_APP_ID"
    echo "  Actual:   $APP_BUNDLE_ID"
    ERRORS=$((ERRORS + 1))
fi

# Check launchd plist if installed
LAUNCHD_PLIST="/Library/LaunchDaemons/com.pointerdesigner.helper.plist"
if [[ -f "$LAUNCHD_PLIST" ]]; then
    LAUNCHD_LABEL="$(read_plist_key "$LAUNCHD_PLIST" Label)"
    if [[ "$LAUNCHD_LABEL" != "$EXPECTED_HELPER_ID" ]]; then
        echo "ERROR: LaunchDaemon label mismatch!"
        echo "  Expected: $EXPECTED_HELPER_ID"
        echo "  Actual:   $LAUNCHD_LABEL"
        ERRORS=$((ERRORS + 1))
    fi
fi

# Check embedded helper plist label
if [[ -f "$EMBEDDED_HELPER_PLIST" ]]; then
    if [[ "$EMBEDDED_LABEL" != "$EXPECTED_HELPER_ID" ]]; then
        echo "ERROR: Embedded helper plist label mismatch!"
        echo "  Expected: $EXPECTED_HELPER_ID"
        echo "  Actual:   $EMBEDDED_LABEL"
        ERRORS=$((ERRORS + 1))
    fi
fi

if [[ $ERRORS -eq 0 ]]; then
    echo "All identity strings consistent. ✓"
else
    echo ""
    echo "Found $ERRORS identity error(s)!"
    exit 1
fi

echo ""
echo "=== Done ==="
