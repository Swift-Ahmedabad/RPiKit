import Foundation

/// A drawable, colour (RGB565) surface.
public protocol ColorCanvas: AnyObject, Sendable {
    var size: Size { get }
    func clear(color: RGB565)
    func setPixel(at point: Point, color: RGB565)
    func getPixel(at point: Point) -> RGB565
}

extension ColorCanvas {
    public func clear() {
        clear(color: .black)
    }

    public func setPixel(x: Int, y: Int, color: RGB565) {
        setPixel(at: Point(x: x, y: y), color: color)
    }

    public func fill(_ color: RGB565) {
        clear(color: color)
    }

    public func drawHorizontalLine(y: Int, from startX: Int = 0, to endX: Int? = nil, color: RGB565) {
        let limitX = endX ?? size.width
        guard y >= 0 && y < size.height else { return }
        for x in Swift.max(0, startX)..<Swift.min(size.width, limitX) {
            setPixel(at: Point(x: x, y: y), color: color)
        }
    }

    public func drawVerticalLine(x: Int, from startY: Int = 0, to endY: Int? = nil, color: RGB565) {
        let limitY = endY ?? size.height
        guard x >= 0 && x < size.width else { return }
        for y in Swift.max(0, startY)..<Swift.min(size.height, limitY) {
            setPixel(at: Point(x: x, y: y), color: color)
        }
    }

    public func drawRect(_ rect: Rect, color: RGB565) {
        drawHorizontalLine(y: rect.minY, from: rect.minX, to: rect.maxX, color: color)
        drawHorizontalLine(y: rect.maxY - 1, from: rect.minX, to: rect.maxX, color: color)
        drawVerticalLine(x: rect.minX, from: rect.minY, to: rect.maxY, color: color)
        drawVerticalLine(x: rect.maxX - 1, from: rect.minY, to: rect.maxY, color: color)
    }

    public func fillRect(_ rect: Rect, color: RGB565) {
        let minX = Swift.max(0, rect.minX)
        let minY = Swift.max(0, rect.minY)
        let maxX = Swift.min(size.width, rect.maxX)
        let maxY = Swift.min(size.height, rect.maxY)
        guard minX < maxX && minY < maxY else { return }
        for y in minY..<maxY {
            for x in minX..<maxX {
                setPixel(at: Point(x: x, y: y), color: color)
            }
        }
    }

    // MARK: - Text

    public func drawString(
        _ text: String,
        at origin: Point,
        font: ProportionalFont,
        alignment: TextAlignment = .left,
        maxWidth: Int? = nil,
        color: RGB565
    ) {
        TextRenderer.draw(
            text,
            into: self,
            at: origin,
            font: font,
            alignment: alignment,
            maxWidth: maxWidth,
            color: color
        )
    }

    public func drawString(
        _ text: String,
        atX x: Int,
        y: Int,
        font: ProportionalFont,
        alignment: TextAlignment = .left,
        maxWidth: Int? = nil,
        color: RGB565
    ) {
        drawString(text, at: Point(x, y), font: font, alignment: alignment, maxWidth: maxWidth, color: color)
    }

    public func drawString(
        _ text: String,
        at origin: Point,
        font: BitmapFont,
        scale: Int = 1,
        alignment: TextAlignment = .left,
        maxWidth: Int? = nil,
        color: RGB565
    ) {
        TextRenderer.draw(
            text,
            into: self,
            at: origin,
            font: font,
            scale: scale,
            alignment: alignment,
            maxWidth: maxWidth,
            color: color
        )
    }

    public func drawString(
        _ text: String,
        atX x: Int,
        y: Int,
        font: BitmapFont,
        scale: Int = 1,
        alignment: TextAlignment = .left,
        maxWidth: Int? = nil,
        color: RGB565
    ) {
        drawString(
            text,
            at: Point(x, y),
            font: font,
            scale: scale,
            alignment: alignment,
            maxWidth: maxWidth,
            color: color
        )
    }

    public func textWidth(_ text: String, font: ProportionalFont) -> Int {
        TextRenderer.textWidth(text, font: font)
    }

    public func textWidth(_ text: String, font: BitmapFont, scale: Int = 1) -> Int {
        TextRenderer.textWidth(text, font: font, scale: scale)
    }
}
