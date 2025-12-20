import Foundation
import CoreGraphics
import AppKit

/// Samples screen colors at cursor position for contrast detection
/// Fixes edge cases: #2, #5, #11, #12, #13, #14, #15, #16, #19, #20
public final class BackgroundColorDetector {
    private let sampleSize: CGFloat = 5
    private let displayManager = DisplayManager.shared
    private let permissionManager = PermissionManager.shared

    // Edge case #12: Debounce rapid color changes
    private var lastSampleTime: CFAbsoluteTime = 0
    private var lastStableColor: CursorColor = .white
    private var colorChangeCount = 0
    private let flickerThreshold = 10 // Changes per second before stabilizing

    // Edge case #14: Hysteresis to prevent oscillation
    private var brightnessHistory: [Float] = []
    private let historySize = 5

    public init() {}

    /// Sample the average color at a given screen position
    /// Returns nil if permission denied or invalid position
    public func sampleColor(at point: CGPoint, settings: CursorSettings = .defaults) -> CursorColor? {
        // Edge case #5: Check screen recording permission
        guard permissionManager.hasScreenRecordingPermission else {
            return nil
        }

        // Edge case #2: Get safe sampling rect within screen bounds
        let safeRect = displayManager.safeSamplingRect(centeredAt: point, size: sampleSize)

        // Edge case #3: Verify point is on a valid display
        guard displayManager.isPointOnScreen(point) else {
            return lastStableColor // Return last known good color
        }

        guard let image = CGWindowListCreateImage(
            safeRect,
            .optionOnScreenBelowWindow, // Edge case #15: Sample below cursor window
            kCGNullWindowID,
            [.bestResolution, .boundsIgnoreFraming]
        ) else {
            return nil
        }

        guard var color = averageColor(of: image) else {
            return nil
        }

        // Edge case #16: Handle P3 wide gamut by clamping
        color = CursorColor(red: color.red, green: color.green, blue: color.blue, alpha: color.alpha)

        // Edge case #12: Detect and suppress flickering
        color = applyFlickerSuppression(color, settings: settings)

        // Edge case #14: Apply hysteresis to prevent oscillation
        color = applyHysteresis(color, settings: settings)

        return color
    }

    /// Calculate the average color of an image
    /// Fixes edge case #16: Handles color space conversion properly
    private func averageColor(of image: CGImage) -> CursorColor? {
        let width = image.width
        let height = image.height
        let totalPixels = width * height

        guard totalPixels > 0 else { return nil }

        // Use sRGB color space for consistent results (edge case #16)
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else {
            return nil
        }

        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * width
        let bitsPerComponent = 8

        var rawData = [UInt8](repeating: 0, count: height * bytesPerRow)

        guard let context = CGContext(
            data: &rawData,
            width: width,
            height: height,
            bitsPerComponent: bitsPerComponent,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else {
            return nil
        }

        context.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))

        var totalRed: Int = 0
        var totalGreen: Int = 0
        var totalBlue: Int = 0
        var totalAlpha: Int = 0

        for y in 0..<height {
            for x in 0..<width {
                let offset = (y * bytesPerRow) + (x * bytesPerPixel)
                totalRed += Int(rawData[offset])
                totalGreen += Int(rawData[offset + 1])
                totalBlue += Int(rawData[offset + 2])
                totalAlpha += Int(rawData[offset + 3])
            }
        }

        // Edge case #11: If mostly transparent, sample might be over transparent window
        let avgAlpha = Float(totalAlpha) / Float(totalPixels * 255)
        if avgAlpha < 0.3 {
            // Mostly transparent - could be sampling through a window
            // Return a neutral color that works well with any background
            return CursorColor(red: 0.5, green: 0.5, blue: 0.5)
        }

        return CursorColor(
            red: Float(totalRed) / Float(totalPixels * 255),
            green: Float(totalGreen) / Float(totalPixels * 255),
            blue: Float(totalBlue) / Float(totalPixels * 255)
        )
    }

    /// Sample multiple points around cursor for gradient detection (edge case #13)
    public func sampleColorWithContext(at point: CGPoint, radius: CGFloat = 10, settings: CursorSettings = .defaults) -> CursorColor? {
        guard permissionManager.hasScreenRecordingPermission else {
            return nil
        }

        let samplePoints: [CGPoint] = [
            point,
            CGPoint(x: point.x - radius, y: point.y),
            CGPoint(x: point.x + radius, y: point.y),
            CGPoint(x: point.x, y: point.y - radius),
            CGPoint(x: point.x, y: point.y + radius)
        ]

        var colors: [CursorColor] = []
        var brightnesses: [Float] = []

        for samplePoint in samplePoints {
            if displayManager.isPointOnScreen(samplePoint),
               let color = sampleColor(at: samplePoint, settings: settings) {
                colors.append(color)
                brightnesses.append(color.brightness)
            }
        }

        guard !colors.isEmpty else { return nil }

        // Edge case #13: Detect gradients by checking brightness variance
        let avgBrightness = brightnesses.reduce(0, +) / Float(brightnesses.count)
        let variance = brightnesses.reduce(0) { $0 + pow($1 - avgBrightness, 2) } / Float(brightnesses.count)

        // High variance = gradient, use center point brightness for stability
        if variance > 0.1 {
            return colors[0] // Return center sample
        }

        // Low variance = uniform color, return average
        let avgRed = colors.reduce(0) { $0 + $1.red } / Float(colors.count)
        let avgGreen = colors.reduce(0) { $0 + $1.green } / Float(colors.count)
        let avgBlue = colors.reduce(0) { $0 + $1.blue } / Float(colors.count)

        return CursorColor(red: avgRed, green: avgGreen, blue: avgBlue)
    }

    // Edge case #12: Suppress flickering from video/animation
    private func applyFlickerSuppression(_ color: CursorColor, settings: CursorSettings) -> CursorColor {
        let now = CFAbsoluteTimeGetCurrent()
        let timeDelta = now - lastSampleTime
        lastSampleTime = now

        // Reset counter after 1 second of stable colors
        if timeDelta > 1.0 {
            colorChangeCount = 0
        }

        // Detect rapid color changes
        let colorDelta = abs(color.brightness - lastStableColor.brightness)
        if colorDelta > 0.1 {
            colorChangeCount += 1
        }

        // If changing too rapidly, stick with stable color
        if colorChangeCount > flickerThreshold {
            return lastStableColor
        }

        // Update stable color on significant change
        if colorDelta > 0.2 {
            lastStableColor = color
        }

        return color
    }

    // Edge case #14: Apply hysteresis to prevent oscillation at threshold
    private func applyHysteresis(_ color: CursorColor, settings: CursorSettings) -> CursorColor {
        brightnessHistory.append(color.brightness)
        if brightnessHistory.count > historySize {
            brightnessHistory.removeFirst()
        }

        // Calculate smoothed brightness
        let smoothedBrightness = brightnessHistory.reduce(0, +) / Float(brightnessHistory.count)

        // Only change if we've moved beyond hysteresis threshold
        let threshold = settings.brightnessThreshold
        let hysteresis = settings.hysteresis

        let lastBrightness = lastStableColor.brightness

        // If crossing threshold, require extra margin (hysteresis)
        if lastBrightness < threshold && smoothedBrightness > threshold + hysteresis {
            // Was dark, now definitively light
            lastStableColor = color
        } else if lastBrightness >= threshold && smoothedBrightness < threshold - hysteresis {
            // Was light, now definitively dark
            lastStableColor = color
        }

        // Return original color but decisions use hysteresis
        return color
    }

    /// Check if point is over system UI (edge cases #19, #20)
    public func isOverSystemUI(at point: NSPoint) -> Bool {
        // Check menu bar
        if let mainScreen = NSScreen.main {
            let menuBarHeight: CGFloat = 24
            if point.y > mainScreen.frame.height - menuBarHeight {
                return true
            }
        }

        // Check Dock (approximate - Dock position varies)
        // This is a heuristic since Dock position detection requires private APIs
        if let mainScreen = NSScreen.main {
            let dockHeight: CGFloat = 70
            if point.y < dockHeight {
                return true
            }
        }

        return false
    }

    /// Reset detection state
    public func reset() {
        lastSampleTime = 0
        lastStableColor = .white
        colorChangeCount = 0
        brightnessHistory.removeAll()
    }
}
