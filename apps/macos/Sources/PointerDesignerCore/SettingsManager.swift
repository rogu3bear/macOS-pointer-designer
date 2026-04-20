import Foundation

/// Manages persistence and retrieval of cursor settings
/// Fixes edge cases: #45 (corrupted data), #46 (file locked), #47 (migration), #50 (error handling)
public final class SettingsManager: SettingsService {
    public static let shared = SettingsManager()

    private let userDefaults = UserDefaults.standard
    private let settingsKey = Identity.settingsKey
    private let backupKey = Identity.settingsBackupKey

    private var cachedSettings: CursorSettings?
    private let lock = NSLock()

    // Edge case #46: Track save failures
    private var consecutiveSaveFailures = 0
    private let maxSaveRetries = 3

    private init() {
        // Edge case #47: Perform migration on init if needed
        migrateIfNeeded()
    }

    /// Current settings, loaded from disk or defaults
    /// Edge case #45: Safe loading with fallbacks
    public var currentSettings: CursorSettings {
        lock.lock()
        defer { lock.unlock() }

        if let cached = cachedSettings {
            return cached
        }

        // Try to load settings
        if let settings = loadSettings() {
            cachedSettings = settings
            return settings
        }

        // Edge case #45: Try backup if primary is corrupted
        if let backup = loadBackupSettings() {
            cachedSettings = backup
            // Restore backup to primary
            saveToUserDefaults(backup)
            return backup
        }

        // Return defaults if all else fails
        return .defaults
    }

    /// Save settings to disk
    /// Edge case #46: Handle save failures with retry
    public func save(_ settings: CursorSettings) {
        lock.lock()

        var settingsToSave = settings
        settingsToSave.validate()
        cachedSettings = settingsToSave

        lock.unlock()

        // Attempt save with retry logic
        var saved = false
        for attempt in 0..<maxSaveRetries {
            if saveToUserDefaults(settingsToSave) {
                saved = true
                consecutiveSaveFailures = 0

                // Also save backup (edge case #45)
                saveBackup(settingsToSave)
                break
            }

            // Edge case #46: Brief delay before retry using RunLoop (non-blocking)
            if attempt < maxSaveRetries - 1 {
                RunLoop.current.run(until: Date().addingTimeInterval(0.1))
            }
        }

        if !saved {
            consecutiveSaveFailures += 1
            // Edge case #50: Post notification about save failure
            NotificationCenter.default.post(
                name: .settingsSaveFailed,
                object: nil,
                userInfo: ["failures": consecutiveSaveFailures]
            )
        }

        NotificationCenter.default.post(
            name: .settingsDidChange,
            object: nil,
            userInfo: ["settings": settingsToSave]
        )
    }

    /// Reset to default settings
    public func reset() {
        save(.defaults)
    }

    /// Force reload from disk
    public func reload() {
        lock.lock()
        cachedSettings = nil
        lock.unlock()
        _ = currentSettings
    }

    /// Export settings to Data for backup
    public func exportSettings() -> Data? {
        let settings = currentSettings
        return try? JSONEncoder().encode(settings)
    }

    /// Import settings from Data
    /// Edge case #45: Validate before importing
    public func importSettings(from data: Data) -> Bool {
        do {
            var settings = try JSONDecoder().decode(CursorSettings.self, from: data)
            settings.validate()
            save(settings)
            return true
        } catch {
            return false
        }
    }

    // MARK: - Private Persistence

    private func loadSettings() -> CursorSettings? {
        guard let data = userDefaults.data(forKey: settingsKey) else {
            return nil
        }

        // Edge case #45: Use try? to handle corrupted data gracefully
        do {
            var settings = try JSONDecoder().decode(CursorSettings.self, from: data)
            settings.validate()
            return settings
        } catch {
            // Log error but don't crash
            print("CursorDesigner: Failed to decode settings: \(error)")
            return nil
        }
    }

    private func loadBackupSettings() -> CursorSettings? {
        guard let data = userDefaults.data(forKey: backupKey) else {
            return nil
        }

        return try? JSONDecoder().decode(CursorSettings.self, from: data)
    }

    @discardableResult
    private func saveToUserDefaults(_ settings: CursorSettings) -> Bool {
        do {
            let data = try JSONEncoder().encode(settings)
            userDefaults.set(data, forKey: settingsKey)

            // Edge case #46: Force synchronize and verify
            userDefaults.synchronize()

            // Verify save succeeded
            if let savedData = userDefaults.data(forKey: settingsKey),
               savedData == data {
                return true
            }

            return false
        } catch {
            print("CursorDesigner: Failed to encode settings: \(error)")
            return false
        }
    }

    private func saveBackup(_ settings: CursorSettings) {
        guard let data = try? JSONEncoder().encode(settings) else { return }
        userDefaults.set(data, forKey: backupKey)
    }

    // MARK: - Migration (Edge case #47)

    private func migrateIfNeeded() {
        // Check for old settings format
        migrateFromV0IfNeeded()
    }

    private func migrateFromV0IfNeeded() {
        // Example: Migrate from old individual keys to unified settings object
        let oldColorKey = Identity.legacyCursorColorKey
        let oldEnabledKey = Identity.legacyEnabledKey

        // Check if old format exists
        guard userDefaults.object(forKey: oldColorKey) != nil ||
              userDefaults.object(forKey: oldEnabledKey) != nil else {
            return
        }

        // Migration not needed if new format already exists
        if userDefaults.data(forKey: settingsKey) != nil {
            // Clean up old keys
            userDefaults.removeObject(forKey: oldColorKey)
            userDefaults.removeObject(forKey: oldEnabledKey)
            return
        }

        // Build settings from old format
        var settings = CursorSettings.defaults

        if let enabled = userDefaults.object(forKey: oldEnabledKey) as? Bool {
            settings.isEnabled = enabled
        }

        // Save in new format
        save(settings)

        // Clean up old keys
        userDefaults.removeObject(forKey: oldColorKey)
        userDefaults.removeObject(forKey: oldEnabledKey)

        print("CursorDesigner: Migrated settings from v0 format")
    }

    // MARK: - Diagnostics

    /// Get settings storage status for debugging
    public var storageStatus: [String: Any] {
        return [
            "hasPrimarySettings": userDefaults.data(forKey: settingsKey) != nil,
            "hasBackupSettings": userDefaults.data(forKey: backupKey) != nil,
            "consecutiveSaveFailures": consecutiveSaveFailures,
            "settingsSchemaVersion": currentSettings.schemaVersion
        ]
    }
}

// MARK: - Notifications

public extension Notification.Name {
    static let settingsDidChange = Notification.Name(Identity.settingsDidChangeNotification)
    static let settingsSaveFailed = Notification.Name(Identity.settingsSaveFailedNotification)
}
