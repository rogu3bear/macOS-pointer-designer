# Cursor Designer

System-wide macOS cursor customization with dynamic contrast adaptation.

## Features

- **Custom Cursor Colors**: Choose any color for your cursor
- **Auto-Invert Mode**: Cursor automatically adjusts based on background brightness
- **Outline Mode**: Add a contrasting outline that adapts to the background
- **Menu Bar App**: Quick access to settings from the menu bar
- **Launch at Login**: Optionally start with your Mac
- **Multi-Monitor Support**: Handles different DPI scales and refresh rates per display
- **Crash Recovery**: Automatically restores system cursor if app terminates unexpectedly

## Requirements

- macOS 13.0 (Ventura) or later
- Apple Silicon or Intel Mac

## Installation

### Homebrew (Recommended)

```bash
brew tap rogu3bear/cursor-designer-osx
brew install --cask cursor-designer-osx
```

### Manual Installation

1. Download the latest [CursorDesigner.dmg](https://github.com/rogu3bear/cursor-designer-osx/releases/latest)
2. Open the DMG file
3. Drag `CursorDesigner.app` to your Applications folder
4. Launch from Applications
5. Click "Install Helper Tool" when prompted (required for system-wide changes)

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
- **Launch at Login**: Start automatically with macOS

## Quick Start (Personal Use)

```bash
# Build
swift build

# Run the app
.build/debug/PointerDesigner

# Run the helper (in separate terminal, may need sudo)
.build/debug/PointerDesignerHelper

# Note: Executable names remain PointerDesigner/PointerDesignerHelper for compatibility
```

**Note**: For system-wide cursor changes, the helper needs to run. For personal use, the app is configured to accept local connections without code signing verification.

## Building from Source

### Prerequisites

- Xcode 15.0+
- Swift 5.9+

### Build

```bash
# Clone the repository
git clone https://github.com/rogu3bear/cursor-designer-osx.git
cd cursor-designer-osx

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
cursor-designer-osx/
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
│   │   ├── HelperToolManager.swift    # XPC communication with helper
│   │   ├── LaunchAtLoginManager.swift # SMAppService integration
│   │   └── SystemIntegrationManager.swift  # Sleep/wake, appearance changes
│   │
│   └── PointerDesignerHelper/     # Privileged helper (module name preserved)
│       └── main.swift             # System-wide cursor application
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
        └── checkHelperToolInstallation()
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
    │   └── HelperToolManager.setCursor() (system-wide via XPC)
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
- **Administrator Access**: One-time for helper tool installation

No data is collected or transmitted. All processing happens locally.

## Troubleshooting

### Cursor not changing system-wide
1. Ensure helper tool is installed (Preferences → Install Helper Tool)
2. Grant Screen Recording permission
3. Restart the app

### High CPU usage
- Lower the sampling rate in Preferences (default: 60 Hz)
- Use "None" contrast mode when dynamic adaptation isn't needed

### Cursor flickers on videos
- The app includes flicker suppression for video content
- If issues persist, lower sampling rate to 30 Hz

### App crashed and cursor is stuck
- The app tracks cursor state and will restore it on next launch
- Force quit and relaunch to trigger recovery

## License

MIT License - see [LICENSE](LICENSE) for details.

## Contributing

Contributions welcome! Please read our contributing guidelines before submitting PRs.
