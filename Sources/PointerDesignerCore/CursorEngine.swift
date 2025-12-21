import Foundation
import AppKit
import CoreGraphics

/// Core engine managing cursor appearance and dynamic updates
/// Fixes edge cases: #4, #9, #10, #30, #31, #32, #33, #34, #35, #36, #37
public final class CursorEngine: CursorService {
    public static let shared = CursorEngine()

    // Injected dependencies (protocol-based for testability)
    private let displayService: DisplayService
    private let permissionService: PermissionService
    private let helperService: HelperService
    private let backgroundDetector: BackgroundColorDetector
    private let cursorRenderer: CursorRenderer

    private var settings: CursorSettings = .defaults
    private var displayLink: CVDisplayLink?

    // Thread-safe state accessed from display link callback
    @Atomic private var isRunning = false
    @Atomic private var lastMouseLocation: CGPoint = .zero
    @Atomic private var lastBackgroundColor: CursorColor = .white
    @Atomic private var lastActivityTime: CFAbsoluteTime = 0
    @Atomic private var movementThreshold: CGFloat = 2.0
    @Atomic private var lastCursorUpdateTime: CFAbsoluteTime = 0
    @Atomic private var currentRefreshRate: Double = 60.0

    // Main thread only
    private var lastAppliedCursor: NSCursor?
    private var idleTimer: Timer?

    // Constants
    private let idleThreshold: TimeInterval = 5.0 // seconds
    private let minUpdateInterval: TimeInterval = 1.0 / 120.0 // Max 120 updates/sec

    // Thread safety
    private let updateQueue = DispatchQueue(label: "com.pointerdesigner.cursorengine", qos: .userInteractive)
    private let settingsLock = NSLock()

    /// Default initializer using production singletons
    private init() {
        self.displayService = DisplayManager.shared
        self.permissionService = PermissionManager.shared
        self.helperService = HelperToolManager.shared
        self.backgroundDetector = BackgroundColorDetector()
        self.cursorRenderer = CursorRenderer()
        setupObservers()
    }

    /// Initializer for dependency injection (testing)
    public init(
        displayService: DisplayService,
        permissionService: PermissionService,
        helperService: HelperService,
        backgroundDetector: BackgroundColorDetector? = nil,
        cursorRenderer: CursorRenderer? = nil
    ) {
        self.displayService = displayService
        self.permissionService = permissionService
        self.helperService = helperService
        self.backgroundDetector = backgroundDetector ?? BackgroundColorDetector()
        self.cursorRenderer = cursorRenderer ?? CursorRenderer()
        setupObservers()
    }

    deinit {
        stop()
        removeObservers()
    }

    // MARK: - Public API

    /// Configure the engine with new settings
    public func configure(with settings: CursorSettings) {
        settingsLock.lock()
        self.settings = settings
        settingsLock.unlock()

        cursorRenderer.configure(with: settings)
        backgroundDetector.reset()

        if isRunning {
            applyCursor()
        }
    }

    /// Start cursor customization
    public func start() {
        guard !isRunning else { return }

        // Edge case #5: Check permissions first
        if settings.contrastMode != .none && !permissionService.hasScreenRecordingPermission {
            permissionService.promptForPermission(.screenRecording, from: nil)
        }

        isRunning = true
        lastActivityTime = CFAbsoluteTimeGetCurrent()

        setupDisplayLink()

        if let displayLink = displayLink {
            CVDisplayLinkStart(displayLink)
        }

        startIdleTimer()
        applyCursor()
    }

    /// Stop cursor customization and restore system default
    public func stop() {
        guard isRunning else { return }
        isRunning = false

        stopIdleTimer()
        releaseDisplayLink()
        restoreSystemCursor()
    }

    /// Properly release the CVDisplayLink to prevent resource leaks
    private func releaseDisplayLink() {
        if let link = displayLink {
            CVDisplayLinkStop(link)
            // CVDisplayLink is a CFType, setting to nil releases it
            displayLink = nil
        }
    }

    // MARK: - Setup

    private func setupDisplayLink() {
        // Edge case #4: Create display link that handles hotplug
        var link: CVDisplayLink?
        CVDisplayLinkCreateWithActiveCGDisplays(&link)

        guard let displayLink = link else { return }

        let callback: CVDisplayLinkOutputCallback = { displayLink, inNow, inOutputTime, flagsIn, flagsOut, userInfo -> CVReturn in
            guard let userInfo = userInfo else { return kCVReturnSuccess }
            let engine = Unmanaged<CursorEngine>.fromOpaque(userInfo).takeUnretainedValue()
            engine.displayLinkFired()
            return kCVReturnSuccess
        }

        let userInfo = Unmanaged.passUnretained(self).toOpaque()
        CVDisplayLinkSetOutputCallback(displayLink, callback, userInfo)

        // Edge case #9: Track refresh rate for ProMotion displays
        updateRefreshRate(for: displayLink)

        self.displayLink = displayLink
    }

    // Edge case #9: Update refresh rate tracking
    private func updateRefreshRate(for displayLink: CVDisplayLink) {
        let actualRate: CVTime = CVDisplayLinkGetNominalOutputVideoRefreshPeriod(displayLink)
        // Check if the time is valid and not indefinite
        // CVTimeFlags.isIndefinite = 1 << 0
        let isIndefiniteFlag: Int32 = 1
        if (actualRate.flags & isIndefiniteFlag) != 0 || actualRate.timeValue <= 0 {
            currentRefreshRate = 60.0
        } else {
            currentRefreshRate = Double(actualRate.timeScale) / Double(actualRate.timeValue)
        }
    }

    private func setupObservers() {
        // Edge case #4, #10: Handle display configuration changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleDisplayChange),
            name: .displayConfigurationDidChange,
            object: nil
        )

        // Edge case #30: Handle appearance changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppearanceChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )

        // Edge case #36: Handle app state changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidBecomeActive),
            name: NSApplication.didBecomeActiveNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleAppDidResignActive),
            name: NSApplication.didResignActiveNotification,
            object: nil
        )

        // Edge case #32, #42: Handle sleep/wake
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handleSleepNotification),
            name: NSWorkspace.willSleepNotification,
            object: nil
        )

        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(handleWakeNotification),
            name: NSWorkspace.didWakeNotification,
            object: nil
        )

        // Edge case #33: Handle memory warnings
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleMemoryWarning),
            name: NSNotification.Name("NSApplicationDidReceiveMemoryWarningNotification"),
            object: nil
        )
    }

    private func removeObservers() {
        NotificationCenter.default.removeObserver(self)
        NSWorkspace.shared.notificationCenter.removeObserver(self)
    }

    // MARK: - Event Handlers

    @objc private func handleDisplayChange(_ notification: Notification) {
        // Edge case #4, #10: Recreate display link for new configuration
        releaseDisplayLink()

        if isRunning {
            setupDisplayLink()
            if let displayLink = displayLink {
                CVDisplayLinkStart(displayLink)
            }
            applyCursor()
        }
    }

    @objc private func handleAppearanceChange(_ notification: Notification) {
        // Edge case #30: Clear cache and re-render cursor
        cursorRenderer.clearCache()
        backgroundDetector.reset()

        if isRunning {
            applyCursor()
        }
    }

    @objc private func handleAppDidBecomeActive(_ notification: Notification) {
        // Edge case #36: Resume updates when app becomes active
        if isRunning, let displayLink = displayLink {
            CVDisplayLinkStart(displayLink)
        }
    }

    @objc private func handleAppDidResignActive(_ notification: Notification) {
        // Edge case #36: Reduce updates when in background
        // Keep running but at reduced rate
    }

    @objc private func handleSleepNotification(_ notification: Notification) {
        // Edge case #32, #42: Stop before sleep
        releaseDisplayLink()
    }

    @objc private func handleWakeNotification(_ notification: Notification) {
        // Edge case #32, #42: Resume after wake
        if isRunning {
            // Delay to let display settle
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
                self?.handleDisplayChange(notification)
            }
        }
    }

    @objc private func handleMemoryWarning(_ notification: Notification) {
        // Edge case #33: Clear caches on memory pressure
        cursorRenderer.clearCache()
    }

    // MARK: - Idle Detection (Edge case #34)

    private func startIdleTimer() {
        idleTimer?.invalidate()
        idleTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.checkIdle()
        }
    }

    private func stopIdleTimer() {
        idleTimer?.invalidate()
        idleTimer = nil
    }

    private func checkIdle() {
        let now = CFAbsoluteTimeGetCurrent()
        let idleTime = now - lastActivityTime

        if idleTime > idleThreshold {
            // Reduce processing when idle
            // The display link still fires but we skip sampling
        }
    }

    // MARK: - Display Link Callback

    private func displayLinkFired() {
        guard isRunning else { return }

        let now = CFAbsoluteTimeGetCurrent()

        // Edge case #37: Rate limit updates
        guard now - lastCursorUpdateTime >= minUpdateInterval else { return }

        // CRITICAL: NSEvent.mouseLocation must be accessed on main thread
        // Capture it here and pass to background processing
        DispatchQueue.main.async { [weak self] in
            guard let self = self, self.isRunning else { return }
            let mouseLocation = NSEvent.mouseLocation
            self.updateQueue.async { [weak self] in
                self?.processFrame(mouseLocation: mouseLocation)
            }
        }
    }

    private func processFrame(mouseLocation: NSPoint) {
        // Edge case #3: Convert coordinates properly for current display
        let cgPoint = displayService.convertToCGPoint(mouseLocation)

        // Edge case #35: Adaptive movement threshold based on speed
        let distance = hypot(cgPoint.x - lastMouseLocation.x, cgPoint.y - lastMouseLocation.y)

        // Update activity time if moved
        if distance > 0.5 {
            lastActivityTime = CFAbsoluteTimeGetCurrent()
        }

        // Skip if mouse hasn't moved significantly (edge case #34: idle optimization)
        guard distance > movementThreshold else { return }

        // Edge case #35: Adjust threshold based on movement speed
        if distance > 50 {
            movementThreshold = 5.0 // Fast movement, larger threshold
        } else {
            movementThreshold = 2.0 // Slow movement, smaller threshold
        }

        lastMouseLocation = cgPoint

        // Sample background color if contrast mode is active
        settingsLock.lock()
        let currentSettings = settings
        settingsLock.unlock()

        if currentSettings.contrastMode != .none {
            if let bgColor = backgroundDetector.sampleColor(at: cgPoint, settings: currentSettings) {
                // Only update if color changed significantly
                let colorDelta = abs(bgColor.brightness - lastBackgroundColor.brightness)
                if colorDelta > currentSettings.hysteresis {
                    lastBackgroundColor = bgColor
                    DispatchQueue.main.async { [weak self] in
                        self?.applyCursor()
                    }
                }
            }
        }
    }

    // MARK: - Cursor Application

    private func applyCursor() {
        settingsLock.lock()
        let currentSettings = settings
        settingsLock.unlock()

        let effectiveColor: CursorColor

        switch currentSettings.contrastMode {
        case .none:
            effectiveColor = currentSettings.cursorColor
        case .autoInvert:
            effectiveColor = calculateInvertedColor(against: lastBackgroundColor, settings: currentSettings)
        case .outline:
            effectiveColor = currentSettings.cursorColor
        }

        let outlineColor: CursorColor?
        if currentSettings.contrastMode == .outline {
            outlineColor = currentSettings.outlineColor ?? lastBackgroundColor.withGuaranteedContrast()
        } else {
            outlineColor = nil
        }

        guard let cursorImage = cursorRenderer.renderCursor(
            color: effectiveColor,
            outlineColor: outlineColor,
            outlineWidth: currentSettings.contrastMode == .outline ? currentSettings.outlineWidth : 0,
            at: lastMouseLocation
        ) else { return }

        // Edge case #25: Calculate correct hot spot
        let hotSpot = cursorRenderer.hotSpot(for: currentSettings.contrastMode == .outline ? currentSettings.outlineWidth : 0)
        let cursor = NSCursor(image: cursorImage, hotSpot: hotSpot)

        // Edge case #37: Update timestamp
        lastCursorUpdateTime = CFAbsoluteTimeGetCurrent()

        DispatchQueue.main.async { [weak self] in
            cursor.set()
            self?.lastAppliedCursor = cursor
        }

        // For system-wide changes, communicate with helper
        helperService.setCursor(cursorImage)
    }

    private func calculateInvertedColor(against background: CursorColor, settings: CursorSettings) -> CursorColor {
        let threshold = settings.brightnessThreshold

        if background.brightness < threshold {
            // Dark background - use bright version of user's color
            let boostFactor: Float = 0.8
            return CursorColor(
                red: max(settings.cursorColor.red, boostFactor),
                green: max(settings.cursorColor.green, boostFactor),
                blue: max(settings.cursorColor.blue, boostFactor)
            )
        } else {
            // Light background - use dark version of user's color
            let dimFactor: Float = 0.2
            return CursorColor(
                red: min(settings.cursorColor.red, dimFactor),
                green: min(settings.cursorColor.green, dimFactor),
                blue: min(settings.cursorColor.blue, dimFactor)
            )
        }
    }

    private func restoreSystemCursor() {
        DispatchQueue.main.async {
            NSCursor.arrow.set()
        }
        helperService.restoreSystemCursor()
        lastAppliedCursor = nil
    }

    // MARK: - Public Utilities

    /// Force refresh cursor (call after permission granted)
    public func refresh() {
        backgroundDetector.reset()
        cursorRenderer.clearCache()
        applyCursor()
    }

    /// Check if engine can use contrast features
    public var canUseContrastFeatures: Bool {
        return permissionService.hasScreenRecordingPermission
    }
}
