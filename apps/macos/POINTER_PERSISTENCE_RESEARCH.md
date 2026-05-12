# Cursor Persistence Research

Last reviewed: May 12, 2026.

This note explains why Cursor Designer's current custom cursor can return to the
default shape or orientation in some applications, and what a least-permission
fix should look like.

## Findings

1. `NSCursor.set()` is an AppKit cursor mechanism, not a durable system-wide
   pointer replacement contract. Apple documents `NSCursor.set()` as making the
   receiver the current cursor, and AppKit cursor rectangles/tracking areas are
   designed so the view under the pointer can set I-beam, hand, resize, and
   other cursors as the pointer crosses cursor regions.
2. The current implementation uses `NSCursor(image:hotSpot:)` and `cursor.set()`
   in `CursorEngine.applyCursor()`. That can work while Cursor Designer or one
   of its own cursor rects is controlling the pointer, but another application
   can legitimately replace the cursor as part of normal AppKit cursor-update
   handling.
3. A privileged helper is not automatically the right answer. The current helper
   scaffold correctly keeps `supportsSystemWidePointerReplacement == false`
   because a distribution-safe public API for replacing every system cursor has
   not been proven here. Private WindowServer/CGS cursor replacement should stay
   out of the release path unless a future tranche proves entitlement,
   notarization, rollback, and user-consent behavior.
4. The least-permission durable path starts with a supervised pointer
   presentation layer: a menu-bar agent that keeps the visible customization
   alive by observing pointer motion and app/display changes, then reapplying or
   drawing the custom pointer without installing a privileged helper. Mouse
   event observation can use AppKit global monitors for mouse events; Apple
   notes global monitors only observe events and cannot modify or prevent
   delivery.
5. Screen Recording is only justified for dynamic contrast/background sampling.
   It must not be requested for static color, static outline, settings, launch at
   login, or update checks.
6. Accessibility is only justified when Cursor Designer needs to control or read
   other applications through Accessibility APIs, monitor key-related events, or
   synthesize input. It should not be requested just to check for updates or to
   render the Preferences preview.
7. Update checks are network behavior and must be explicit. The app should only
   contact release metadata when the user enables internet access for update
   checks and presses a settings-menu update action. Future automatic updates
   should use a signed appcast/updater system such as Sparkle only after the same
   opt-in boundary is preserved.

## Recommended Architecture

Keep three separate capability layers:

- **AppKit preview layer**: no extra permission. Uses `NSCursor`, cursor rects,
  and Preferences preview. This is useful but not a system-wide persistence
  guarantee.
- **Pointer supervisor layer**: no privileged helper by default. Observes mouse,
  active-app, display, sleep/wake, and settings changes; keeps the chosen pointer
  presentation alive by reapplying the current cursor; degrades honestly in apps
  or modes it cannot control. If it later uses a click-through overlay, it must
  be reversible, local-only, and disabled before any password, secure input,
  screen saver, or full-screen edge case that proves unsafe.
- **Privileged/helper layer**: disabled until proven. Only enable after there is
  a public, notarizable, least-privilege mechanism with rollback, code-signing
  verification, and manual permission evidence. Do not ship private CGS or SIP
  workarounds as product behavior.

## Sources

- Apple Developer Documentation, `NSCursor.set()`: https://developer.apple.com/documentation/appkit/nscursor/set%28%29
- Apple Developer Documentation, `NSCursor`: https://developer.apple.com/documentation/appkit/nscursor
- Apple Cocoa Event Handling Guide, cursor-update events and cursor rectangles: https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/EventOverview/MouseTrackingEvents/MouseTrackingEvents.html
- Apple Cocoa Event Handling Guide, tracking areas and `cursorUpdate:`: https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/EventOverview/TrackingAreaObjects/TrackingAreaObjects.html
- Apple Developer Documentation, global event monitors: https://developer.apple.com/documentation/appkit/nsevent/addglobalmonitorforevents%28matching%3Ahandler:%29
- Apple Cocoa Event Handling Guide, global monitors cannot modify events and key monitoring needs Accessibility trust: https://developer.apple.com/library/archive/documentation/Cocoa/Conceptual/EventOverview/MonitoringEvents/MonitoringEvents.html
- Apple Developer Documentation, macOS sandbox outgoing network entitlement: https://developer.apple.com/documentation/bundleresources/entitlements/com.apple.security.network.client
- Sparkle documentation, programmatic updater setup and user-controlled update checks: https://sparkle-project.org/documentation/programmatic-setup/
