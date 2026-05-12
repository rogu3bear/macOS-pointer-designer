.PHONY: all build release clean test install uninstall dmg create-dmg signed-dmg sign-dmg preflight launch-smoke dmg-install-check dmg-artifact-match-check release-metadata-check signing-identity-check notary-profile-check release-artifact-readiness release-readiness release-candidate

PRODUCT_NAME = CursorDesigner
BUILD_DIR = .build
RELEASE_DIR = $(BUILD_DIR)/release
APP_BUNDLE = $(RELEASE_DIR)/$(PRODUCT_NAME).app
DMG_NAME = $(PRODUCT_NAME).dmg
SIGN_IDENTITY ?= Developer ID Application
NOTARY_PROFILE ?= notarization
GITHUB_REPO ?= rogu3bear/macOS-pointer-designer

# Build configuration
SWIFT_BUILD_FLAGS = -c release --arch arm64 --arch x86_64

all: build

# Build the app
build:
	swift build $(SWIFT_BUILD_FLAGS)

# Build release app bundle
release: build
	@echo "Creating app bundle..."
	@mkdir -p "$(APP_BUNDLE)/Contents/MacOS"
	@mkdir -p "$(APP_BUNDLE)/Contents/Resources"

	# Copy main executable
	@cp "$(BUILD_DIR)/apple/Products/Release/PointerDesigner" "$(APP_BUNDLE)/Contents/MacOS/"

	# Copy resources
	@cp "Sources/PointerDesigner/Resources/Info.plist" "$(APP_BUNDLE)/Contents/"

	@echo "App bundle created at $(APP_BUNDLE)"

# Run tests
test:
	swift test

# Preflight check: build fresh, run tests, validate bundle
# Use this before commits/releases to catch identity or wiring regressions
# Exits non-zero if any step fails (tests fail, bundle invalid, identity mismatch)
preflight: clean release
	@echo ""
	@echo "=== Running Preflight Checks ==="
	@echo ""
	@echo ">>> Step 1: swift test"
	@swift test
	@echo ""
	@echo ">>> Step 2: Validate app bundle"
	@./Scripts/trust-check.sh --app $(APP_BUNDLE)
	@echo ""
	@echo "=== Preflight Complete ✓ ==="

# Launch the built app and verify it stays alive long enough for a menu bar smoke test.
launch-smoke: release
	@./Scripts/launch-smoke.sh --app "$(APP_BUNDLE)"

# Clean build artifacts
clean:
	swift package clean
	rm -rf $(BUILD_DIR)
	rm -rf $(DMG_NAME)

# Install to Applications
install: release
	@echo "Installing to /Applications..."
	@cp -R "$(APP_BUNDLE)" "/Applications/"
	@echo "Installed successfully"

# Uninstall from Applications
uninstall:
	@echo "Uninstalling..."
	@rm -rf "/Applications/$(PRODUCT_NAME).app"
	@echo "Uninstalled successfully"

# Create DMG for distribution from a fresh release build
dmg: release create-dmg

# Create DMG from the current app bundle without rebuilding it.
# Used by notarize after signing so release does not overwrite signed code.
create-dmg:
	@echo "Creating DMG..."
	@./Scripts/create-dmg.sh
	@echo "DMG created: $(DMG_NAME)"

# Code sign the generated DMG for distribution.
sign-dmg: signing-identity-check
	@echo "Signing DMG..."
	@codesign --force --verify --verbose \
		--sign "$(SIGN_IDENTITY)" \
		"$(DMG_NAME)"

# Build a signed local DMG candidate without notarizing it.
signed-dmg: sign create-dmg sign-dmg

# Verify the generated DMG mounts to the expected drag-install surface.
dmg-install-check:
	@./Scripts/dmg-install-check.sh --dmg "$(DMG_NAME)"

# Verify the generated DMG contains the same app bundle currently under assessment.
dmg-artifact-match-check:
	@./Scripts/dmg-install-check.sh --app "$(APP_BUNDLE)" --dmg "$(DMG_NAME)"

# Verify public release metadata is truthful for the current distribution state.
release-metadata-check:
	@./Scripts/release-metadata-check.sh --app "$(APP_BUNDLE)" --repo "$(GITHUB_REPO)" --dmg "$(DMG_NAME)"

# Verify the selected Developer ID signing identity before spending time building.
signing-identity-check:
	@./Scripts/signing-identity-check.sh --sign-identity "$(SIGN_IDENTITY)"

# Verify notarization credentials before spending time building a release candidate.
notary-profile-check:
	@./Scripts/notary-profile-check.sh --notary-profile "$(NOTARY_PROFILE)"

# Code signing (requires valid Developer ID)
sign: signing-identity-check release
	@echo "Signing app bundle..."
	@codesign --deep --force --verify --verbose \
		--options runtime \
		--timestamp \
		--sign "$(SIGN_IDENTITY)" \
		"$(APP_BUNDLE)"

# Notarize for distribution (requires Apple Developer account)
notarize: notary-profile-check signing-identity-check signed-dmg
	@echo "Notarizing..."
	@xcrun notarytool submit $(DMG_NAME) \
		--keychain-profile "$(NOTARY_PROFILE)" \
		--wait
	@xcrun stapler staple $(DMG_NAME)

# Verify a signed, notarized, distribution-ready local artifact.
release-artifact-readiness:
	@./Scripts/release-readiness.sh --app "$(APP_BUNDLE)" --dmg "$(DMG_NAME)" --notary-profile "$(NOTARY_PROFILE)" --repo "$(GITHUB_REPO)" --skip-release-metadata

# Verify a signed, notarized, distribution-ready local artifact and stable release metadata.
release-readiness:
	@./Scripts/release-readiness.sh --app "$(APP_BUNDLE)" --dmg "$(DMG_NAME)" --notary-profile "$(NOTARY_PROFILE)" --repo "$(GITHUB_REPO)"

# Build, sign, notarize, staple, and verify the local release candidate artifact.
release-candidate: notarize release-artifact-readiness
