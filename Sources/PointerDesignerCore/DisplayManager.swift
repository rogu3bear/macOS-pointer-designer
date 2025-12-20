import Foundation
import AppKit
import CoreGraphics

/// Manages display configuration and handles multi-monitor, DPI, and display change scenarios
/// Fixes edge cases: #1, #3, #4, #6, #7, #8, #9, #10
public final class DisplayManager {
    public static let shared = DisplayManager()

    private var displayConfigurationToken: CGDisplayReconfigurationCallBack?
    private var cachedDisplayInfo: [CGDirectDisplayID: DisplayInfo] = [:]

    public struct DisplayInfo {
        public let displayID: CGDirectDisplayID
        public let bounds: CGRect
        public let scaleFactor: CGFloat
        public let refreshRate: Double
        public let isBuiltIn: Bool
        public let isHDR: Bool
        public let colorSpace: CGColorSpace?

        public var isRetina: Bool { scaleFactor >= 2.0 }
    }

    private init() {
        refreshDisplayInfo()
        registerForDisplayChanges()
    }

    deinit {
        unregisterForDisplayChanges()
    }

    // MARK: - Public API

    /// Get display info for the display containing the given point
    public func displayInfo(for point: CGPoint) -> DisplayInfo? {
        var displayCount: UInt32 = 0
        var displayID: CGDirectDisplayID = 0

        let result = CGGetDisplaysWithPoint(point, 1, &displayID, &displayCount)

        guard result == .success, displayCount > 0 else {
            // Point is in dead zone between monitors - use nearest display
            return nearestDisplay(to: point)
        }

        return cachedDisplayInfo[displayID] ?? createDisplayInfo(for: displayID)
    }

    /// Get the appropriate scale factor for cursor rendering at a point
    public func scaleFactor(for point: CGPoint) -> CGFloat {
        return displayInfo(for: point)?.scaleFactor ?? 2.0
    }

    /// Convert NSEvent mouse location to CGPoint for the correct display
    public func convertToCGPoint(_ nsPoint: NSPoint) -> CGPoint {
        // NSEvent uses bottom-left origin, CG uses top-left
        guard let screen = screenContaining(nsPoint) else {
            // Fallback to main screen
            let mainHeight = NSScreen.main?.frame.height ?? 0
            return CGPoint(x: nsPoint.x, y: mainHeight - nsPoint.y)
        }

        let screenFrame = screen.frame

        // Convert Y coordinate within this screen's coordinate space
        return CGPoint(
            x: nsPoint.x,
            y: screenFrame.maxY - nsPoint.y
        )
    }

    /// Check if a point is within valid screen bounds
    public func isPointOnScreen(_ point: CGPoint) -> Bool {
        for screen in NSScreen.screens {
            if screen.frame.contains(NSPoint(x: point.x, y: screen.frame.maxY - point.y)) {
                return true
            }
        }
        return false
    }

    /// Get safe sampling rect that doesn't extend beyond screen bounds
    public func safeSamplingRect(centeredAt point: CGPoint, size: CGFloat) -> CGRect {
        let halfSize = size / 2

        var rect = CGRect(
            x: point.x - halfSize,
            y: point.y - halfSize,
            width: size,
            height: size
        )

        // Find the display containing this point
        guard let display = displayInfo(for: point) else {
            return rect
        }

        // Clamp to display bounds
        let bounds = display.bounds

        if rect.minX < bounds.minX {
            rect.origin.x = bounds.minX
        }
        if rect.minY < bounds.minY {
            rect.origin.y = bounds.minY
        }
        if rect.maxX > bounds.maxX {
            rect.size.width = bounds.maxX - rect.origin.x
        }
        if rect.maxY > bounds.maxY {
            rect.size.height = bounds.maxY - rect.origin.y
        }

        // Ensure minimum size
        rect.size.width = max(rect.size.width, 1)
        rect.size.height = max(rect.size.height, 1)

        return rect
    }

    /// Check if display supports HDR (edge case #6)
    public func isHDRDisplay(at point: CGPoint) -> Bool {
        return displayInfo(for: point)?.isHDR ?? false
    }

    /// Refresh all display information (call after display configuration change)
    public func refreshDisplayInfo() {
        cachedDisplayInfo.removeAll()

        var displayCount: UInt32 = 0
        CGGetActiveDisplayList(0, nil, &displayCount)

        guard displayCount > 0 else { return }

        var displays = [CGDirectDisplayID](repeating: 0, count: Int(displayCount))
        CGGetActiveDisplayList(displayCount, &displays, &displayCount)

        for displayID in displays {
            cachedDisplayInfo[displayID] = createDisplayInfo(for: displayID)
        }
    }

    // MARK: - Display Change Notifications (Edge case #4, #10)

    private func registerForDisplayChanges() {
        let callback: CGDisplayReconfigurationCallBack = { displayID, flags, userInfo in
            guard let userInfo = userInfo else { return }
            let manager = Unmanaged<DisplayManager>.fromOpaque(userInfo).takeUnretainedValue()
            manager.handleDisplayChange(displayID: displayID, flags: flags)
        }

        let userInfo = Unmanaged.passUnretained(self).toOpaque()
        CGDisplayRegisterReconfigurationCallback(callback, userInfo)

        // Also observe NSScreen changes
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screensDidChange),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    private func unregisterForDisplayChanges() {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func screensDidChange(_ notification: Notification) {
        refreshDisplayInfo()
        NotificationCenter.default.post(name: .displayConfigurationDidChange, object: nil)
    }

    private func handleDisplayChange(displayID: CGDirectDisplayID, flags: CGDisplayChangeSummaryFlags) {
        if flags.contains(.addFlag) || flags.contains(.removeFlag) ||
           flags.contains(.movedFlag) || flags.contains(.setMainFlag) {
            DispatchQueue.main.async { [weak self] in
                self?.refreshDisplayInfo()
                NotificationCenter.default.post(name: .displayConfigurationDidChange, object: nil)
            }
        }
    }

    // MARK: - Private Helpers

    private func createDisplayInfo(for displayID: CGDirectDisplayID) -> DisplayInfo {
        let bounds = CGDisplayBounds(displayID)
        let mode = CGDisplayCopyDisplayMode(displayID)

        let scaleFactor: CGFloat
        if let mode = mode {
            scaleFactor = CGFloat(mode.pixelWidth) / CGFloat(mode.width)
        } else {
            scaleFactor = NSScreen.main?.backingScaleFactor ?? 2.0
        }

        let refreshRate = mode?.refreshRate ?? 60.0

        // Check if built-in display
        let isBuiltIn = CGDisplayIsBuiltin(displayID) != 0

        // Check HDR capability (edge case #6)
        var isHDR = false
        if #available(macOS 10.15, *) {
            if let screen = NSScreen.screens.first(where: {
                $0.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as? CGDirectDisplayID == displayID
            }) {
                isHDR = screen.maximumPotentialExtendedDynamicRangeColorComponentValue > 1.0
            }
        }

        // Get color space
        let colorSpace = CGDisplayCopyColorSpace(displayID)

        return DisplayInfo(
            displayID: displayID,
            bounds: bounds,
            scaleFactor: scaleFactor,
            refreshRate: refreshRate,
            isBuiltIn: isBuiltIn,
            isHDR: isHDR,
            colorSpace: colorSpace
        )
    }

    private func screenContaining(_ point: NSPoint) -> NSScreen? {
        for screen in NSScreen.screens {
            if screen.frame.contains(point) {
                return screen
            }
        }
        return nil
    }

    private func nearestDisplay(to point: CGPoint) -> DisplayInfo? {
        var nearestDisplay: DisplayInfo?
        var nearestDistance: CGFloat = .greatestFiniteMagnitude

        for (_, info) in cachedDisplayInfo {
            let center = CGPoint(
                x: info.bounds.midX,
                y: info.bounds.midY
            )
            let distance = hypot(point.x - center.x, point.y - center.y)

            if distance < nearestDistance {
                nearestDistance = distance
                nearestDisplay = info
            }
        }

        return nearestDisplay
    }
}

// MARK: - Notifications

public extension Notification.Name {
    static let displayConfigurationDidChange = Notification.Name("com.pointerdesigner.displayConfigurationDidChange")
}
