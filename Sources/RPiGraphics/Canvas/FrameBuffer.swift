import Foundation

public final class FrameBuffer: MonochromeCanvas, @unchecked Sendable {
    private let lock = NSLock()
    public let size: Size
    public private(set) var bytes: [UInt8]

    public init(size: Size, initialColor: PixelColor = .off) {
        self.size = size
        let byteCount = (size.width * size.height + 7) / 8
        self.bytes = [UInt8](repeating: initialColor == .off ? 0x00 : 0xFF, count: byteCount)
    }

    public func clear(color: PixelColor) {
        lock.lock()
        defer { lock.unlock() }
        let fillByte: UInt8 = (color == .off) ? 0x00 : 0xFF
        for i in 0..<bytes.count {
            bytes[i] = fillByte
        }
    }

    public func setPixel(at point: Point, color: PixelColor) {
        guard point.x >= 0 && point.x < size.width && point.y >= 0 && point.y < size.height else { return }
        lock.lock()
        defer { lock.unlock() }
        let index = (point.y * size.width + point.x) / 8
        let bit = 7 - ((point.y * size.width + point.x) % 8)
        if color == .on {
            bytes[index] |= (1 << bit)
        } else {
            bytes[index] &= ~(1 << bit)
        }
    }

    public func getPixel(at point: Point) -> PixelColor {
        guard point.x >= 0 && point.x < size.width && point.y >= 0 && point.y < size.height else { return .off }
        lock.lock()
        defer { lock.unlock() }
        let index = (point.y * size.width + point.x) / 8
        let bit = 7 - ((point.y * size.width + point.x) % 8)
        return ((bytes[index] & (1 << bit)) != 0) ? .on : .off
    }
}
