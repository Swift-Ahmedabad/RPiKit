import Foundation

public struct TextRenderer {

    // MARK: - Measurement

    public static func textWidth(_ text: String, font: ProportionalFont) -> Int {
        var width = 0
        for char in text {
            guard let ascii = char.asciiValue, let glyph = font.glyph(for: ascii) else { continue }
            width += Int(glyph.advance)
        }
        return width
    }

    public static func textWidth(_ text: String, font: BitmapFont, scale: Int = 1) -> Int {
        var maxLineChars = 0
        var currentLineChars = 0
        for char in text {
            if char == "\n" {
                maxLineChars = max(maxLineChars, currentLineChars)
                currentLineChars = 0
            } else {
                currentLineChars += 1
            }
        }
        maxLineChars = max(maxLineChars, currentLineChars)
        return maxLineChars * font.width * scale
    }

    // MARK: - Monochrome Rendering

    public static func draw(
        _ text: String,
        into canvas: MonochromeCanvas,
        at origin: Point,
        font: ProportionalFont,
        alignment: TextAlignment = .left,
        maxWidth: Int? = nil,
        color: PixelColor = .on
    ) {
        drawProportional(
            text,
            canvasSize: canvas.size,
            at: origin,
            font: font,
            alignment: alignment,
            maxWidth: maxWidth
        ) { point in
            canvas.setPixel(at: point, color: color)
        }
    }

    public static func draw(
        _ text: String,
        into canvas: MonochromeCanvas,
        at origin: Point,
        font: BitmapFont,
        scale: Int = 1,
        alignment: TextAlignment = .left,
        maxWidth: Int? = nil,
        color: PixelColor = .on
    ) {
        drawBitmap(
            text,
            canvasSize: canvas.size,
            at: origin,
            font: font,
            scale: scale,
            alignment: alignment,
            maxWidth: maxWidth
        ) { point in
            canvas.setPixel(at: point, color: color)
        }
    }

    public static func drawChar(
        _ char: Character,
        into canvas: MonochromeCanvas,
        at origin: Point,
        font: BitmapFont,
        scale: Int = 1,
        color: PixelColor = .on
    ) {
        drawGlyph(char, at: origin, font: font, scale: scale) { point in
            canvas.setPixel(at: point, color: color)
        }
    }

    // MARK: - Colour Rendering

    public static func draw(
        _ text: String,
        into canvas: ColorCanvas,
        at origin: Point,
        font: ProportionalFont,
        alignment: TextAlignment = .left,
        maxWidth: Int? = nil,
        color: RGB565
    ) {
        drawProportional(
            text,
            canvasSize: canvas.size,
            at: origin,
            font: font,
            alignment: alignment,
            maxWidth: maxWidth
        ) { point in
            canvas.setPixel(at: point, color: color)
        }
    }

    public static func draw(
        _ text: String,
        into canvas: ColorCanvas,
        at origin: Point,
        font: BitmapFont,
        scale: Int = 1,
        alignment: TextAlignment = .left,
        maxWidth: Int? = nil,
        color: RGB565
    ) {
        drawBitmap(
            text,
            canvasSize: canvas.size,
            at: origin,
            font: font,
            scale: scale,
            alignment: alignment,
            maxWidth: maxWidth
        ) { point in
            canvas.setPixel(at: point, color: color)
        }
    }

    public static func drawChar(
        _ char: Character,
        into canvas: ColorCanvas,
        at origin: Point,
        font: BitmapFont,
        scale: Int = 1,
        color: RGB565
    ) {
        drawGlyph(char, at: origin, font: font, scale: scale) { point in
            canvas.setPixel(at: point, color: color)
        }
    }

    // MARK: - Shared Layout & Rasterisation

    private static func drawProportional(
        _ text: String,
        canvasSize: Size,
        at origin: Point,
        font: ProportionalFont,
        alignment: TextAlignment,
        maxWidth: Int?,
        setPixel: (Point) -> Void
    ) {
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        var cursorY = origin.y
        let boundaryWidth = maxWidth ?? (canvasSize.width - origin.x)

        for line in lines {
            let lineWidth = textWidth(line, font: font)
            let startX: Int
            switch alignment {
            case .left:
                startX = origin.x
            case .center:
                startX = origin.x + max(0, (boundaryWidth - lineWidth) / 2)
            case .right:
                startX = origin.x + max(0, boundaryWidth - lineWidth)
            }

            var cursorX = startX
            for char in line {
                guard let ascii = char.asciiValue, let glyph = font.glyph(for: ascii) else { continue }

                // Auto-wrap if exceeding boundary
                if cursorX + Int(glyph.advance) > origin.x + boundaryWidth {
                    cursorX = startX
                    cursorY += font.lineHeight
                }
                if cursorY + Int(glyph.height) > canvasSize.height {
                    return
                }

                if glyph.width > 0 && glyph.height > 0 {
                    let bytesPerRow = (Int(glyph.width) + 7) / 8
                    for row in 0..<Int(glyph.height) {
                        let rowOffset = row * bytesPerRow
                        for col in 0..<Int(glyph.width) {
                            let byteIndex = rowOffset + (col / 8)
                            let bitIndex = 7 - (col % 8)
                            let isSet = (glyph.bytes[byteIndex] & (1 << bitIndex)) != 0
                            if isSet {
                                let px = cursorX + Int(glyph.left) + col
                                let py = cursorY + Int(glyph.top) + row
                                setPixel(Point(px, py))
                            }
                        }
                    }
                }
                cursorX += Int(glyph.advance)
            }

            cursorY += font.lineHeight
        }
    }

    private static func drawBitmap(
        _ text: String,
        canvasSize: Size,
        at origin: Point,
        font: BitmapFont,
        scale: Int,
        alignment: TextAlignment,
        maxWidth: Int?,
        setPixel: (Point) -> Void
    ) {
        let lines = text.split(separator: "\n", omittingEmptySubsequences: false).map(String.init)
        var cursorY = origin.y
        let charWidth = font.width * scale
        let lineHeight = (font.height + 2) * scale
        let boundaryWidth = maxWidth ?? (canvasSize.width - origin.x)

        for line in lines {
            let lineWidth = line.count * charWidth
            let startX: Int
            switch alignment {
            case .left:
                startX = origin.x
            case .center:
                startX = origin.x + max(0, (boundaryWidth - lineWidth) / 2)
            case .right:
                startX = origin.x + max(0, boundaryWidth - lineWidth)
            }

            var cursorX = startX
            for char in line {
                if cursorX + charWidth > origin.x + boundaryWidth {
                    cursorX = startX
                    cursorY += lineHeight
                }
                if cursorY + font.height * scale > canvasSize.height {
                    return
                }

                drawGlyph(char, at: Point(cursorX, cursorY), font: font, scale: scale, setPixel: setPixel)
                cursorX += charWidth
            }
            cursorY += lineHeight
        }
    }

    private static func drawGlyph(
        _ char: Character,
        at origin: Point,
        font: BitmapFont,
        scale: Int,
        setPixel: (Point) -> Void
    ) {
        guard let asciiValue = char.asciiValue, asciiValue >= 32 && asciiValue <= 126 else { return }
        let fontIndex = Int(asciiValue - 32)
        guard fontIndex < font.glyphs.count else { return }
        let glyph = font.glyphs[fontIndex]

        for row in 0..<font.height {
            let rowOffset = row * font.bytesPerRow
            for col in 0..<font.width {
                let byteIndex = rowOffset + (col / 8)
                let bitIndex = 7 - (col % 8)
                let isPixelSet = (glyph[byteIndex] & (1 << bitIndex)) != 0
                if isPixelSet {
                    if scale == 1 {
                        setPixel(Point(origin.x + col, origin.y + row))
                    } else {
                        for dy in 0..<scale {
                            for dx in 0..<scale {
                                setPixel(Point(origin.x + (col * scale) + dx, origin.y + (row * scale) + dy))
                            }
                        }
                    }
                }
            }
        }
    }
}

// MARK: - MonochromeCanvas Convenience Extension

extension MonochromeCanvas {
    public func drawString(
        _ text: String,
        at origin: Point,
        font: ProportionalFont,
        alignment: TextAlignment = .left,
        maxWidth: Int? = nil,
        color: PixelColor = .on
    ) {
        TextRenderer.draw(text, into: self, at: origin, font: font, alignment: alignment, maxWidth: maxWidth, color: color)
    }

    public func drawString(
        _ text: String,
        atX x: Int,
        y: Int,
        font: ProportionalFont,
        alignment: TextAlignment = .left,
        maxWidth: Int? = nil,
        color: PixelColor = .on
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
        color: PixelColor = .on
    ) {
        TextRenderer.draw(text, into: self, at: origin, font: font, scale: scale, alignment: alignment, maxWidth: maxWidth, color: color)
    }

    public func drawString(
        _ text: String,
        atX x: Int,
        y: Int,
        font: BitmapFont,
        scale: Int = 1,
        alignment: TextAlignment = .left,
        maxWidth: Int? = nil,
        color: PixelColor = .on
    ) {
        drawString(text, at: Point(x, y), font: font, scale: scale, alignment: alignment, maxWidth: maxWidth, color: color)
    }

    public func textWidth(_ text: String, font: ProportionalFont) -> Int {
        TextRenderer.textWidth(text, font: font)
    }

    public func textWidth(_ text: String, font: BitmapFont, scale: Int = 1) -> Int {
        TextRenderer.textWidth(text, font: font, scale: scale)
    }
}
