import Foundation

/// Manages persistence and retrieval of cursor settings
public final class SettingsManager {
    public static let shared = SettingsManager()

    private let userDefaults = UserDefaults.standard
    private let settingsKey = "com.pointerdesigner.settings"

    private var cachedSettings: CursorSettings?

    private init() {}

    /// Current settings, loaded from disk or defaults
    public var currentSettings: CursorSettings {
        if let cached = cachedSettings {
            return cached
        }

        guard let data = userDefaults.data(forKey: settingsKey),
              let settings = try? JSONDecoder().decode(CursorSettings.self, from: data) else {
            return .defaults
        }

        cachedSettings = settings
        return settings
    }

    /// Save settings to disk
    public func save(_ settings: CursorSettings) {
        cachedSettings = settings

        guard let data = try? JSONEncoder().encode(settings) else {
            return
        }

        userDefaults.set(data, forKey: settingsKey)
        userDefaults.synchronize()

        NotificationCenter.default.post(
            name: .settingsDidChange,
            object: nil,
            userInfo: ["settings": settings]
        )
    }

    /// Reset to default settings
    public func reset() {
        save(.defaults)
    }
}

public extension Notification.Name {
    static let settingsDidChange = Notification.Name("com.pointerdesigner.settingsDidChange")
}
