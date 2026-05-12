.PHONY: all build release clean test install uninstall dmg create-dmg preflight dmg-install-check release-readiness

PRODUCT_NAME = CursorDesigner
BUILD_DIR = .build
RELEASE_DIR = $(BUILD_DIR)/release
APP_BUNDLE = $(RELEASE_DIR)/$(PRODUCT_NAME).app
DMG_NAME = $(PRODUCT_NAME).dmg
SIGN_IDENTITY ?= Developer ID Application
NOTARY_PROFILE ?= notarization

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

# Verify the generated DMG mounts to the expected drag-install surface.
dmg-install-check:
	@./Scripts/dmg-install-check.sh --dmg "$(DMG_NAME)"

# Code signing (requires valid Developer ID)
sign: release
	@echo "Signing app bundle..."
	@codesign --deep --force --verify --verbose \
		--sign "$(SIGN_IDENTITY)" \
		"$(APP_BUNDLE)"

# Notarize for distribution (requires Apple Developer account)
notarize: sign create-dmg
	@echo "Notarizing..."
	@xcrun notarytool submit $(DMG_NAME) \
		--keychain-profile "$(NOTARY_PROFILE)" \
		--wait
	@xcrun stapler staple $(DMG_NAME)

# Verify a signed, notarized, distribution-ready local artifact.
release-readiness: dmg-install-check
	@./Scripts/release-readiness.sh --app "$(APP_BUNDLE)" --dmg "$(DMG_NAME)" --notary-profile "$(NOTARY_PROFILE)"
