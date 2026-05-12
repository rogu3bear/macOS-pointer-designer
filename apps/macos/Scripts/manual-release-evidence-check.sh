#!/bin/bash
set -euo pipefail

EVIDENCE_PATH="ReleaseEvidence/manual-release-evidence.txt"
DMG_PATH="CursorDesigner.dmg"
EXPECTED_COMMIT=""
MOUNT_DIR=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        --evidence)
            if [[ $# -lt 2 || "$2" == --* ]]; then
                echo "ERROR: --evidence requires a path" >&2
                exit 2
            fi
            EVIDENCE_PATH="$2"
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
        --commit)
            if [[ $# -lt 2 || "$2" == --* ]]; then
                echo "ERROR: --commit requires a commit" >&2
                exit 2
            fi
            EXPECTED_COMMIT="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [--evidence PATH] [--dmg PATH] [--commit COMMIT]"
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 2
            ;;
    esac
done

cleanup() {
    if [[ -n "$MOUNT_DIR" && -d "$MOUNT_DIR" ]]; then
        hdiutil detach "$MOUNT_DIR" -quiet || true
        rmdir "$MOUNT_DIR" 2>/dev/null || true
    fi
}
trap cleanup EXIT

echo "=== Cursor Designer Manual Release Evidence Check ==="
echo "Evidence: $EVIDENCE_PATH"
echo "DMG:      $DMG_PATH"
if [[ -n "$EXPECTED_COMMIT" ]]; then
    echo "Commit:   $EXPECTED_COMMIT"
fi
echo ""

if [[ ! -f "$EVIDENCE_PATH" ]]; then
    echo "Manual release evidence is incomplete: file not found." >&2
    echo "Create the evidence from MANUAL_RELEASE_CHECKS.md after release-readiness passes." >&2
    exit 1
fi

required_fields=(
    "Release tag:"
    "Commit:"
    "macOS version:"
    "Hardware:"
    "DMG filename:"
    "DMG SHA-256:"
    "App bundle ID:"
    "App version:"
    "App build:"
    "App executable SHA-256:"
    "make release-readiness:"
    "spctl --assess --type open --context context:primary-signature --verbose=4 CursorDesigner.dmg:"
    "xcrun stapler validate CursorDesigner.dmg:"
    "APP-1 menu bar launch:"
    "APP-2 persistence after quit/relaunch:"
    "APP-2 last-known permission posture:"
    "APP-2 recovery after force quit:"
    "APP-3 Negative preset and custom color:"
    "APP-4 Screen Recording denied:"
    "APP-4 Screen Recording granted:"
    "APP-5 unsupported helper/system-wide replacement unavailable:"
    "APP-6 drag install from DMG:"
    "APP-8 local-first, website-boundary, and future Leptos/Cloudflare product truth:"
    "Blocker disposition:"
)

observed_fields=(
    "make release-readiness:"
    "spctl --assess --type open --context context:primary-signature --verbose=4 CursorDesigner.dmg:"
    "xcrun stapler validate CursorDesigner.dmg:"
    "APP-1 menu bar launch:"
    "APP-2 persistence after quit/relaunch:"
    "APP-2 last-known permission posture:"
    "APP-2 recovery after force quit:"
    "APP-3 Negative preset and custom color:"
    "APP-4 Screen Recording denied:"
    "APP-4 Screen Recording granted:"
    "APP-5 unsupported helper/system-wide replacement unavailable:"
    "APP-6 drag install from DMG:"
    "APP-8 local-first, website-boundary, and future Leptos/Cloudflare product truth:"
)

failures=()

field_value() {
    local field="$1"
    local line
    local value

    line="$(grep -F "$field" "$EVIDENCE_PATH" | head -n 1)"
    value="${line#*"$field"}"
    value="${value#"${value%%[![:space:]]*}"}"
    echo "$value"
}

for field in "${required_fields[@]}"; do
    if ! grep -Fq "$field" "$EVIDENCE_PATH"; then
        failures+=("missing field: $field")
        continue
    fi

    value="$(field_value "$field")"
    if [[ -z "$value" ]]; then
        failures+=("empty field: $field")
    fi
done

for field in "${observed_fields[@]}"; do
    value="$(field_value "$field")"
    if [[ "$value" =~ [Ff]ail|[Ff]ailed|[Ff]ailing|[Bb]locked|[Ss]kipped|[Pp]ending|[Uu]ntested|[Ii]ncomplete|[Nn]/?[Aa]([[:space:].,:;-]|$)|[Nn]ot[[:space:]]+(run|performed|observed|tested|verified|applicable) ]]; then
        failures+=("non-passing evidence recorded for: $field")
    fi
done

blocker_disposition="$(field_value "Blocker disposition:")"
if [[ ! "$blocker_disposition" =~ ^[Nn]one([[:space:].,:;-]|$) ]]; then
    failures+=("Blocker disposition must be None for final release evidence")
fi

if [[ -f "$DMG_PATH" ]]; then
    recorded_filename="$(field_value "DMG filename:")"
    actual_filename="$(basename "$DMG_PATH")"
    if [[ "$recorded_filename" != "$actual_filename" ]]; then
        failures+=("Recorded DMG filename does not match $DMG_PATH")
    fi

    recorded_digest="$(field_value "DMG SHA-256:")"
    actual_digest="$(shasum -a 256 "$DMG_PATH" | awk '{print $1}')"
    if [[ "$recorded_digest" != "$actual_digest" ]]; then
        failures+=("Recorded DMG SHA-256 does not match $DMG_PATH")
    fi

    MOUNT_DIR=$(mktemp -d "${TMPDIR:-/tmp}/cursor-designer-evidence.XXXXXX")
    if hdiutil attach -readonly -nobrowse -noautoopen -mountpoint "$MOUNT_DIR" "$DMG_PATH" >/dev/null; then
        mounted_app="$MOUNT_DIR/CursorDesigner.app"
        info_plist="$mounted_app/Contents/Info.plist"
        executable_path="$mounted_app/Contents/MacOS/PointerDesigner"

        if [[ ! -f "$info_plist" ]]; then
            failures+=("Mounted DMG app is missing Info.plist")
        elif [[ ! -x "$executable_path" ]]; then
            failures+=("Mounted DMG app is missing executable")
        else
            actual_bundle_id=$(/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" "$info_plist")
            actual_version=$(/usr/libexec/PlistBuddy -c "Print :CFBundleShortVersionString" "$info_plist")
            actual_build=$(/usr/libexec/PlistBuddy -c "Print :CFBundleVersion" "$info_plist")
            actual_executable_digest="$(shasum -a 256 "$executable_path" | awk '{print $1}')"

            if [[ "$(field_value "App bundle ID:")" != "$actual_bundle_id" ]]; then
                failures+=("Recorded app bundle ID does not match mounted DMG app")
            fi

            if [[ "$(field_value "App version:")" != "$actual_version" ]]; then
                failures+=("Recorded app version does not match mounted DMG app")
            fi

            expected_release_tag="v$actual_version"
            if [[ "$(field_value "Release tag:")" != "$expected_release_tag" ]]; then
                failures+=("Recorded release tag does not match mounted DMG app version")
            fi

            if [[ "$(field_value "App build:")" != "$actual_build" ]]; then
                failures+=("Recorded app build does not match mounted DMG app")
            fi

            if [[ "$(field_value "App executable SHA-256:")" != "$actual_executable_digest" ]]; then
                failures+=("Recorded app executable SHA-256 does not match mounted DMG app")
            fi
        fi
    else
        failures+=("DMG could not be mounted for app identity verification: $DMG_PATH")
    fi
else
    failures+=("DMG not found for evidence digest check: $DMG_PATH")
fi

if [[ -n "$EXPECTED_COMMIT" ]]; then
    recorded_commit="$(field_value "Commit:")"
    if [[ "$recorded_commit" != "$EXPECTED_COMMIT" ]]; then
        failures+=("Recorded commit does not match $EXPECTED_COMMIT")
    fi
fi

if grep -Eq "Pass/fail|None, or list every blocker|expected results|TODO|TBD|FIXME" "$EVIDENCE_PATH"; then
    failures+=("template placeholder text remains")
fi

if [[ ${#failures[@]} -gt 0 ]]; then
    echo "Manual release evidence is incomplete:" >&2
    for failure in "${failures[@]}"; do
        echo "- $failure" >&2
    done
    exit 1
fi

echo "Manual release evidence check passed."
