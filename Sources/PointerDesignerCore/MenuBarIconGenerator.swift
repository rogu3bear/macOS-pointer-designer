import AppKit

/// Generates dynamic menu bar icons that reflect current cursor settings
public final class MenuBarIconGenerator {
    public static let shared = MenuBarIconGenerator()

    private let iconSize = NSSize(width: 18, height: 18)

    private init() {}

    /// Generate a menu bar icon matching the current cursor settings
    public func generateIcon(for settings: CursorSettings) -> NSImage {
        let image = NSImage(size: iconSize, flipped: false) { rect in
            self.drawCursorIcon(in: rect, settings: settings)
            return true
        }

        // Make it a template only if using default white color without effects
        let isSimple = settings.cursorColor.isEffectivelyWhite &&
                       !settings.glowEnabled &&
                       !settings.shadowEnabled
        image.isTemplate = isSimple

        return image
    }

    private func drawCursorIcon(in rect: NSRect, settings: CursorSettings) {
        let color = NSColor(
            red: CGFloat(settings.cursorColor.red),
            green: CGFloat(settings.cursorColor.green),
            blue: CGFloat(settings.cursorColor.blue),
            alpha: CGFloat(settings.cursorColor.alpha)
        )

        // Scale factor for the cursor
        let scale = CGFloat(settings.cursorScale)
        let cursorHeight: CGFloat = 14 * scale
        let cursorWidth: CGFloat = 10 * scale

        // Center the cursor in the rect
        let originX = (rect.width - cursorWidth) / 2
        let originY = (rect.height - cursorHeight) / 2

        // Create cursor arrow path
        let path = NSBezierPath()
        path.move(to: NSPoint(x: originX, y: originY + cursorHeight))
        path.line(to: NSPoint(x: originX, y: originY))
        path.line(to: NSPoint(x: originX + cursorWidth, y: originY + cursorHeight * 0.65))
        path.line(to: NSPoint(x: originX + cursorWidth * 0.55, y: originY + cursorHeight * 0.55))
        path.line(to: NSPoint(x: originX + cursorWidth * 0.85, y: originY + cursorHeight * 0.25))
        path.line(to: NSPoint(x: originX + cursorWidth * 0.65, y: originY + cursorHeight * 0.15))
        path.line(to: NSPoint(x: originX + cursorWidth * 0.35, y: originY + cursorHeight * 0.45))
        path.close()

        // Draw shadow if enabled
        if settings.shadowEnabled {
            let context = NSGraphicsContext.current?.cgContext
            context?.saveGState()
            context?.setShadow(
                offset: CGSize(width: 1, height: -1),
                blur: 2,
                color: NSColor.black.withAlphaComponent(0.5).cgColor
            )
            NSColor.black.withAlphaComponent(0.3).setFill()
            path.fill()
            context?.restoreGState()
        }

        // Draw glow if enabled
        if settings.glowEnabled && settings.glowRadius > 0 {
            let glowColor = NSColor(
                red: CGFloat(settings.glowColor.red),
                green: CGFloat(settings.glowColor.green),
                blue: CGFloat(settings.glowColor.blue),
                alpha: 0.6
            )

            let context = NSGraphicsContext.current?.cgContext
            context?.saveGState()
            context?.setShadow(
                offset: .zero,
                blur: CGFloat(settings.glowRadius / 2), // Scale down for menu bar
                color: glowColor.cgColor
            )
            color.setFill()
            path.fill()
            context?.restoreGState()
        }

        // Draw the main cursor fill
        color.setFill()
        path.fill()

        // Draw outline for visibility
        let outlineColor: NSColor
        if settings.contrastMode == .outline, let customOutline = settings.outlineColor {
            outlineColor = NSColor(
                red: CGFloat(customOutline.red),
                green: CGFloat(customOutline.green),
                blue: CGFloat(customOutline.blue),
                alpha: CGFloat(customOutline.alpha)
            )
        } else {
            // Auto outline based on color brightness
            outlineColor = settings.cursorColor.brightness > 0.5 ?
                NSColor.black.withAlphaComponent(0.8) :
                NSColor.white.withAlphaComponent(0.8)
        }

        outlineColor.setStroke()
        path.lineWidth = 0.75
        path.stroke()
    }

    /// Generate a preset preview icon
    public func generatePresetIcon(for preset: CursorPreset) -> NSImage {
        var settings = CursorSettings.defaults
        settings.applyPreset(preset)
        return generateIcon(for: settings)
    }
}
