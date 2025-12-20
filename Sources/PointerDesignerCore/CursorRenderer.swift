import Foundation
import AppKit
import CoreGraphics

/// Renders custom cursor images with color and outline options
public final class CursorRenderer {
    private var settings: CursorSettings = .defaults

    // Standard macOS arrow cursor dimensions
    private let cursorWidth: CGFloat = 24
    private let cursorHeight: CGFloat = 24
    private let scale: CGFloat = 2.0 // Retina

    public init() {}

    public func configure(with settings: CursorSettings) {
        self.settings = settings
    }

    /// Render a cursor image with specified color and optional outline
    public func renderCursor(
        color: CursorColor,
        outlineColor: CursorColor?,
        outlineWidth: Float
    ) -> NSImage? {
        let size = NSSize(
            width: cursorWidth * scale,
            height: cursorHeight * scale
        )

        let image = NSImage(size: size)
        image.lockFocus()

        guard let context = NSGraphicsContext.current?.cgContext else {
            image.unlockFocus()
            return nil
        }

        context.scaleBy(x: scale, y: scale)

        // Draw outline first if enabled
        if let outline = outlineColor, outlineWidth > 0 {
            drawCursorPath(in: context, color: outline, inflate: CGFloat(outlineWidth))
        }

        // Draw main cursor
        drawCursorPath(in: context, color: color, inflate: 0)

        image.unlockFocus()
        return image
    }

    private func drawCursorPath(in context: CGContext, color: CursorColor, inflate: CGFloat) {
        let nsColor = NSColor(
            red: CGFloat(color.red),
            green: CGFloat(color.green),
            blue: CGFloat(color.blue),
            alpha: CGFloat(color.alpha)
        )

        context.setFillColor(nsColor.cgColor)
        context.setStrokeColor(NSColor.black.withAlphaComponent(0.3).cgColor)
        context.setLineWidth(0.5)

        // Arrow cursor path (standard macOS pointer shape)
        let path = CGMutablePath()

        // Inflate path for outline
        let offset = inflate

        // Arrow shape vertices
        let tipX: CGFloat = 1 + offset
        let tipY: CGFloat = 1 + offset

        path.move(to: CGPoint(x: tipX, y: tipY))
        path.addLine(to: CGPoint(x: tipX, y: tipY + 17 - offset * 2))
        path.addLine(to: CGPoint(x: tipX + 4, y: tipY + 13))
        path.addLine(to: CGPoint(x: tipX + 7, y: tipY + 20 - offset))
        path.addLine(to: CGPoint(x: tipX + 9, y: tipY + 19 - offset))
        path.addLine(to: CGPoint(x: tipX + 6, y: tipY + 12))
        path.addLine(to: CGPoint(x: tipX + 11 - offset, y: tipY + 12))
        path.closeSubpath()

        context.addPath(path)
        context.fillPath()

        // Add subtle border for definition
        context.addPath(path)
        context.strokePath()
    }

    /// Create a cursor with dynamic shadow based on background
    public func renderCursorWithShadow(
        color: CursorColor,
        shadowColor: CursorColor,
        shadowOffset: CGFloat = 1
    ) -> NSImage? {
        let size = NSSize(
            width: (cursorWidth + 4) * scale,
            height: (cursorHeight + 4) * scale
        )

        let image = NSImage(size: size)
        image.lockFocus()

        guard let context = NSGraphicsContext.current?.cgContext else {
            image.unlockFocus()
            return nil
        }

        context.scaleBy(x: scale, y: scale)

        // Draw shadow
        context.saveGState()
        context.translateBy(x: shadowOffset, y: shadowOffset)
        drawCursorPath(in: context, color: shadowColor.inverted, inflate: 1)
        context.restoreGState()

        // Draw main cursor
        drawCursorPath(in: context, color: color, inflate: 0)

        image.unlockFocus()
        return image
    }
}
