#!/bin/bash
set -euo pipefail

EVIDENCE_PATH="ReleaseEvidence/manual-release-evidence.txt"

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
        -h|--help)
            echo "Usage: $0 [--evidence PATH]"
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 2
            ;;
    esac
done

echo "=== Cursor Designer Manual Release Evidence Check ==="
echo "Evidence: $EVIDENCE_PATH"
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
    "make release-readiness:"
    "spctl --assess --type open --verbose=4 CursorDesigner.dmg:"
    "xcrun stapler validate CursorDesigner.dmg:"
    "APP-1 menu bar launch:"
    "APP-2 persistence after quit/relaunch:"
    "APP-2 recovery after force quit:"
    "APP-3 Negative preset and custom color:"
    "APP-4 Screen Recording denied:"
    "APP-4 Screen Recording granted:"
    "APP-5 unsupported helper/system-wide replacement unavailable:"
    "APP-6 drag install from DMG:"
    "APP-8 local-first product truth:"
    "Blocker disposition:"
)

failures=()

for field in "${required_fields[@]}"; do
    if ! grep -Fq "$field" "$EVIDENCE_PATH"; then
        failures+=("missing field: $field")
        continue
    fi

    line="$(grep -F "$field" "$EVIDENCE_PATH" | head -n 1)"
    value="${line#*"$field"}"
    value="${value#"${value%%[![:space:]]*}"}"
    if [[ -z "$value" ]]; then
        failures+=("empty field: $field")
    fi
done

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
