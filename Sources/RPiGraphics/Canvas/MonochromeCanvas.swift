import Foundation

public protocol MonochromeCanvas: AnyObject, Sendable {
    var size: Size { get }
    func clear(color: PixelColor)
    func setPixel(at point: Point, color: PixelColor)
    func getPixel(at point: Point) -> PixelColor
}

extension MonochromeCanvas {
    public func setPixel(x: Int, y: Int, color: PixelColor) {
        setPixel(at: Point(x: x, y: y), color: color)
    }

    public func setPixel(x: Int, y: Int, isOn: Bool) {
        setPixel(at: Point(x: x, y: y), color: isOn ? .on : .off)
    }

    public func setPixel(x: Int, y: Int, isBlack: Bool) {
        setPixel(at: Point(x: x, y: y), color: isBlack ? .on : .off)
    }

    public func drawHorizontalLine(y: Int, from startX: Int = 0, to endX: Int? = nil, color: PixelColor = .on) {
        let limitX = endX ?? size.width
        guard y >= 0 && y < size.height else { return }
        for x in Swift.max(0, startX)..<Swift.min(size.width, limitX) {
            setPixel(at: Point(x: x, y: y), color: color)
        }
    }

    public func drawVerticalLine(x: Int, from startY: Int = 0, to endY: Int? = nil, color: PixelColor = .on) {
        let limitY = endY ?? size.height
        guard x >= 0 && x < size.width else { return }
        for y in Swift.max(0, startY)..<Swift.min(size.height, limitY) {
            setPixel(at: Point(x: x, y: y), color: color)
        }
    }

    public func drawRect(_ rect: Rect, color: PixelColor = .on) {
        drawHorizontalLine(y: rect.minY, from: rect.minX, to: rect.maxX, color: color)
        drawHorizontalLine(y: rect.maxY - 1, from: rect.minX, to: rect.maxX, color: color)
        drawVerticalLine(x: rect.minX, from: rect.minY, to: rect.maxY, color: color)
        drawVerticalLine(x: rect.maxX - 1, from: rect.minY, to: rect.maxY, color: color)
    }
}
