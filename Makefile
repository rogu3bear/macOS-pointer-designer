.PHONY: all build release clean test install uninstall dmg

PRODUCT_NAME = PointerDesigner
BUILD_DIR = .build
RELEASE_DIR = $(BUILD_DIR)/release
APP_BUNDLE = $(RELEASE_DIR)/$(PRODUCT_NAME).app
DMG_NAME = $(PRODUCT_NAME).dmg

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
	@mkdir -p "$(APP_BUNDLE)/Contents/Library/LaunchServices"

	# Copy main executable
	@cp "$(BUILD_DIR)/apple/Products/Release/PointerDesigner" "$(APP_BUNDLE)/Contents/MacOS/"

	# Copy helper tool
	@cp "$(BUILD_DIR)/apple/Products/Release/PointerDesignerHelper" "$(APP_BUNDLE)/Contents/Library/LaunchServices/com.pointerdesigner.helper"

	# Copy resources
	@cp "Sources/PointerDesigner/Resources/Info.plist" "$(APP_BUNDLE)/Contents/"
	@cp "Sources/PointerDesigner/Resources/com.pointerdesigner.helper.plist" "$(APP_BUNDLE)/Contents/Library/LaunchServices/"

	@echo "App bundle created at $(APP_BUNDLE)"

# Run tests
test:
	swift test

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
	@rm -f "/Library/PrivilegedHelperTools/com.pointerdesigner.helper"
	@rm -f "/Library/LaunchDaemons/com.pointerdesigner.helper.plist"
	@echo "Uninstalled successfully"

# Create DMG for distribution
dmg: release
	@echo "Creating DMG..."
	@./Scripts/create-dmg.sh
	@echo "DMG created: $(DMG_NAME)"

# Code signing (requires valid Developer ID)
sign: release
	@echo "Signing app bundle..."
	@codesign --deep --force --verify --verbose \
		--sign "Developer ID Application" \
		"$(APP_BUNDLE)"
	@echo "Signing helper tool..."
	@codesign --force --verify --verbose \
		--sign "Developer ID Application" \
		"$(APP_BUNDLE)/Contents/Library/LaunchServices/com.pointerdesigner.helper"

# Notarize for distribution (requires Apple Developer account)
notarize: sign dmg
	@echo "Notarizing..."
	@xcrun notarytool submit $(DMG_NAME) \
		--keychain-profile "notarization" \
		--wait
	@xcrun stapler staple $(DMG_NAME)
