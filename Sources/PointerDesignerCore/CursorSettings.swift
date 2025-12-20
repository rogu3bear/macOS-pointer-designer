import Foundation

/// Defines how the cursor adapts to background colors
public enum ContrastMode: String, Codable, CaseIterable {
    /// No contrast adaptation
    case none
    /// Automatically invert cursor color based on background brightness
    case autoInvert
    /// Add a contrasting outline around the cursor
    case outline
}

/// RGBA color representation for cursor customization
public struct CursorColor: Codable, Equatable {
    public var red: Float
    public var green: Float
    public var blue: Float
    public var alpha: Float

    public init(red: Float, green: Float, blue: Float, alpha: Float = 1.0) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }

    public static let white = CursorColor(red: 1, green: 1, blue: 1)
    public static let black = CursorColor(red: 0, green: 0, blue: 0)

    /// Calculate perceived brightness (0-1)
    public var brightness: Float {
        // Using relative luminance formula
        return 0.299 * red + 0.587 * green + 0.114 * blue
    }

    /// Returns the inverted color
    public var inverted: CursorColor {
        CursorColor(red: 1 - red, green: 1 - green, blue: 1 - blue, alpha: alpha)
    }

    /// Returns a contrasting color (black or white) based on brightness
    public var contrasting: CursorColor {
        brightness > 0.5 ? .black : .white
    }
}

/// All user-configurable settings for cursor customization
public struct CursorSettings: Codable, Equatable {
    public var isEnabled: Bool
    public var cursorColor: CursorColor
    public var contrastMode: ContrastMode
    public var outlineWidth: Float
    public var outlineColor: CursorColor?
    public var samplingRate: Int // Hz for background detection
    public var launchAtLogin: Bool

    public init(
        isEnabled: Bool = true,
        cursorColor: CursorColor = .white,
        contrastMode: ContrastMode = .autoInvert,
        outlineWidth: Float = 2.0,
        outlineColor: CursorColor? = nil,
        samplingRate: Int = 60,
        launchAtLogin: Bool = false
    ) {
        self.isEnabled = isEnabled
        self.cursorColor = cursorColor
        self.contrastMode = contrastMode
        self.outlineWidth = outlineWidth
        self.outlineColor = outlineColor
        self.samplingRate = samplingRate
        self.launchAtLogin = launchAtLogin
    }

    public static let defaults = CursorSettings()
}
