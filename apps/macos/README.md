# Cursor Designer

macOS cursor customization with dynamic contrast adaptation, persistent settings, and pointer-focused accessibility presets.

This package lives in `apps/macos` inside the Cursor Designer monorepo.

For the app-side production checklist, proof gates, and release blockers, see
[`REQUIREMENTS.md`](REQUIREMENTS.md).

## Features

- **Custom Cursor Colors**: Choose any color for your cursor
- **Auto-Invert Mode**: Cursor automatically adjusts based on background brightness
- **Outline Mode**: Add a contrasting outline that adapts to the background
- **Menu Bar App**: Quick access to settings from the menu bar
- **Launch at Login**: Optionally start with your Mac
- **Pointer Scope Status**: Shows whether this build enables any broader pointer replacement capability
- **Multi-Monitor Support**: Handles different DPI scales and refresh rates per display
- **Crash Recovery**: Tracks app session state and recovers cleanly after unexpected termination

## Requirements

- macOS 13.0 (Ventura) or later
- Apple Silicon or Intel Mac

## Installation Status

Cursor Designer is not advertised as a stable public download yet.

For local evaluation:

1. Build and verify the app from source with `make preflight`.
2. Create a local DMG with `make dmg`.
3. Open the generated `CursorDesigner.dmg`.
4. Drag `CursorDesigner.app` to your Applications folder.
5. Launch from Applications and open Preferences to choose pointer colors,
   presets, contrast behavior, and launch-at-login.

Do not treat Homebrew, signing, notarization, or public release downloads as
available until those paths are verified and documented here.

## Usage

### Menu Bar

Click the cursor icon in the menu bar to:
- Enable/disable cursor customization (Cmd+E)
- Switch between contrast modes (Cmd+1/2/3)
- Open preferences (Cmd+,)

### Contrast Modes

| Mode | Description |
|------|-------------|
| **None** | Use your chosen color without adaptation |
| **Auto-Invert** | Cursor lightens on dark backgrounds, darkens on light backgrounds |
| **Outline** | Adds a contrasting border around the cursor |

### Preferences

- **Cursor Color**: Pick your preferred cursor color
- **Contrast Mode**: Select adaptation behavior
- **Outline Width**: Adjust outline thickness (1-5px)
- **Sampling Rate**: Background detection frequency (15-120 Hz)
- **Pointer Scope**: Shows whether broader pointer replacement is enabled in this build
- **Launch at Login**: Start automatically with macOS

## Quick Start (Personal Use)

```bash
# Build
swift build

# Run the app
.build/debug/PointerDesigner

# Note: Executable names remain PointerDesigner/PointerDesignerHelper for compatibility
```

**Note**: The menu bar app and Preferences preview work without the helper. System-wide pointer replacement is not enabled in this build.

## Building from Source

### Prerequisites

- Xcode 15.0+
- Swift 5.9+

### Build

```bash
# Clone the monorepo
git clone https://github.com/rogu3bear/macOS-pointer-designer.git
cd macOS-pointer-designer/apps/macos

# Build with Swift Package Manager
swift build

# Run tests
swift test

# Build release
make release

# Create DMG
make dmg
```

### Project Structure

```
apps/macos/
├── Sources/
│   ├── PointerDesigner/           # Main app target (module name preserved)
│   │   ├── main.swift             # App entry point
│   │   ├── AppDelegate.swift      # App lifecycle, crash recovery, signal handlers
│   │   ├── MenuBarController.swift    # Menu bar UI and actions
│   │   └── PreferencesWindowController.swift  # Settings UI
│   │
│   ├── PointerDesignerCore/       # Core library (module name preserved)
│   │   ├── CursorSettings.swift       # Settings model with validation
│   │   ├── CursorEngine.swift         # Main engine: display link, cursor updates
│   │   ├── CursorRenderer.swift       # Renders cursor images with CoreGraphics
│   │   ├── BackgroundColorDetector.swift  # Samples screen colors
│   │   ├── DisplayManager.swift       # Multi-monitor handling, DPI, HDR detection
│   │   ├── PermissionManager.swift    # Screen recording permission checks
│   │   ├── SettingsManager.swift      # Persistence with backup/migration
│   │   ├── HelperToolManager.swift    # Capability-gated helper scaffold
│   │   ├── LaunchAtLoginManager.swift # SMAppService integration
│   │   └── SystemIntegrationManager.swift  # Sleep/wake, appearance changes
│   │
│   └── PointerDesignerHelper/     # Helper source scaffold (not packaged in current app builds)
│       └── main.swift             # Helper executable scaffold
│
├── Tests/
│   └── PointerDesignerTests/
│       ├── CursorSettingsTests.swift
│       ├── BackgroundColorDetectorTests.swift
│       └── EdgeCaseTests.swift
│
├── Package.swift
└── Makefile
```

## Architecture

### Application Flow

```
main.swift
    └── AppDelegate.applicationDidFinishLaunching()
        ├── ensureSingleInstance()      # Prevent duplicate instances
        ├── setupCrashRecovery()        # Register exception handler
        ├── setupSignalHandlers()       # SIGTERM/SIGINT handling
        ├── setupMenuBar()              # Create status item + menu
        ├── setupCursorEngine()         # Initialize core engine
        └── show pointer scope status in Preferences
```

### Core Engine Pipeline

```
CursorEngine.start()
    │
    ├── CVDisplayLink (vsync callback)
    │       ↓
    ├── processFrame()
    │   ├── Get mouse location (NSEvent.mouseLocation)
    │   ├── Convert coordinates (DisplayManager)
    │   └── Check movement threshold
    │           ↓
    ├── BackgroundColorDetector.sampleColor()
    │   ├── Check screen recording permission
    │   ├── CGWindowListCreateImage (sample 5x5 pixels)
    │   ├── Convert to sRGB color space
    │   ├── Apply flicker suppression
    │   └── Apply hysteresis (prevent oscillation)
    │           ↓
    ├── applyCursor()
    │   ├── Calculate effective color (based on ContrastMode)
    │   ├── CursorRenderer.renderCursor()
    │   │   ├── Check image cache
    │   │   ├── Create CGContext with correct scale
    │   │   ├── Draw cursor path with optional outline
    │   │   └── Cache rendered image
    │   ├── NSCursor.set() (in-app)
    │   └── HelperToolManager.setCursor() only when a supported helper capability is enabled
```

### Settings Persistence

```
SettingsManager
    ├── Primary storage: UserDefaults (JSON-encoded CursorSettings)
    ├── Backup storage: Separate key for crash recovery
    ├── Validation: Clamps values to valid ranges
    ├── Migration: Schema versioning for future updates
    └── Notifications: .settingsDidChange broadcast
```

## Edge Cases Handled

The application handles 70+ edge cases across these categories:

| Category | Examples |
|----------|----------|
| **Display** | Multi-monitor DPI, display hotplug, HDR color clamping, ProMotion refresh rates |
| **Color Detection** | Transparent windows, video flicker suppression, gradient detection, P3 wide gamut |
| **Cursor Rendering** | Outline width bounds, hot spot calculation, image caching, fallback cursor |
| **Performance** | Idle detection, rate limiting, memory pressure handling, background throttling |
| **System Integration** | Sleep/wake, permission prompts, launch at login, single instance |
| **Persistence** | Corrupted data recovery, file locking, schema migration, save verification |
| **Accessibility** | VoiceOver labels, keyboard navigation, contrast ratios (WCAG) |

## Privacy & Permissions

Cursor Designer requires:
- **Screen Recording**: To sample background colors (System Settings → Privacy & Security → Screen Recording)
- **Administrator Access**: Not required for the current app behavior. Do not grant admin access unless a future release clearly enables and explains a supported helper capability.

No data is collected or transmitted. All processing happens locally.

## Troubleshooting

### Dynamic contrast is not updating
1. Grant Screen Recording permission
2. Open Preferences and check the selected contrast mode
3. Lower the sampling rate if CPU usage is high
4. Restart the app if display state changed while the app was running

### High CPU usage
- Lower the sampling rate in Preferences (default: 60 Hz)
- Use "None" contrast mode when dynamic adaptation isn't needed

### Cursor flickers on videos
- The app includes flicker suppression for video content
- If issues persist, lower sampling rate to 30 Hz

### App crashed or settings look wrong
- Relaunch Cursor Designer to rebuild app session state
- Open Preferences, review the selected preset and contrast mode, then disable and re-enable customization if needed

## License

MIT License - see [LICENSE](LICENSE) for details.
