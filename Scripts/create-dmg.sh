#!/bin/bash
set -e

PRODUCT_NAME="PointerDesigner"
APP_PATH=".build/release/${PRODUCT_NAME}.app"
DMG_NAME="${PRODUCT_NAME}.dmg"
DMG_TEMP="temp_${DMG_NAME}"
VOLUME_NAME="${PRODUCT_NAME}"
DMG_SIZE="50m"

echo "Creating DMG for ${PRODUCT_NAME}..."

# Check if app exists
if [ ! -d "$APP_PATH" ]; then
    echo "Error: App bundle not found at $APP_PATH"
    echo "Run 'make release' first"
    exit 1
fi

# Remove old DMG files
rm -f "$DMG_NAME" "$DMG_TEMP"

# Create temporary DMG
hdiutil create -srcfolder "$APP_PATH" \
    -volname "$VOLUME_NAME" \
    -fs HFS+ \
    -fsargs "-c c=64,a=16,e=16" \
    -format UDRW \
    -size "$DMG_SIZE" \
    "$DMG_TEMP"

# Mount the temporary DMG
DEVICE=$(hdiutil attach -readwrite -noverify -noautoopen "$DMG_TEMP" | \
    egrep '^/dev/' | sed 1q | awk '{print $1}')

MOUNT_POINT="/Volumes/$VOLUME_NAME"

# Wait for mount
sleep 2

# Create Applications symlink
ln -s /Applications "$MOUNT_POINT/Applications"

# Set custom background and icon positions (optional)
echo '
   tell application "Finder"
     tell disk "'${VOLUME_NAME}'"
           open
           set current view of container window to icon view
           set toolbar visible of container window to false
           set statusbar visible of container window to false
           set the bounds of container window to {400, 100, 900, 400}
           set viewOptions to the icon view options of container window
           set arrangement of viewOptions to not arranged
           set icon size of viewOptions to 72
           set position of item "'${PRODUCT_NAME}'.app" of container window to {125, 150}
           set position of item "Applications" of container window to {375, 150}
           close
           open
           update without registering applications
           delay 2
     end tell
   end tell
' | osascript || true

# Sync and unmount
sync
hdiutil detach "$DEVICE"

# Convert to compressed read-only DMG
hdiutil convert "$DMG_TEMP" \
    -format UDZO \
    -imagekey zlib-level=9 \
    -o "$DMG_NAME"

# Clean up
rm -f "$DMG_TEMP"

echo "DMG created: $DMG_NAME"
echo "Size: $(du -h "$DMG_NAME" | cut -f1)"
