import XCTest
@testable import PointerDesignerCore

// MARK: - SignalHandler Tests

final class SignalHandlerTests: XCTestCase {
    var signalHandler: SignalHandler!

    override func setUp() {
        super.setUp()
        signalHandler = SignalHandler()
    }

    override func tearDown() {
        signalHandler.stop()
        signalHandler.removeAllCallbacks()
        super.tearDown()
    }

    func testStartSetsUpSignalHandling() {
        signalHandler.start()
        // Starting twice should be idempotent
        signalHandler.start()
        signalHandler.stop()
    }

    func testStopIsIdempotent() {
        signalHandler.stop()
        signalHandler.stop()
    }

    func testCallbackRegistration() {
        var callbackInvoked = false
        signalHandler.onSignal { _ in
            callbackInvoked = true
        }
        // Can't easily test signal delivery, but we can verify registration doesn't crash
        XCTAssertFalse(callbackInvoked) // Not invoked until signal received
    }

    func testRemoveAllCallbacks() {
        signalHandler.onSignal { _ in }
        signalHandler.onSignal { _ in }
        signalHandler.removeAllCallbacks()
        // Should not crash
    }
}

// MARK: - SingleInstanceGuard Tests

final class SingleInstanceGuardTests: XCTestCase {

    func testCheckReturnsOkWhenNoOtherInstance() {
        // Create guard with mock workspace that returns only current process
        let mockWorkspace = MockWorkspace(runningApps: [])
        let guard_ = SingleInstanceGuard(
            workspace: mockWorkspace,
            bundleIdentifier: "com.test.app",
            currentPID: 12345
        )

        let result = guard_.check()
        if case .ok = result {
            // Expected
        } else {
            XCTFail("Expected .ok result")
        }
    }

    func testCheckReturnsAlreadyRunningWhenDuplicateExists() {
        let mockApp = MockRunningApplication(bundleIdentifier: "com.test.app", processIdentifier: 99999)
        let mockWorkspace = MockWorkspace(runningApps: [mockApp])

        let guard_ = SingleInstanceGuard(
            workspace: mockWorkspace,
            bundleIdentifier: "com.test.app",
            currentPID: 12345 // Different PID
        )

        let result = guard_.check()
        if case .alreadyRunning(let existingApp) = result {
            XCTAssertEqual(existingApp.processIdentifier, 99999)
        } else {
            XCTFail("Expected .alreadyRunning result")
        }
    }

    func testCheckIgnoresCurrentProcess() {
        let currentPID: pid_t = 12345
        let mockApp = MockRunningApplication(bundleIdentifier: "com.test.app", processIdentifier: currentPID)
        let mockWorkspace = MockWorkspace(runningApps: [mockApp])

        let guard_ = SingleInstanceGuard(
            workspace: mockWorkspace,
            bundleIdentifier: "com.test.app",
            currentPID: currentPID // Same PID
        )

        let result = guard_.check()
        if case .ok = result {
            // Expected - should ignore self
        } else {
            XCTFail("Expected .ok result when only current process is running")
        }
    }

    func testEnsureSingleInstanceReturnsTrueWhenOk() {
        let mockWorkspace = MockWorkspace(runningApps: [])
        let guard_ = SingleInstanceGuard(
            workspace: mockWorkspace,
            bundleIdentifier: "com.test.app",
            currentPID: 12345
        )

        XCTAssertTrue(guard_.ensureSingleInstance(showAlert: false))
    }

    func testEnsureSingleInstanceReturnsFalseWhenDuplicate() {
        let mockApp = MockRunningApplication(bundleIdentifier: "com.test.app", processIdentifier: 99999)
        let mockWorkspace = MockWorkspace(runningApps: [mockApp])

        let guard_ = SingleInstanceGuard(
            workspace: mockWorkspace,
            bundleIdentifier: "com.test.app",
            currentPID: 12345
        )

        XCTAssertFalse(guard_.ensureSingleInstance(showAlert: false))
    }
}

// MARK: - OrphanCleaner Tests

final class OrphanCleanerTests: XCTestCase {

    func testCleanupAsyncCompletesWithResult() {
        let cleaner = OrphanCleaner(
            processName: "NonExistentProcess12345",
            currentPID: ProcessInfo.processInfo.processIdentifier
        )

        let expectation = expectation(description: "Cleanup completes")

        cleaner.cleanupAsync { result in
            XCTAssertEqual(result.processesFound, 0)
            XCTAssertEqual(result.processesKilled, 0)
            XCTAssertTrue(result.errors.isEmpty)
            expectation.fulfill()
        }

        waitForExpectations(timeout: 5.0)
    }

    func testCleanupSyncReturnsResult() {
        let cleaner = OrphanCleaner(
            processName: "NonExistentProcess12345",
            currentPID: ProcessInfo.processInfo.processIdentifier
        )

        let result = cleaner.cleanupSync()
        XCTAssertEqual(result.processesFound, 0)
        XCTAssertEqual(result.processesKilled, 0)
    }

    func testCleanerDoesNotKillCurrentProcess() {
        // Use a process name that might match current process
        let cleaner = OrphanCleaner(
            processName: "xctest",
            currentPID: ProcessInfo.processInfo.processIdentifier
        )

        let result = cleaner.cleanupSync()
        // Should not have killed ourselves
        XCTAssertTrue(result.errors.isEmpty || result.processesKilled == 0)
    }
}

// MARK: - CrashRecoveryManager Tests

final class CrashRecoveryManagerTests: XCTestCase {
    var tempDir: String!
    var sessionFilePath: String!
    var crashManager: CrashRecoveryManager!

    override func setUp() {
        super.setUp()
        tempDir = NSTemporaryDirectory()
        sessionFilePath = (tempDir as NSString).appendingPathComponent("test.session.\(UUID().uuidString).json")
        crashManager = CrashRecoveryManager(sessionFilePath: sessionFilePath, fileManager: .default)
    }

    override func tearDown() {
        try? FileManager.default.removeItem(atPath: sessionFilePath)
        super.tearDown()
    }

    func testCheckForCrashReturnsNoPreviousSessionWhenNoFile() {
        let result = crashManager.checkForCrash()
        if case .noPreviousSession = result {
            // Expected
        } else {
            XCTFail("Expected .noPreviousSession")
        }
    }

    func testStartSessionCreatesFile() {
        crashManager.startSession()
        XCTAssertTrue(FileManager.default.fileExists(atPath: sessionFilePath))
    }

    func testEndSessionRemovesFile() {
        crashManager.startSession()
        XCTAssertTrue(FileManager.default.fileExists(atPath: sessionFilePath))

        crashManager.endSession()
        XCTAssertFalse(FileManager.default.fileExists(atPath: sessionFilePath))
    }

    func testMarkCursorActiveUpdatesSession() {
        crashManager.startSession()
        crashManager.markCursorActive(true)

        // Read the session file and verify
        if let data = FileManager.default.contents(atPath: sessionFilePath),
           let session = try? JSONDecoder().decode(CrashRecoveryManager.SessionInfo.self, from: data) {
            XCTAssertTrue(session.cursorWasActive)
        } else {
            XCTFail("Could not read session file")
        }
    }

    func testCheckForCrashDetectsStalePID() {
        // Write a session with a PID that definitely doesn't exist
        let staleSession = CrashRecoveryManager.SessionInfo(
            pid: 99999999, // Very unlikely to exist
            startTime: Date(),
            cursorWasActive: true
        )

        if let data = try? JSONEncoder().encode(staleSession) {
            try? data.write(to: URL(fileURLWithPath: sessionFilePath))
        }

        let result = crashManager.checkForCrash()
        if case .crashDetected(let session) = result {
            XCTAssertEqual(session.pid, 99999999)
            XCTAssertTrue(session.cursorWasActive)
        } else {
            XCTFail("Expected .crashDetected")
        }
    }

    func testRecoverIfNeededReturnsFalseWhenNoSession() {
        let recovered = crashManager.recoverIfNeeded(showAlert: false)
        XCTAssertFalse(recovered)
    }

    func testRecoveryHandlerIsCalled() {
        // Create a stale session
        let staleSession = CrashRecoveryManager.SessionInfo(
            pid: 99999999,
            startTime: Date(),
            cursorWasActive: true
        )

        if let data = try? JSONEncoder().encode(staleSession) {
            try? data.write(to: URL(fileURLWithPath: sessionFilePath))
        }

        var handlerCalled = false
        crashManager.onRecovery {
            handlerCalled = true
        }

        _ = crashManager.recoverIfNeeded(showAlert: false)
        XCTAssertTrue(handlerCalled)
    }
}

// MARK: - ProcessLifecycleManager Tests

final class ProcessLifecycleManagerTests: XCTestCase {
    var tempSessionPath: String!
    var manager: ProcessLifecycleManager!

    override func setUp() {
        super.setUp()
        tempSessionPath = (NSTemporaryDirectory() as NSString)
            .appendingPathComponent("test.lifecycle.\(UUID().uuidString).json")

        // Create manager with test dependencies
        let mockWorkspace = MockWorkspace(runningApps: [])
        let singleInstanceGuard = SingleInstanceGuard(
            workspace: mockWorkspace,
            bundleIdentifier: "com.test.app",
            currentPID: ProcessInfo.processInfo.processIdentifier
        )
        let signalHandler = SignalHandler()
        let crashRecoveryManager = CrashRecoveryManager(
            sessionFilePath: tempSessionPath,
            fileManager: .default
        )
        let orphanCleaner = OrphanCleaner(
            processName: "NonExistentTestProcess",
            currentPID: ProcessInfo.processInfo.processIdentifier
        )
        let mockCursorService = MockCursorService()

        manager = ProcessLifecycleManager(
            singleInstanceGuard: singleInstanceGuard,
            signalHandler: signalHandler,
            crashRecoveryManager: crashRecoveryManager,
            orphanCleaner: orphanCleaner,
            cursorService: mockCursorService
        )
    }

    override func tearDown() {
        manager.shutdown()
        try? FileManager.default.removeItem(atPath: tempSessionPath)
        super.tearDown()
    }

    func testSharedInstanceExists() {
        XCTAssertNotNil(ProcessLifecycleManager.shared)
    }

    func testStartupReturnsTrue() {
        XCTAssertTrue(manager.startup())
        XCTAssertTrue(manager.isRunning)
    }

    func testStartupIsIdempotent() {
        XCTAssertTrue(manager.startup())
        XCTAssertTrue(manager.startup()) // Second call should also return true
    }

    func testShutdownSetsIsRunningFalse() {
        _ = manager.startup()
        manager.shutdown()
        XCTAssertFalse(manager.isRunning)
    }

    func testRegisterForTerminationStoresHandler() {
        var handlerCalled = false

        manager.registerForTermination {
            handlerCalled = true
        }

        // Handler should not be called until shutdown
        XCTAssertFalse(handlerCalled)

        _ = manager.startup()
        manager.shutdown()

        // Handler should be called on shutdown
        XCTAssertTrue(handlerCalled)
    }

    func testMarkCursorActiveDoesNotCrash() {
        _ = manager.startup()
        manager.markCursorActive(true)
        manager.markCursorActive(false)
    }

    func testShutdownCleansUpSessionFile() {
        _ = manager.startup()
        XCTAssertTrue(FileManager.default.fileExists(atPath: tempSessionPath))

        manager.shutdown()
        XCTAssertFalse(FileManager.default.fileExists(atPath: tempSessionPath))
    }
}

// MARK: - Mock Classes

class MockWorkspace: WorkspaceProvider {
    let apps: [RunningApplicationProtocol]

    init(runningApps: [RunningApplicationProtocol]) {
        self.apps = runningApps
    }

    var runningApplications: [RunningApplicationProtocol] {
        return apps
    }
}

class MockRunningApplication: RunningApplicationProtocol {
    let bundleIdentifier: String?
    let processIdentifier: pid_t
    let localizedName: String?
    var activateCalled = false

    init(bundleIdentifier: String?, processIdentifier: pid_t, localizedName: String? = nil) {
        self.bundleIdentifier = bundleIdentifier
        self.processIdentifier = processIdentifier
        self.localizedName = localizedName
    }

    func activate(options: NSApplication.ActivationOptions) -> Bool {
        activateCalled = true
        return true
    }
}
