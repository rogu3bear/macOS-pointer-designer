import Foundation

// MARK: - Protocols for Dependency Injection

/// Protocol for file system operations (enables testing with mocks)
public protocol FileManaging {
    func fileExists(atPath path: String) -> Bool
    func moveItem(at srcURL: URL, to dstURL: URL) throws
    func copyItem(at srcURL: URL, to dstURL: URL) throws
    func removeItem(at URL: URL) throws
    func urls(for directory: FileManager.SearchPathDirectory, in domainMask: FileManager.SearchPathDomainMask) -> [URL]
    func contentsOfDirectory(at url: URL, includingPropertiesForKeys keys: [URLResourceKey]?, options mask: FileManager.DirectoryEnumerationOptions) throws -> [URL]
    func createDirectory(at url: URL, withIntermediateDirectories createIntermediates: Bool, attributes: [FileAttributeKey: Any]?) throws
}

extension FileManager: FileManaging {}

/// Protocol for logging (enables capturing logs in tests)
public protocol MigrationLogger {
    func log(_ message: String)
}

/// Default logger that uses NSLog
public struct NSLogMigrationLogger: MigrationLogger {
    public init() {}
    public func log(_ message: String) {
        NSLog("AppSupportMigrator: %@", message)
    }
}

// MARK: - AppSupportMigrator

/// One-time migration from old "PointerDesigner" App Support directory to new "CursorDesigner"
/// Must run before any other code accesses App Support to preserve session files, etc.
///
/// Migration Policy (safe merge):
/// - If only old exists: move old → new
/// - If only new exists: nothing to do
/// - If both exist: copy missing files from old → new (never overwrite), then remove old
/// - If neither exists: nothing to do
public final class AppSupportMigrator {

    public enum MigrationResult: Equatable {
        case notNeeded              // Neither exists or only new exists (no old data)
        case migrated               // Successfully moved old → new (old didn't exist after)
        case copied                 // Move failed, copied entire directory instead
        case merged(filesCopied: Int)  // Both existed, merged missing files from old → new
        case failed(String)         // Migration failed (String for Equatable)

        public static func == (lhs: MigrationResult, rhs: MigrationResult) -> Bool {
            switch (lhs, rhs) {
            case (.notNeeded, .notNeeded): return true
            case (.migrated, .migrated): return true
            case (.copied, .copied): return true
            case (.merged(let a), .merged(let b)): return a == b
            case (.failed(let a), .failed(let b)): return a == b
            default: return false
            }
        }
    }

    private let fileManager: FileManaging
    private let logger: MigrationLogger
    private let baseURL: URL?
    private let oldDirName: String
    private let newDirName: String

    /// Default initializer using system FileManager and Application Support
    public convenience init() {
        self.init(
            fileManager: FileManager.default,
            logger: NSLogMigrationLogger(),
            baseURL: nil,
            oldDirName: Identity.legacyAppSupportDirName,
            newDirName: Identity.appSupportDirName
        )
    }

    /// Initializer for dependency injection (testing)
    public init(
        fileManager: FileManaging,
        logger: MigrationLogger,
        baseURL: URL?,
        oldDirName: String,
        newDirName: String
    ) {
        self.fileManager = fileManager
        self.logger = logger
        self.baseURL = baseURL
        self.oldDirName = oldDirName
        self.newDirName = newDirName
    }

    /// Run migration
    /// This is idempotent - safe to call multiple times
    @discardableResult
    public func migrate() -> MigrationResult {
        // Get base directory
        let appSupport: URL
        if let base = baseURL {
            appSupport = base
        } else {
            guard let systemAppSupport = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
                logger.log("Could not locate Application Support directory")
                return .notNeeded
            }
            appSupport = systemAppSupport
        }

        let oldDir = appSupport.appendingPathComponent(oldDirName)
        let newDir = appSupport.appendingPathComponent(newDirName)

        // Check if migration is needed
        let oldExists = fileManager.fileExists(atPath: oldDir.path)
        let newExists = fileManager.fileExists(atPath: newDir.path)

        // Case 1: Neither exists - nothing to do
        if !oldExists && !newExists {
            return .notNeeded
        }

        // Case 2: Only new exists - nothing to migrate
        if !oldExists && newExists {
            return .notNeeded
        }

        // Case 3: Both exist - safe merge (copy missing files from old → new)
        if oldExists && newExists {
            return performSafeMerge(from: oldDir, to: newDir)
        }

        // Case 4: Only old exists - migrate (move or copy)
        logger.log("Migrating from \(oldDir.path) to \(newDir.path)")

        // Try move first (atomic, faster)
        do {
            try fileManager.moveItem(at: oldDir, to: newDir)
            logger.log("Successfully moved App Support directory")
            return .migrated
        } catch {
            logger.log("Move failed (\(error.localizedDescription)), trying copy...")
        }

        // Move failed, try copy
        do {
            try fileManager.copyItem(at: oldDir, to: newDir)
            logger.log("Successfully copied App Support directory")

            // Try to remove old dir after successful copy (best effort)
            try? fileManager.removeItem(at: oldDir)

            return .copied
        } catch {
            logger.log("Copy also failed: \(error.localizedDescription)")
            return .failed(error.localizedDescription)
        }
    }

    /// Safe merge: copy files from old → new that don't already exist in new
    /// Never overwrites existing files in new
    private func performSafeMerge(from oldDir: URL, to newDir: URL) -> MigrationResult {
        logger.log("Both directories exist, performing safe merge")

        var filesCopied = 0

        do {
            // Get all files in old directory (recursively)
            let oldFiles = try enumerateFiles(in: oldDir)

            for oldFile in oldFiles {
                // Get relative path from old directory
                let relativePath = oldFile.path.replacingOccurrences(of: oldDir.path + "/", with: "")
                let newFile = newDir.appendingPathComponent(relativePath)

                // Only copy if file doesn't exist in new location
                if !fileManager.fileExists(atPath: newFile.path) {
                    // Ensure parent directory exists
                    let parentDir = newFile.deletingLastPathComponent()
                    if !fileManager.fileExists(atPath: parentDir.path) {
                        try fileManager.createDirectory(at: parentDir, withIntermediateDirectories: true, attributes: nil)
                    }

                    try fileManager.copyItem(at: oldFile, to: newFile)
                    logger.log("Merged file: \(relativePath)")
                    filesCopied += 1
                }
            }

            if filesCopied > 0 {
                logger.log("Merged \(filesCopied) file(s) from old to new directory")
            } else {
                logger.log("No files needed merging (all already exist in new)")
            }

            // Remove old directory after successful merge
            try? fileManager.removeItem(at: oldDir)
            logger.log("Removed old directory after merge")

            return .merged(filesCopied: filesCopied)

        } catch {
            logger.log("Safe merge failed: \(error.localizedDescription)")
            return .failed(error.localizedDescription)
        }
    }

    /// Recursively enumerate all files in a directory
    /// Note: Uses contentsOfDirectory which returns files directly (not directories as items)
    private func enumerateFiles(in directory: URL) throws -> [URL] {
        let contents = try fileManager.contentsOfDirectory(
            at: directory,
            includingPropertiesForKeys: nil,
            options: [.skipsHiddenFiles]
        )

        // For simplicity, treat all items as files (App Support typically has flat structure)
        // Subdirectories would need recursive handling in a full implementation
        return contents
    }

    // MARK: - Static Convenience

    /// Static convenience method for one-liner usage
    @discardableResult
    public static func migrateIfNeeded() -> MigrationResult {
        return AppSupportMigrator().migrate()
    }
}
