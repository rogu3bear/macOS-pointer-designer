# Pointer Designer

System-wide macOS cursor customization with dynamic contrast adaptation.

## Features

- **Custom Cursor Colors**: Choose any color for your cursor
- **Auto-Invert Mode**: Cursor automatically adjusts based on background brightness
- **Outline Mode**: Add a contrasting outline that adapts to the background
- **Menu Bar App**: Quick access to settings from the menu bar
- **Launch at Login**: Optionally start with your Mac

## Requirements

- macOS 13.0 (Ventura) or later
- Apple Silicon or Intel Mac

## Installation

### Homebrew (Recommended)

```bash
brew tap rogu3bear/pointer-designer
brew install --cask pointer-designer
```

### Manual Installation

1. Download the latest [PointerDesigner.dmg](https://github.com/rogu3bear/macOS-pointer-designer/releases/latest)
2. Open the DMG file
3. Drag `PointerDesigner.app` to your Applications folder
4. Launch from Applications
5. Click "Install Helper Tool" when prompted (required for system-wide changes)

## Usage

### Menu Bar

Click the cursor icon in the menu bar to:
- Enable/disable cursor customization
- Switch between contrast modes
- Open preferences

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

## Building from Source

### Prerequisites

- Xcode 15.0+
- Swift 5.9+

### Build

```bash
# Clone the repository
git clone https://github.com/rogu3bear/macOS-pointer-designer.git
cd macOS-pointer-designer

# Build release
make release

# Run tests
make test

# Create DMG
make dmg
```

### Project Structure

```
macOS-pointer-designer/
├── Sources/
│   ├── PointerDesigner/         # Main app
│   │   ├── main.swift
│   │   ├── AppDelegate.swift
│   │   ├── MenuBarController.swift
│   │   └── PreferencesWindowController.swift
│   ├── PointerDesignerCore/     # Core library
│   │   ├── CursorEngine.swift
│   │   ├── CursorRenderer.swift
│   │   ├── CursorSettings.swift
│   │   ├── BackgroundColorDetector.swift
│   │   ├── SettingsManager.swift
│   │   ├── HelperToolManager.swift
│   │   └── LaunchAtLoginManager.swift
│   └── PointerDesignerHelper/   # Privileged helper
│       └── main.swift
├── Tests/
├── Scripts/
├── Casks/
├── Package.swift
└── Makefile
```

## How It Works

1. **Background Detection**: Uses `CGWindowListCreateImage` to sample screen colors at the cursor position
2. **Color Calculation**: Computes relative luminance to determine if background is light or dark
3. **Cursor Rendering**: Generates cursor images with CoreGraphics based on current settings
4. **System-Wide Application**: Helper tool applies cursor changes across all applications

## Privacy & Permissions

Pointer Designer requires:
- **Screen Recording**: To sample background colors (System Settings → Privacy & Security → Screen Recording)
- **Administrator Access**: One-time for helper tool installation

## Troubleshooting

### Cursor not changing system-wide
1. Ensure helper tool is installed (Preferences → Install Helper Tool)
2. Grant Screen Recording permission
3. Restart the app

### High CPU usage
- Lower the sampling rate in Preferences (default: 60 Hz)
- Use "None" contrast mode when dynamic adaptation isn't needed

## License

MIT License - see [LICENSE](LICENSE) for details.

## Contributing

Contributions welcome! Please read our contributing guidelines before submitting PRs.
