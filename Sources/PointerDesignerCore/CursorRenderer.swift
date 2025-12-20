import Foundation
import AppKit
import CoreGraphics

/// Renders custom cursor images with color and outline options
/// Fixes edge cases: #21, #22, #24, #25, #26, #27, #28, #29
public final class CursorRenderer {
    private var settings: CursorSettings = .defaults
    private let displayManager = DisplayManager.shared

    // Standard macOS arrow cursor dimensions
    private let baseCursorWidth: CGFloat = 24
    private let baseCursorHeight: CGFloat = 24

    // Edge case #27: Image cache to reduce memory pressure
    private var imageCache: NSCache<NSString, NSImage> = {
        let cache = NSCache<NSString, NSImage>()
        cache.countLimit = 10
        cache.totalCostLimit = 1024 * 1024 * 5 // 5MB
        return cache
    }()

    public init() {}

    public func configure(with settings: CursorSettings) {
        self.settings = settings
        // Clear cache when settings change
        imageCache.removeAllObjects()
    }

    /// Render a cursor image with specified color and optional outline
    /// Fixes edge cases #21, #24, #25, #26
    public func renderCursor(
        color: CursorColor,
        outlineColor: CursorColor?,
        outlineWidth: Float,
        at point: CGPoint? = nil
    ) -> NSImage? {
        // Edge case #1: Get appropriate scale for current display
        let scale: CGFloat
        if settings.adaptiveScaling, let point = point {
            scale = displayManager.scaleFactor(for: point)
        } else {
            scale = NSScreen.main?.backingScaleFactor ?? 2.0
        }

        // Edge case #21, #24: Validate and clamp outline width
        let safeOutlineWidth = validateOutlineWidth(outlineWidth)

        // Edge case #27: Check cache first
        let cacheKey = cacheKeyFor(color: color, outlineColor: outlineColor, outlineWidth: safeOutlineWidth, scale: scale)
        if let cachedImage = imageCache.object(forKey: cacheKey as NSString) {
            return cachedImage
        }

        // Calculate size with outline padding
        let padding = CGFloat(safeOutlineWidth) + 2
        let size = NSSize(
            width: (baseCursorWidth + padding * 2) * scale,
            height: (baseCursorHeight + padding * 2) * scale
        )

        // Edge case #26: Safely create image with error handling
        guard let image = createImage(size: size) else {
            return createFallbackCursor(color: color, scale: scale)
        }

        image.lockFocus()

        guard let context = NSGraphicsContext.current?.cgContext else {
            image.unlockFocus()
            return createFallbackCursor(color: color, scale: scale)
        }

        // Edge case #28: Handle non-integer scale factors
        context.interpolationQuality = .high
        context.setShouldAntialias(true)

        context.scaleBy(x: scale, y: scale)
        context.translateBy(x: padding, y: padding)

        // Draw outline first if enabled (edge case #21: only if width > 0)
        if let outline = outlineColor, safeOutlineWidth > 0 {
            drawCursorPath(in: context, color: outline, inflate: CGFloat(safeOutlineWidth))
        }

        // Draw main cursor
        drawCursorPath(in: context, color: color, inflate: 0)

        image.unlockFocus()

        // Cache the rendered image
        imageCache.setObject(image, forKey: cacheKey as NSString)

        return image
    }

    /// Edge case #21, #24: Validate outline width to prevent geometry issues
    private func validateOutlineWidth(_ width: Float) -> Float {
        // Minimum 0 (no outline), maximum half the cursor size to prevent overflow
        let maxWidth = Float(baseCursorWidth) / 4.0 // Max ~6px
        return max(0, min(width, maxWidth))
    }

    private func drawCursorPath(in context: CGContext, color: CursorColor, inflate: CGFloat) {
        let nsColor = NSColor(
            red: CGFloat(color.red),
            green: CGFloat(color.green),
            blue: CGFloat(color.blue),
            alpha: CGFloat(color.alpha)
        )

        context.setFillColor(nsColor.cgColor)

        // Create border color with guaranteed contrast
        let borderColor = color.brightness > 0.5
            ? NSColor.black.withAlphaComponent(0.4)
            : NSColor.white.withAlphaComponent(0.4)
        context.setStrokeColor(borderColor.cgColor)
        context.setLineWidth(0.5)

        // Arrow cursor path (standard macOS pointer shape)
        let path = createCursorPath(inflate: inflate)

        context.addPath(path)
        context.fillPath()

        // Add border for definition
        context.addPath(path)
        context.strokePath()
    }

    /// Create cursor path with optional inflation for outline
    /// Edge case #21: Ensure path remains valid even with large inflation
    private func createCursorPath(inflate: CGFloat) -> CGPath {
        let path = CGMutablePath()

        // Clamp inflation to prevent path inversion
        let offset = min(inflate, 5)

        // Arrow shape vertices - adjusted for inflation
        let tipX: CGFloat = 1
        let tipY: CGFloat = 1

        // Main arrow body
        path.move(to: CGPoint(x: tipX - offset, y: tipY - offset))
        path.addLine(to: CGPoint(x: tipX - offset, y: tipY + 17 + offset))
        path.addLine(to: CGPoint(x: tipX + 4, y: tipY + 13 + offset * 0.5))
        path.addLine(to: CGPoint(x: tipX + 7 + offset * 0.3, y: tipY + 20 + offset))
        path.addLine(to: CGPoint(x: tipX + 9 + offset * 0.5, y: tipY + 19 + offset))
        path.addLine(to: CGPoint(x: tipX + 6, y: tipY + 12 + offset * 0.3))
        path.addLine(to: CGPoint(x: tipX + 11 + offset, y: tipY + 12 + offset * 0.3))
        path.closeSubpath()

        return path
    }

    /// Edge case #25: Calculate correct hot spot based on cursor size and outline
    public func hotSpot(for outlineWidth: Float) -> NSPoint {
        let safeOutlineWidth = validateOutlineWidth(outlineWidth)
        let padding = CGFloat(safeOutlineWidth) + 2

        // Hot spot at tip of arrow, accounting for padding
        return NSPoint(x: padding + 1, y: padding + 1)
    }

    /// Edge case #26: Safe image creation with fallback
    private func createImage(size: NSSize) -> NSImage? {
        guard size.width > 0, size.height > 0,
              size.width < 1000, size.height < 1000 else { // Sanity check
            return nil
        }

        return NSImage(size: size)
    }

    /// Edge case #26: Fallback cursor when rendering fails
    private func createFallbackCursor(color: CursorColor, scale: CGFloat) -> NSImage {
        let size = NSSize(width: baseCursorWidth * scale, height: baseCursorHeight * scale)
        let image = NSImage(size: size)

        image.lockFocus()
        if let context = NSGraphicsContext.current?.cgContext {
            context.scaleBy(x: scale, y: scale)

            // Simple circle fallback
            let rect = CGRect(x: 2, y: 2, width: 10, height: 10)
            context.setFillColor(NSColor(
                red: CGFloat(color.red),
                green: CGFloat(color.green),
                blue: CGFloat(color.blue),
                alpha: CGFloat(color.alpha)
            ).cgColor)
            context.fillEllipse(in: rect)
        }
        image.unlockFocus()

        return image
    }

    /// Create a cursor with dynamic shadow based on background
    public func renderCursorWithShadow(
        color: CursorColor,
        shadowColor: CursorColor,
        shadowOffset: CGFloat = 1,
        at point: CGPoint? = nil
    ) -> NSImage? {
        let scale: CGFloat
        if settings.adaptiveScaling, let point = point {
            scale = displayManager.scaleFactor(for: point)
        } else {
            scale = NSScreen.main?.backingScaleFactor ?? 2.0
        }

        let size = NSSize(
            width: (baseCursorWidth + 4) * scale,
            height: (baseCursorHeight + 4) * scale
        )

        guard let image = createImage(size: size) else {
            return createFallbackCursor(color: color, scale: scale)
        }

        image.lockFocus()

        guard let context = NSGraphicsContext.current?.cgContext else {
            image.unlockFocus()
            return createFallbackCursor(color: color, scale: scale)
        }

        context.interpolationQuality = .high
        context.setShouldAntialias(true)
        context.scaleBy(x: scale, y: scale)

        // Draw shadow
        context.saveGState()
        context.translateBy(x: shadowOffset, y: shadowOffset)
        drawCursorPath(in: context, color: shadowColor.contrasting, inflate: 1)
        context.restoreGState()

        // Draw main cursor
        drawCursorPath(in: context, color: color, inflate: 0)

        image.unlockFocus()
        return image
    }

    /// Clear image cache (call on memory warning)
    public func clearCache() {
        imageCache.removeAllObjects()
    }

    /// Generate cache key for rendered cursor
    private func cacheKeyFor(color: CursorColor, outlineColor: CursorColor?, outlineWidth: Float, scale: CGFloat) -> String {
        var key = "c\(color.red)_\(color.green)_\(color.blue)_\(color.alpha)"
        if let outline = outlineColor {
            key += "_o\(outline.red)_\(outline.green)_\(outline.blue)"
        }
        key += "_w\(outlineWidth)_s\(scale)"
        return key
    }
}
