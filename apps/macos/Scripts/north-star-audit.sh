#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
MACOS_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
ROOT_DIR="$(cd -- "$MACOS_DIR/../.." && pwd)"

APP_PATH=".build/release/CursorDesigner.app"
DMG_PATH="CursorDesigner.dmg"
NOTARY_PROFILE="notarization"
REPO="rogu3bear/macOS-pointer-designer"
MANUAL_EVIDENCE="ReleaseEvidence/manual-release-evidence.txt"

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
        --manual-evidence)
            if [[ $# -lt 2 || "$2" == --* ]]; then
                echo "ERROR: --manual-evidence requires a path" >&2
                exit 2
            fi
            MANUAL_EVIDENCE="$2"
            shift 2
            ;;
        -h|--help)
            echo "Usage: $0 [--app PATH] [--dmg PATH] [--notary-profile NAME] [--repo OWNER/REPO] [--manual-evidence PATH]"
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
echo "Manual evidence: $MANUAL_EVIDENCE"
echo ""

echo "Prompt-to-artifact checklist"
echo "- APP-1 menu bar launch and compatibility truth: apps/macos/REQUIREMENTS.md -> make launch-smoke, check-compatibility-boundary.sh"
echo "- APP-2 persistence, last-known permission posture, and recovery: apps/macos/REQUIREMENTS.md -> CursorSettingsTests, CursorStateControllerTests, AppSupportMigratorTests, CrashRecoveryManagerTests, MANUAL_RELEASE_CHECKS.md"
echo "- APP-3 Negative preset and custom color: apps/macos/REQUIREMENTS.md -> check-app-ui-contract.sh, CursorSettingsTests, CursorStateControllerTests"
echo "- APP-4 dynamic contrast permission truth: apps/macos/REQUIREMENTS.md -> check-app-ui-contract.sh, CursorStateControllerTests, MANUAL_RELEASE_CHECKS.md"
echo "- APP-5 unsupported helper and system-wide replacement unavailable: apps/macos/REQUIREMENTS.md -> check-app-ui-contract.sh, IdentityTests, CursorStateControllerTests"
echo "- APP-6 app bundle, DMG, and mounted app match: apps/macos/REQUIREMENTS.md -> make preflight, make dmg, make dmg-install-check, make dmg-artifact-match-check"
echo "- APP-7 signing, notarization, Gatekeeper, release metadata, install instructions, optional Homebrew/cask truth, and artifact-bound human evidence: apps/macos/REQUIREMENTS.md -> make setup-notary-profile, make notary-profile-check, make release-readiness, make release-metadata-check, manual-release-evidence-check.sh"
echo "  Manual evidence must match the same DMG digest, commit, release tag, mounted app bundle ID, app version, app build, and app executable SHA-256."
echo "- APP-8 local-first, website-boundary, and distribution-boundary product truth: apps/macos/REQUIREMENTS.md -> check-monorepo-references.sh, check-website-boundary.sh, check-distribution-boundary.sh, check-local-first.sh, IdentityTests"
echo "- Website: NORTH_STAR.md -> No canonical Cursor Designer website exists; future Leptos/Cloudflare work is limited to static-first Leptos UI, Cloudflare edge delivery, verified release metadata reads, digest display, compatibility notes, and privacy-preserving download routing."
echo "- Hosted CI: .github/workflows/ci.yml -> cheap boundary smoke only; local macOS package, DMG, signing, notarization, permission-flow, and release-evidence gates remain authoritative."
echo ""

echo ">>> Product boundary"
"$ROOT_DIR/scripts/check-monorepo-references.sh"

echo ""
echo ">>> Website boundary"
"$ROOT_DIR/scripts/check-website-boundary.sh"

echo ""
echo ">>> Distribution boundary"
"$ROOT_DIR/scripts/check-distribution-boundary.sh"

echo ""
echo ">>> Compatibility boundary"
"$ROOT_DIR/scripts/check-compatibility-boundary.sh"

echo ""
echo ">>> Local-first app surface"
"$ROOT_DIR/scripts/check-local-first.sh"

echo ""
echo ">>> App UI truth"
"$ROOT_DIR/scripts/check-app-ui-contract.sh"

echo ""
echo ">>> Core macOS behavior"
(cd "$MACOS_DIR" && swift test)

echo ""
echo ">>> Current app launch smoke"
(cd "$MACOS_DIR" && "$SCRIPT_DIR/launch-smoke.sh" --app "$APP_PATH")

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
echo ">>> Manual release evidence"
HEAD_COMMIT="$(cd "$ROOT_DIR" && git rev-parse HEAD)"
set +e
(cd "$MACOS_DIR" && "$SCRIPT_DIR/manual-release-evidence-check.sh" --evidence "$MANUAL_EVIDENCE" --dmg "$DMG_PATH" --commit "$HEAD_COMMIT")
manual_status=$?
set -e

if [[ "$manual_status" -ne 0 ]]; then
    echo ""
    echo "North Star audit result: not mass-production ready."
    echo "manual-release-evidence-check failed with exit $manual_status; complete MANUAL_RELEASE_CHECKS.md against the same Gatekeeper-accepted DMG."
    exit "$manual_status"
fi

echo ""
echo "North Star audit result: release-readiness and manual release evidence passed."
