#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
MACOS_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
ROOT_DIR="$(cd -- "$MACOS_DIR/../.." && pwd)"

APP_PATH=".build/release/CursorDesigner.app"
DMG_PATH="CursorDesigner.dmg"
NOTARY_PROFILE="notarization"
REPO="rogu3bear/macOS-pointer-designer"

while [[ $# -gt 0 ]]; do
    case "$1" in
        --app)
            if [[ $# -lt 2 || "$2" == --* ]]; then
                echo "ERROR: --app requires a path" >&2
                exit 2
            fi
            APP_PATH="$2"
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
        --notary-profile)
            if [[ $# -lt 2 || "$2" == --* ]]; then
                echo "ERROR: --notary-profile requires a name" >&2
                exit 2
            fi
            NOTARY_PROFILE="$2"
            shift 2
            ;;
        --repo)
            if [[ $# -lt 2 || "$2" == --* ]]; then
                echo "ERROR: --repo requires OWNER/REPO" >&2
                exit 2
            fi
            REPO="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [--app PATH] [--dmg PATH] [--notary-profile NAME] [--repo OWNER/REPO]"
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 2
            ;;
    esac
done

echo "=== Cursor Designer North Star Audit ==="
echo "App:            $APP_PATH"
echo "DMG:            $DMG_PATH"
echo "Notary profile: $NOTARY_PROFILE"
echo "Release repo:   $REPO"
echo ""

echo "Prompt-to-artifact checklist"
echo "- APP-1 menu bar launch: apps/macos/REQUIREMENTS.md -> make launch-smoke"
echo "- APP-2 persistence and recovery: apps/macos/REQUIREMENTS.md -> CursorStateControllerTests, AppSupportMigratorTests, CrashRecoveryManagerTests, MANUAL_RELEASE_CHECKS.md"
echo "- APP-3 Negative preset and custom color: apps/macos/REQUIREMENTS.md -> check-app-ui-contract.sh, CursorSettingsTests, CursorStateControllerTests"
echo "- APP-4 dynamic contrast permission truth: apps/macos/REQUIREMENTS.md -> check-app-ui-contract.sh, CursorStateControllerTests, MANUAL_RELEASE_CHECKS.md"
echo "- APP-5 unsupported helper and system-wide replacement unavailable: apps/macos/REQUIREMENTS.md -> check-app-ui-contract.sh, IdentityTests, CursorStateControllerTests"
echo "- APP-6 app bundle, DMG, and mounted app match: apps/macos/REQUIREMENTS.md -> make preflight, make dmg, make dmg-install-check, make dmg-artifact-match-check"
echo "- APP-7 signing, notarization, Gatekeeper, release metadata, and install instructions: apps/macos/REQUIREMENTS.md -> make release-readiness and make release-metadata-check"
echo "- APP-8 local-first product truth: apps/macos/REQUIREMENTS.md -> check-monorepo-references.sh, check-local-first.sh, IdentityTests"
echo "- Website: NORTH_STAR.md -> No canonical Cursor Designer website exists."
echo ""

echo ">>> Product boundary"
"$ROOT_DIR/scripts/check-monorepo-references.sh"

echo ""
echo ">>> Local-first app surface"
"$ROOT_DIR/scripts/check-local-first.sh"

echo ""
echo ">>> App UI truth"
"$ROOT_DIR/scripts/check-app-ui-contract.sh"

echo ""
echo ">>> Public distribution readiness"
set +e
(cd "$MACOS_DIR" && "$SCRIPT_DIR/release-readiness.sh" --app "$APP_PATH" --dmg "$DMG_PATH" --notary-profile "$NOTARY_PROFILE" --repo "$REPO")
readiness_status=$?
set -e

if [[ "$readiness_status" -ne 0 ]]; then
    echo ""
    echo "North Star audit result: not mass-production ready."
    echo "release-readiness failed with exit $readiness_status; preserve the blockers above."
    exit "$readiness_status"
fi

echo ""
echo "North Star audit result: release-readiness passed."
echo "Complete MANUAL_RELEASE_CHECKS.md against the same Gatekeeper-accepted DMG before declaring mass-production readiness."
