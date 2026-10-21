import Foundation
import RPiGraphics

public final class VirtualDisplay: MonochromeDisplay, @unchecked Sendable {
    private let lock = NSLock()
    public let size: Size
    private let buffer: FrameBuffer

    public init(size: Size) {
        self.size = size
        self.buffer = FrameBuffer(size: size)
    }

    public func initialize() throws {
        clear(color: .off)
    }

    public func clear(color: PixelColor) {
        buffer.clear(color: color)
    }

    public func setPixel(at point: Point, color: PixelColor) {
        buffer.setPixel(at: point, color: color)
    }

    public func getPixel(at point: Point) -> PixelColor {
        buffer.getPixel(at: point)
    }

    public func display() throws {
        // In-memory flush
    }

    public func sleep() throws {}

    /// Renders an ASCII preview string of the current buffer.
    public func asciiPreview(scaleX: Int = 1, scaleY: Int = 1) -> String {
        lock.lock()
        defer { lock.unlock() }

        var output = "+" + String(repeating: "-", count: size.width / scaleX) + "+\n"
        for y in stride(from: 0, to: size.height, by: scaleY) {
            output += "|"
            for x in stride(from: 0, to: size.width, by: scaleX) {
                let pixel = buffer.getPixel(at: Point(x, y))
                output += pixel == .on ? "#" : " "
            }
            output += "|\n"
        }
        output += "+" + String(repeating: "-", count: size.width / scaleX) + "+\n"
        return output
    }
}
