import Foundation
import RPiHAL

/// An in-memory RGB565 drawing surface, useful for off-screen composition,
/// tests, and previews.
public final class ColorFrameBuffer: ColorCanvas, @unchecked Sendable {
    private let lock = Lock()
    public let size: Size
    private var pixels: [RGB565]

    public init(size: Size, initialColor: RGB565 = .black) {
        self.size = size
        self.pixels = [RGB565](repeating: initialColor, count: size.width * size.height)
    }

    public convenience init(width: Int, height: Int, initialColor: RGB565 = .black) {
        self.init(size: Size(width: width, height: height), initialColor: initialColor)
    }

    public func clear(color: RGB565) {
        lock.withLock {
            for i in 0..<pixels.count {
                pixels[i] = color
            }
        }
    }

    public func setPixel(at point: Point, color: RGB565) {
        guard point.x >= 0 && point.x < size.width && point.y >= 0 && point.y < size.height else {
            return
        }
        lock.withLock {
            pixels[point.y * size.width + point.x] = color
        }
    }

    public func getPixel(at point: Point) -> RGB565 {
        guard point.x >= 0 && point.x < size.width && point.y >= 0 && point.y < size.height else {
            return .black
        }
        return lock.withLock {
            pixels[point.y * size.width + point.x]
        }
    }

    /// A copy of the raw pixel data in row-major order.
    public func snapshot() -> [RGB565] {
        lock.withLock { pixels }
    }
}
