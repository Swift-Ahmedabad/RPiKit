import Foundation
import RPiHAL

public final class FrameBuffer: MonochromeCanvas, @unchecked Sendable {
    private let lock = Lock()
    public let size: Size
    private var pixels: [PixelColor]

    public init(size: Size, initialColor: PixelColor = .off) {
        self.size = size
        self.pixels = [PixelColor](repeating: initialColor, count: size.width * size.height)
    }

    public convenience init(width: Int, height: Int, initialColor: PixelColor = .off) {
        self.init(size: Size(width: width, height: height), initialColor: initialColor)
    }

    public func clear(color: PixelColor) {
        lock.withLock {
            for i in 0..<pixels.count {
                pixels[i] = color
            }
        }
    }

    public func setPixel(at point: Point, color: PixelColor) {
        guard point.x >= 0 && point.x < size.width && point.y >= 0 && point.y < size.height else {
            return
        }
        lock.withLock {
            let index = point.y * size.width + point.x
            pixels[index] = color
        }
    }

    public func getPixel(at point: Point) -> PixelColor {
        guard point.x >= 0 && point.x < size.width && point.y >= 0 && point.y < size.height else {
            return .off
        }
        return lock.withLock {
            let index = point.y * size.width + point.x
            return pixels[index]
        }
    }
}
