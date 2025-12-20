import Foundation
import AppKit
import CoreGraphics

/// Core engine managing cursor appearance and dynamic updates
public final class CursorEngine {
    public static let shared = CursorEngine()

    private var settings: CursorSettings = .defaults
    private var displayLink: CVDisplayLink?
    private var isRunning = false
    private let backgroundDetector = BackgroundColorDetector()
    private let cursorRenderer = CursorRenderer()

    private var lastMouseLocation: CGPoint = .zero
    private var lastBackgroundColor: CursorColor = .white

    private init() {
        setupDisplayLink()
    }

    deinit {
        stop()
    }

    // MARK: - Public API

    /// Configure the engine with new settings
    public func configure(with settings: CursorSettings) {
        self.settings = settings
        cursorRenderer.configure(with: settings)

        if isRunning {
            applyCursor()
        }
    }

    /// Start cursor customization
    public func start() {
        guard !isRunning else { return }
        isRunning = true

        if let displayLink = displayLink {
            CVDisplayLinkStart(displayLink)
        }

        applyCursor()
    }

    /// Stop cursor customization and restore system default
    public func stop() {
        guard isRunning else { return }
        isRunning = false

        if let displayLink = displayLink {
            CVDisplayLinkStop(displayLink)
        }

        restoreSystemCursor()
    }

    // MARK: - Private Methods

    private func setupDisplayLink() {
        var link: CVDisplayLink?
        CVDisplayLinkCreateWithActiveCGDisplays(&link)

        guard let displayLink = link else { return }

        let callback: CVDisplayLinkOutputCallback = { _, _, _, _, _, userInfo -> CVReturn in
            guard let userInfo = userInfo else { return kCVReturnSuccess }
            let engine = Unmanaged<CursorEngine>.fromOpaque(userInfo).takeUnretainedValue()
            engine.displayLinkFired()
            return kCVReturnSuccess
        }

        let userInfo = Unmanaged.passUnretained(self).toOpaque()
        CVDisplayLinkSetOutputCallback(displayLink, callback, userInfo)

        self.displayLink = displayLink
    }

    private func displayLinkFired() {
        guard isRunning else { return }

        let mouseLocation = NSEvent.mouseLocation
        let screenHeight = NSScreen.main?.frame.height ?? 0
        let cgPoint = CGPoint(x: mouseLocation.x, y: screenHeight - mouseLocation.y)

        // Skip if mouse hasn't moved significantly
        let distance = hypot(cgPoint.x - lastMouseLocation.x, cgPoint.y - lastMouseLocation.y)
        guard distance > 2 else { return }

        lastMouseLocation = cgPoint

        // Sample background color if contrast mode is active
        if settings.contrastMode != .none {
            if let bgColor = backgroundDetector.sampleColor(at: cgPoint) {
                if bgColor != lastBackgroundColor {
                    lastBackgroundColor = bgColor
                    DispatchQueue.main.async { [weak self] in
                        self?.applyCursor()
                    }
                }
            }
        }
    }

    private func applyCursor() {
        let effectiveColor: CursorColor

        switch settings.contrastMode {
        case .none:
            effectiveColor = settings.cursorColor
        case .autoInvert:
            effectiveColor = calculateInvertedColor(against: lastBackgroundColor)
        case .outline:
            effectiveColor = settings.cursorColor
        }

        let outlineColor: CursorColor?
        if settings.contrastMode == .outline {
            outlineColor = settings.outlineColor ?? lastBackgroundColor.contrasting
        } else {
            outlineColor = nil
        }

        guard let cursorImage = cursorRenderer.renderCursor(
            color: effectiveColor,
            outlineColor: outlineColor,
            outlineWidth: settings.contrastMode == .outline ? settings.outlineWidth : 0
        ) else { return }

        let cursor = NSCursor(image: cursorImage, hotSpot: NSPoint(x: 1, y: 1))

        DispatchQueue.main.async {
            cursor.set()
        }

        // For system-wide changes, communicate with helper
        HelperToolManager.shared.setCursor(cursorImage)
    }

    private func calculateInvertedColor(against background: CursorColor) -> CursorColor {
        // If background is dark, use light cursor; if light, use dark cursor
        if background.brightness < 0.5 {
            // Dark background - use bright version of user's color
            return CursorColor(
                red: max(settings.cursorColor.red, 0.8),
                green: max(settings.cursorColor.green, 0.8),
                blue: max(settings.cursorColor.blue, 0.8)
            )
        } else {
            // Light background - use dark version of user's color
            return CursorColor(
                red: min(settings.cursorColor.red, 0.2),
                green: min(settings.cursorColor.green, 0.2),
                blue: min(settings.cursorColor.blue, 0.2)
            )
        }
    }

    private func restoreSystemCursor() {
        DispatchQueue.main.async {
            NSCursor.arrow.set()
        }
        HelperToolManager.shared.restoreSystemCursor()
    }
}
