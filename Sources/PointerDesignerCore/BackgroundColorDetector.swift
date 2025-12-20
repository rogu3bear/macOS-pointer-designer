import Foundation
import CoreGraphics
import AppKit

/// Samples screen colors at cursor position for contrast detection
public final class BackgroundColorDetector {
    private let sampleSize: CGFloat = 5

    public init() {}

    /// Sample the average color at a given screen position
    public func sampleColor(at point: CGPoint) -> CursorColor? {
        let sampleRect = CGRect(
            x: point.x - sampleSize / 2,
            y: point.y - sampleSize / 2,
            width: sampleSize,
            height: sampleSize
        )

        guard let image = CGWindowListCreateImage(
            sampleRect,
            .optionOnScreenBelowWindow,
            kCGNullWindowID,
            [.bestResolution, .boundsIgnoreFraming]
        ) else {
            return nil
        }

        return averageColor(of: image)
    }

    /// Calculate the average color of an image
    private func averageColor(of image: CGImage) -> CursorColor? {
        let width = image.width
        let height = image.height
        let totalPixels = width * height

        guard totalPixels > 0 else { return nil }

        let colorSpace = CGColorSpaceCreateDeviceRGB()
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

        for y in 0..<height {
            for x in 0..<width {
                let offset = (y * bytesPerRow) + (x * bytesPerPixel)
                totalRed += Int(rawData[offset])
                totalGreen += Int(rawData[offset + 1])
                totalBlue += Int(rawData[offset + 2])
            }
        }

        return CursorColor(
            red: Float(totalRed) / Float(totalPixels * 255),
            green: Float(totalGreen) / Float(totalPixels * 255),
            blue: Float(totalBlue) / Float(totalPixels * 255)
        )
    }

    /// Sample multiple points around cursor for more accurate detection
    public func sampleColorWithContext(at point: CGPoint, radius: CGFloat = 10) -> CursorColor? {
        let samplePoints: [CGPoint] = [
            point,
            CGPoint(x: point.x - radius, y: point.y),
            CGPoint(x: point.x + radius, y: point.y),
            CGPoint(x: point.x, y: point.y - radius),
            CGPoint(x: point.x, y: point.y + radius)
        ]

        var colors: [CursorColor] = []

        for samplePoint in samplePoints {
            if let color = sampleColor(at: samplePoint) {
                colors.append(color)
            }
        }

        guard !colors.isEmpty else { return nil }

        let avgRed = colors.reduce(0) { $0 + $1.red } / Float(colors.count)
        let avgGreen = colors.reduce(0) { $0 + $1.green } / Float(colors.count)
        let avgBlue = colors.reduce(0) { $0 + $1.blue } / Float(colors.count)

        return CursorColor(red: avgRed, green: avgGreen, blue: avgBlue)
    }
}
