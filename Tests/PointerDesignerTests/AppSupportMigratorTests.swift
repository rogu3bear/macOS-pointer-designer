import XCTest
@testable import PointerDesignerCore

// MARK: - Mock FileManager

final class MockFileManager: FileManaging {
    var existingPaths: Set<String> = []
    var directoryContents: [String: [URL]] = [:]  // directory path -> files in it
    var moveError: Error?
    var copyError: Error?
    var movedItems: [(from: URL, to: URL)] = []
    var copiedItems: [(from: URL, to: URL)] = []
    var removedItems: [URL] = []
    var createdDirectories: [URL] = []

    func fileExists(atPath path: String) -> Bool {
        return existingPaths.contains(path)
    }

    func moveItem(at srcURL: URL, to dstURL: URL) throws {
        if let error = moveError {
            throw error
        }
        movedItems.append((from: srcURL, to: dstURL))
        existingPaths.remove(srcURL.path)
        existingPaths.insert(dstURL.path)
    }

    func copyItem(at srcURL: URL, to dstURL: URL) throws {
        if let error = copyError {
            throw error
        }
        copiedItems.append((from: srcURL, to: dstURL))
        existingPaths.insert(dstURL.path)
    }

    func removeItem(at url: URL) throws {
        removedItems.append(url)
        existingPaths.remove(url.path)
    }

    func urls(for directory: FileManager.SearchPathDirectory, in domainMask: FileManager.SearchPathDomainMask) -> [URL] {
        // Not used when baseURL is provided
        return []
    }

    func contentsOfDirectory(at url: URL, includingPropertiesForKeys keys: [URLResourceKey]?, options mask: FileManager.DirectoryEnumerationOptions) throws -> [URL] {
        return directoryContents[url.path] ?? []
    }

    func createDirectory(at url: URL, withIntermediateDirectories createIntermediates: Bool, attributes: [FileAttributeKey: Any]?) throws {
        createdDirectories.append(url)
        existingPaths.insert(url.path)
    }

    /// Helper to set up a file in the mock filesystem
    func addFile(at path: String, inDirectory dirPath: String) {
        existingPaths.insert(path)
        let fileURL = URL(fileURLWithPath: path)
        if directoryContents[dirPath] == nil {
            directoryContents[dirPath] = []
        }
        directoryContents[dirPath]?.append(fileURL)
    }
}

// MARK: - Mock Logger

final class MockLogger: MigrationLogger {
    var messages: [String] = []

    func log(_ message: String) {
        messages.append(message)
    }
}

// MARK: - Test Error

enum TestError: Error, LocalizedError {
    case moveFailed
    case copyFailed

    var errorDescription: String? {
        switch self {
        case .moveFailed: return "Move operation failed"
        case .copyFailed: return "Copy operation failed"
        }
    }
}

// MARK: - AppSupportMigratorTests

final class AppSupportMigratorTests: XCTestCase {

    var mockFileManager: MockFileManager!
    var mockLogger: MockLogger!
    var baseURL: URL!
    var migrator: AppSupportMigrator!

    override func setUp() {
        super.setUp()
        mockFileManager = MockFileManager()
        mockLogger = MockLogger()
        baseURL = URL(fileURLWithPath: "/tmp/test-app-support")
    }

    override func tearDown() {
        mockFileManager = nil
        mockLogger = nil
        baseURL = nil
        migrator = nil
        super.tearDown()
    }

    private func createMigrator() -> AppSupportMigrator {
        return AppSupportMigrator(
            fileManager: mockFileManager,
            logger: mockLogger,
            baseURL: baseURL,
            oldDirName: "OldDir",
            newDirName: "NewDir"
        )
    }

    // MARK: - Basic Migration Tests

    func testOldExistsNewMissing_ReturnsMigrated() {
        // Setup: Old directory exists, new doesn't
        let oldPath = baseURL.appendingPathComponent("OldDir").path
        mockFileManager.existingPaths.insert(oldPath)

        let migrator = createMigrator()
        let result = migrator.migrate()

        XCTAssertEqual(result, .migrated)
        XCTAssertEqual(mockFileManager.movedItems.count, 1)
        XCTAssertTrue(mockLogger.messages.contains { $0.contains("Successfully moved") })
    }

    func testOldMissingNewExists_ReturnsNotNeeded() {
        // Setup: New directory exists, old doesn't
        let newPath = baseURL.appendingPathComponent("NewDir").path
        mockFileManager.existingPaths.insert(newPath)

        let migrator = createMigrator()
        let result = migrator.migrate()

        XCTAssertEqual(result, .notNeeded)
        XCTAssertEqual(mockFileManager.movedItems.count, 0)
        XCTAssertEqual(mockFileManager.copiedItems.count, 0)
    }

    func testNeitherExists_ReturnsNotNeeded() {
        // Setup: Neither directory exists
        let migrator = createMigrator()
        let result = migrator.migrate()

        XCTAssertEqual(result, .notNeeded)
        XCTAssertEqual(mockFileManager.movedItems.count, 0)
        XCTAssertEqual(mockFileManager.copiedItems.count, 0)
    }

    func testMoveFailsCopySucceeds_ReturnsCopied() {
        // Setup: Old directory exists, move will fail but copy succeeds
        let oldPath = baseURL.appendingPathComponent("OldDir").path
        mockFileManager.existingPaths.insert(oldPath)
        mockFileManager.moveError = TestError.moveFailed

        let migrator = createMigrator()
        let result = migrator.migrate()

        XCTAssertEqual(result, .copied)
        XCTAssertEqual(mockFileManager.movedItems.count, 0)
        XCTAssertEqual(mockFileManager.copiedItems.count, 1)
        XCTAssertTrue(mockLogger.messages.contains { $0.contains("Move failed") })
        XCTAssertTrue(mockLogger.messages.contains { $0.contains("Successfully copied") })
    }

    func testMoveFailsCopyFails_ReturnsFailed() {
        // Setup: Old directory exists, both move and copy fail
        let oldPath = baseURL.appendingPathComponent("OldDir").path
        mockFileManager.existingPaths.insert(oldPath)
        mockFileManager.moveError = TestError.moveFailed
        mockFileManager.copyError = TestError.copyFailed

        let migrator = createMigrator()
        let result = migrator.migrate()

        if case .failed(let message) = result {
            XCTAssertTrue(message.contains("Copy operation failed"))
        } else {
            XCTFail("Expected .failed result")
        }
        XCTAssertTrue(mockLogger.messages.contains { $0.contains("Copy also failed") })
    }

    func testSuccessfulCopyRemovesOldDirectory() {
        // Setup: Move fails, copy succeeds - old dir should be removed
        let oldPath = baseURL.appendingPathComponent("OldDir").path
        let oldURL = baseURL.appendingPathComponent("OldDir")
        mockFileManager.existingPaths.insert(oldPath)
        mockFileManager.moveError = TestError.moveFailed

        let migrator = createMigrator()
        _ = migrator.migrate()

        XCTAssertEqual(mockFileManager.removedItems.count, 1)
        XCTAssertEqual(mockFileManager.removedItems.first, oldURL)
    }

    func testMigrateIsIdempotent() {
        // Setup: Old directory exists
        let oldPath = baseURL.appendingPathComponent("OldDir").path
        mockFileManager.existingPaths.insert(oldPath)

        let migrator = createMigrator()

        // First migration
        let result1 = migrator.migrate()
        XCTAssertEqual(result1, .migrated)

        // Second migration (now new exists, old doesn't)
        let result2 = migrator.migrate()
        XCTAssertEqual(result2, .notNeeded)
    }

    // MARK: - Both Exist (Safe Merge) Tests

    func testBothExist_EmptyOld_ReturnsMergedZero() {
        // Setup: Both directories exist, old is empty
        let oldPath = baseURL.appendingPathComponent("OldDir").path
        let newPath = baseURL.appendingPathComponent("NewDir").path
        mockFileManager.existingPaths.insert(oldPath)
        mockFileManager.existingPaths.insert(newPath)
        mockFileManager.directoryContents[oldPath] = []  // Empty directory

        let migrator = createMigrator()
        let result = migrator.migrate()

        XCTAssertEqual(result, .merged(filesCopied: 0))
        XCTAssertTrue(mockLogger.messages.contains { $0.contains("safe merge") })
        XCTAssertTrue(mockLogger.messages.contains { $0.contains("No files needed merging") })
    }

    func testBothExist_UniqueFileInOld_ReturnsMergedOne() {
        // Setup: Both directories exist, old has a file not in new
        let oldPath = baseURL.appendingPathComponent("OldDir").path
        let newPath = baseURL.appendingPathComponent("NewDir").path
        mockFileManager.existingPaths.insert(oldPath)
        mockFileManager.existingPaths.insert(newPath)

        // Add session.json to old directory
        let sessionPath = baseURL.appendingPathComponent("OldDir/session.json").path
        mockFileManager.addFile(at: sessionPath, inDirectory: oldPath)

        let migrator = createMigrator()
        let result = migrator.migrate()

        XCTAssertEqual(result, .merged(filesCopied: 1))
        XCTAssertTrue(mockLogger.messages.contains { $0.contains("Merged file: session.json") })
        XCTAssertEqual(mockFileManager.copiedItems.count, 1)
    }

    func testBothExist_FileExistsInBoth_NeverOverwrites() {
        // Setup: Both directories exist, same file in both
        let oldPath = baseURL.appendingPathComponent("OldDir").path
        let newPath = baseURL.appendingPathComponent("NewDir").path
        mockFileManager.existingPaths.insert(oldPath)
        mockFileManager.existingPaths.insert(newPath)

        // Add same file to both
        let oldSessionPath = baseURL.appendingPathComponent("OldDir/session.json").path
        let newSessionPath = baseURL.appendingPathComponent("NewDir/session.json").path
        mockFileManager.addFile(at: oldSessionPath, inDirectory: oldPath)
        mockFileManager.existingPaths.insert(newSessionPath)  // File exists in new

        let migrator = createMigrator()
        let result = migrator.migrate()

        // Should not copy since file exists in new
        XCTAssertEqual(result, .merged(filesCopied: 0))
        XCTAssertEqual(mockFileManager.copiedItems.count, 0)
    }

    func testBothExist_MultipleFiles_MergesOnlyMissing() {
        // Setup: Old has 3 files, new has 1 of them
        let oldPath = baseURL.appendingPathComponent("OldDir").path
        let newPath = baseURL.appendingPathComponent("NewDir").path
        mockFileManager.existingPaths.insert(oldPath)
        mockFileManager.existingPaths.insert(newPath)

        // Files in old
        mockFileManager.addFile(
            at: baseURL.appendingPathComponent("OldDir/file1.txt").path,
            inDirectory: oldPath
        )
        mockFileManager.addFile(
            at: baseURL.appendingPathComponent("OldDir/file2.txt").path,
            inDirectory: oldPath
        )
        mockFileManager.addFile(
            at: baseURL.appendingPathComponent("OldDir/file3.txt").path,
            inDirectory: oldPath
        )

        // file2.txt already exists in new
        mockFileManager.existingPaths.insert(
            baseURL.appendingPathComponent("NewDir/file2.txt").path
        )

        let migrator = createMigrator()
        let result = migrator.migrate()

        // Should copy 2 files (file1 and file3, but not file2)
        XCTAssertEqual(result, .merged(filesCopied: 2))
        XCTAssertEqual(mockFileManager.copiedItems.count, 2)
    }

    func testBothExist_RemovesOldAfterMerge() {
        // Setup: Both exist with unique file
        let oldPath = baseURL.appendingPathComponent("OldDir").path
        let newPath = baseURL.appendingPathComponent("NewDir").path
        let oldURL = baseURL.appendingPathComponent("OldDir")
        mockFileManager.existingPaths.insert(oldPath)
        mockFileManager.existingPaths.insert(newPath)
        mockFileManager.directoryContents[oldPath] = []

        let migrator = createMigrator()
        _ = migrator.migrate()

        // Old directory should be removed after merge
        XCTAssertTrue(mockFileManager.removedItems.contains(oldURL))
        XCTAssertTrue(mockLogger.messages.contains { $0.contains("Removed old directory") })
    }

    // MARK: - Logger Tests

    func testLogsContainMigrationPath() {
        let oldPath = baseURL.appendingPathComponent("OldDir").path
        mockFileManager.existingPaths.insert(oldPath)

        let migrator = createMigrator()
        _ = migrator.migrate()

        XCTAssertTrue(mockLogger.messages.contains { $0.contains("Migrating from") })
    }

    // MARK: - Integration with Identity Constants

    func testDefaultMigratorUsesIdentityConstants() {
        // Verify the default migrator uses Identity constants
        // We can't easily test the internal state, but we can verify
        // the static method doesn't crash and returns a valid result
        let result = AppSupportMigrator.migrateIfNeeded()
        switch result {
        case .notNeeded, .migrated, .copied, .merged:
            break  // All valid results
        case .failed(let error):
            // Only fail test if it's an unexpected error
            XCTFail("Unexpected migration failure: \(error)")
        }
    }
}
