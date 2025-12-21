import Foundation

/// Defines how the cursor adapts to background colors
public enum ContrastMode: String, Codable, CaseIterable, Sendable {
    /// No contrast adaptation
    case none
    /// Automatically invert cursor color based on background brightness
    case autoInvert
    /// Add a contrasting outline around the cursor
    case outline
}

/// Pre-designed cursor themes
public enum CursorPreset: String, Codable, CaseIterable, Sendable {
    case custom      // User's own settings
    case neonGlow    // Vibrant with glow effect
    case stealth     // Dark, minimal, semi-transparent
    case highContrast // Bold black/white for accessibility
    case sunset      // Warm oranges/reds
    case ocean       // Cool blues/teals
    case mint        // Fresh green/cyan
    case lavender    // Soft purple tones
    case monochrome  // Clean grayscale

    public var displayName: String {
        switch self {
        case .custom: return "Custom"
        case .neonGlow: return "Neon Glow"
        case .stealth: return "Stealth"
        case .highContrast: return "High Contrast"
        case .sunset: return "Sunset"
        case .ocean: return "Ocean"
        case .mint: return "Mint"
        case .lavender: return "Lavender"
        case .monochrome: return "Monochrome"
        }
    }

    public var settings: PresetSettings {
        switch self {
        case .custom:
            return PresetSettings(
                color: .white,
                glowEnabled: false,
                glowColor: .white,
                glowRadius: 0,
                shadowEnabled: false,
                scale: 1.0
            )
        case .neonGlow:
            return PresetSettings(
                color: CursorColor(red: 0.0, green: 1.0, blue: 0.9),
                glowEnabled: true,
                glowColor: CursorColor(red: 0.0, green: 1.0, blue: 0.9),
                glowRadius: 8,
                shadowEnabled: false,
                scale: 1.0
            )
        case .stealth:
            return PresetSettings(
                color: CursorColor(red: 0.2, green: 0.2, blue: 0.2, alpha: 0.7),
                glowEnabled: false,
                glowColor: .black,
                glowRadius: 0,
                shadowEnabled: true,
                scale: 0.9
            )
        case .highContrast:
            return PresetSettings(
                color: .white,
                glowEnabled: false,
                glowColor: .white,
                glowRadius: 0,
                shadowEnabled: true,
                scale: 1.2
            )
        case .sunset:
            return PresetSettings(
                color: CursorColor(red: 1.0, green: 0.4, blue: 0.2),
                glowEnabled: true,
                glowColor: CursorColor(red: 1.0, green: 0.6, blue: 0.0),
                glowRadius: 5,
                shadowEnabled: false,
                scale: 1.0
            )
        case .ocean:
            return PresetSettings(
                color: CursorColor(red: 0.0, green: 0.6, blue: 0.9),
                glowEnabled: true,
                glowColor: CursorColor(red: 0.0, green: 0.8, blue: 1.0),
                glowRadius: 6,
                shadowEnabled: false,
                scale: 1.0
            )
        case .mint:
            return PresetSettings(
                color: CursorColor(red: 0.2, green: 0.9, blue: 0.7),
                glowEnabled: true,
                glowColor: CursorColor(red: 0.4, green: 1.0, blue: 0.8),
                glowRadius: 4,
                shadowEnabled: false,
                scale: 1.0
            )
        case .lavender:
            return PresetSettings(
                color: CursorColor(red: 0.7, green: 0.5, blue: 0.9),
                glowEnabled: true,
                glowColor: CursorColor(red: 0.8, green: 0.6, blue: 1.0),
                glowRadius: 5,
                shadowEnabled: false,
                scale: 1.0
            )
        case .monochrome:
            return PresetSettings(
                color: CursorColor(red: 0.9, green: 0.9, blue: 0.9),
                glowEnabled: false,
                glowColor: .white,
                glowRadius: 0,
                shadowEnabled: true,
                scale: 1.0
            )
        }
    }
}

/// Settings associated with a preset
public struct PresetSettings: Codable, Equatable, Sendable {
    public var color: CursorColor
    public var glowEnabled: Bool
    public var glowColor: CursorColor
    public var glowRadius: Float
    public var shadowEnabled: Bool
    public var scale: Float

    public init(
        color: CursorColor,
        glowEnabled: Bool,
        glowColor: CursorColor,
        glowRadius: Float,
        shadowEnabled: Bool,
        scale: Float
    ) {
        self.color = color
        self.glowEnabled = glowEnabled
        self.glowColor = glowColor
        self.glowRadius = max(0, min(20, glowRadius))
        self.shadowEnabled = shadowEnabled
        self.scale = max(0.5, min(2.0, scale))
    }
}

/// RGBA color representation for cursor customization
/// Fixes edge cases: #6 (HDR), #17/#18 (pure black/white), #22 (zero alpha), #23 (negative values)
public struct CursorColor: Codable, Equatable, Sendable {
    public var red: Float
    public var green: Float
    public var blue: Float
    public var alpha: Float

    public init(red: Float, green: Float, blue: Float, alpha: Float = 1.0) {
        // Edge case #23: Clamp negative values
        // Edge case #6: Clamp HDR values > 1.0 to standard range
        self.red = Self.clamp(red)
        self.green = Self.clamp(green)
        self.blue = Self.clamp(blue)
        // Edge case #22: Ensure minimum alpha for visibility
        self.alpha = max(Self.clamp(alpha), 0.1)
    }

    /// Clamp value to valid 0-1 range
    private static func clamp(_ value: Float) -> Float {
        return max(0, min(1, value))
    }

    public static let white = CursorColor(red: 1, green: 1, blue: 1)
    public static let black = CursorColor(red: 0, green: 0, blue: 0)

    /// Calculate perceived brightness (0-1) using relative luminance formula
    public var brightness: Float {
        // Using sRGB relative luminance coefficients
        return 0.2126 * red + 0.7152 * green + 0.0722 * blue
    }

    /// Returns the inverted color
    public var inverted: CursorColor {
        CursorColor(red: 1 - red, green: 1 - green, blue: 1 - blue, alpha: alpha)
    }

    /// Returns a contrasting color (black or white) based on brightness
    /// Edge cases #17/#18: Handle pure black and pure white properly
    public var contrasting: CursorColor {
        // Use WCAG contrast threshold (slightly above 0.5 for better readability)
        brightness > 0.45 ? .black : .white
    }

    /// Check if color is effectively black (edge case #17)
    public var isEffectivelyBlack: Bool {
        return brightness < 0.05
    }

    /// Check if color is effectively white (edge case #18)
    public var isEffectivelyWhite: Bool {
        return brightness > 0.95
    }

    /// Returns a color with guaranteed contrast against this color
    public func withGuaranteedContrast(minimumRatio: Float = 4.5) -> CursorColor {
        let contrastWithWhite = contrastRatio(against: .white)
        let contrastWithBlack = contrastRatio(against: .black)

        if contrastWithWhite >= minimumRatio {
            return .white
        } else if contrastWithBlack >= minimumRatio {
            return .black
        } else {
            // Neither provides enough contrast, return the better option
            return contrastWithWhite > contrastWithBlack ? .white : .black
        }
    }

    /// Calculate WCAG contrast ratio between two colors
    public func contrastRatio(against other: CursorColor) -> Float {
        let l1 = max(brightness, other.brightness)
        let l2 = min(brightness, other.brightness)
        return (l1 + 0.05) / (l2 + 0.05)
    }

    /// Interpolate between two colors
    public func interpolated(to other: CursorColor, amount: Float) -> CursorColor {
        let t = Self.clamp(amount)
        return CursorColor(
            red: red + (other.red - red) * t,
            green: green + (other.green - green) * t,
            blue: blue + (other.blue - blue) * t,
            alpha: alpha + (other.alpha - alpha) * t
        )
    }
}

/// All user-configurable settings for cursor customization
/// Fixes edge cases: #45 (corrupted data), #47 (migration), #48 (zero sampling), #49 (zero outline)
public struct CursorSettings: Codable, Equatable, Sendable {
    /// Schema version for migration support (edge case #47)
    public static let currentSchemaVersion = 2

    public var schemaVersion: Int
    public var isEnabled: Bool
    public var cursorColor: CursorColor
    public var contrastMode: ContrastMode
    public var outlineWidth: Float
    public var outlineColor: CursorColor?
    public var samplingRate: Int // Hz for background detection
    public var launchAtLogin: Bool

    // Advanced settings
    public var brightnessThreshold: Float // Edge case #14: configurable threshold
    public var hysteresis: Float // Edge case #14: prevent oscillation
    public var adaptiveScaling: Bool // Edge case #1: per-display scaling

    // New: Preset and visual effects
    public var preset: CursorPreset
    public var glowEnabled: Bool
    public var glowColor: CursorColor
    public var glowRadius: Float
    public var shadowEnabled: Bool
    public var cursorScale: Float

    public init(
        schemaVersion: Int = CursorSettings.currentSchemaVersion,
        isEnabled: Bool = true,
        cursorColor: CursorColor = .white,
        contrastMode: ContrastMode = .autoInvert,
        outlineWidth: Float = 2.0,
        outlineColor: CursorColor? = nil,
        samplingRate: Int = 60,
        launchAtLogin: Bool = false,
        brightnessThreshold: Float = 0.5,
        hysteresis: Float = 0.1,
        adaptiveScaling: Bool = true,
        preset: CursorPreset = .custom,
        glowEnabled: Bool = false,
        glowColor: CursorColor = .white,
        glowRadius: Float = 0,
        shadowEnabled: Bool = false,
        cursorScale: Float = 1.0
    ) {
        self.schemaVersion = schemaVersion
        self.isEnabled = isEnabled
        self.cursorColor = cursorColor
        self.contrastMode = contrastMode
        // Edge case #49: Ensure minimum outline width when outline mode is used
        self.outlineWidth = max(outlineWidth, 0.5)
        self.outlineColor = outlineColor
        // Edge case #48: Ensure valid sampling rate (15-120 Hz)
        self.samplingRate = max(15, min(120, samplingRate))
        self.launchAtLogin = launchAtLogin
        self.brightnessThreshold = max(0.1, min(0.9, brightnessThreshold))
        self.hysteresis = max(0.01, min(0.2, hysteresis))
        self.adaptiveScaling = adaptiveScaling
        self.preset = preset
        self.glowEnabled = glowEnabled
        self.glowColor = glowColor
        self.glowRadius = max(0, min(20, glowRadius))
        self.shadowEnabled = shadowEnabled
        self.cursorScale = max(0.5, min(2.0, cursorScale))
    }

    public static let defaults = CursorSettings()

    /// Apply a preset's settings
    public mutating func applyPreset(_ preset: CursorPreset) {
        self.preset = preset
        if preset != .custom {
            let presetSettings = preset.settings
            self.cursorColor = presetSettings.color
            self.glowEnabled = presetSettings.glowEnabled
            self.glowColor = presetSettings.glowColor
            self.glowRadius = presetSettings.glowRadius
            self.shadowEnabled = presetSettings.shadowEnabled
            self.cursorScale = presetSettings.scale
        }
    }

    /// Validate settings and fix any invalid values
    public mutating func validate() {
        outlineWidth = max(0.5, min(5.0, outlineWidth))
        samplingRate = max(15, min(120, samplingRate))
        brightnessThreshold = max(0.1, min(0.9, brightnessThreshold))
        hysteresis = max(0.01, min(0.2, hysteresis))
        glowRadius = max(0, min(20, glowRadius))
        cursorScale = max(0.5, min(2.0, cursorScale))
    }

    /// Create settings from potentially corrupted data with fallbacks (edge case #45)
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        // Decode with fallbacks for each field
        self.schemaVersion = (try? container.decode(Int.self, forKey: .schemaVersion)) ?? Self.currentSchemaVersion
        self.isEnabled = (try? container.decode(Bool.self, forKey: .isEnabled)) ?? true
        self.cursorColor = (try? container.decode(CursorColor.self, forKey: .cursorColor)) ?? .white
        self.contrastMode = (try? container.decode(ContrastMode.self, forKey: .contrastMode)) ?? .autoInvert
        self.outlineWidth = (try? container.decode(Float.self, forKey: .outlineWidth)) ?? 2.0
        self.outlineColor = try? container.decode(CursorColor?.self, forKey: .outlineColor)
        self.samplingRate = (try? container.decode(Int.self, forKey: .samplingRate)) ?? 60
        self.launchAtLogin = (try? container.decode(Bool.self, forKey: .launchAtLogin)) ?? false
        self.brightnessThreshold = (try? container.decode(Float.self, forKey: .brightnessThreshold)) ?? 0.5
        self.hysteresis = (try? container.decode(Float.self, forKey: .hysteresis)) ?? 0.1
        self.adaptiveScaling = (try? container.decode(Bool.self, forKey: .adaptiveScaling)) ?? true

        // New v2 fields with defaults for migration
        self.preset = (try? container.decode(CursorPreset.self, forKey: .preset)) ?? .custom
        self.glowEnabled = (try? container.decode(Bool.self, forKey: .glowEnabled)) ?? false
        self.glowColor = (try? container.decode(CursorColor.self, forKey: .glowColor)) ?? .white
        self.glowRadius = (try? container.decode(Float.self, forKey: .glowRadius)) ?? 0
        self.shadowEnabled = (try? container.decode(Bool.self, forKey: .shadowEnabled)) ?? false
        self.cursorScale = (try? container.decode(Float.self, forKey: .cursorScale)) ?? 1.0

        // Validate after loading
        validate()

        // Handle schema migration (edge case #47)
        if schemaVersion < Self.currentSchemaVersion {
            migrateFromVersion(schemaVersion)
        }
    }

    private mutating func migrateFromVersion(_ version: Int) {
        // Migration from v1 to v2: Add preset and visual effects
        if version < 2 {
            self.preset = .custom
            self.glowEnabled = false
            self.glowColor = .white
            self.glowRadius = 0
            self.shadowEnabled = false
            self.cursorScale = 1.0
        }
        self.schemaVersion = Self.currentSchemaVersion
    }

    private enum CodingKeys: String, CodingKey {
        case schemaVersion, isEnabled, cursorColor, contrastMode
        case outlineWidth, outlineColor, samplingRate, launchAtLogin
        case brightnessThreshold, hysteresis, adaptiveScaling
        case preset, glowEnabled, glowColor, glowRadius, shadowEnabled, cursorScale
    }
}
