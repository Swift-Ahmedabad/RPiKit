import Testing
@testable import RPiGraphics

@Suite("Graphics & Typography Tests")
struct GraphicsTests {

    @Test("FrameBuffer pixel manipulation and clear")
    func testFrameBuffer() {
        let buffer = FrameBuffer(size: Size(width: 16, height: 16), initialColor: .off)
        #expect(buffer.getPixel(at: Point(0, 0)) == .off)

        buffer.setPixel(at: Point(5, 5), color: .on)
        #expect(buffer.getPixel(at: Point(5, 5)) == .on)
        #expect(buffer.getPixel(at: Point(5, 4)) == .off)

        buffer.clear(color: .on)
        #expect(buffer.getPixel(at: Point(0, 0)) == .on)
        #expect(buffer.getPixel(at: Point(15, 15)) == .on)
    }

    @Test("TextRenderer text width calculation")
    func testTextMeasurement() {
        let titleWidth = TextRenderer.textWidth("Raspberry Pi", font: .title20)
        #expect(titleWidth > 0)

        let labelWidth = TextRenderer.textWidth("123", font: .label11)
        #expect(labelWidth > 0)
        #expect(titleWidth > labelWidth)

        let bitmapWidth = TextRenderer.textWidth("HELLO", font: .font8x8, scale: 1)
        #expect(bitmapWidth == 5 * 8)
    }

    @Test("TextRenderer alignment rendering")
    func testTextAlignmentRendering() {
        let buffer = FrameBuffer(size: Size(width: 128, height: 64))

        // Left alignment
        TextRenderer.draw("OK", into: buffer, at: Point(0, 0), font: .label11, alignment: .left)
        // Ensure at least one pixel is turned on
        var onPixelCount = 0
        for y in 0..<20 {
            for x in 0..<30 {
                if buffer.getPixel(at: Point(x, y)) == .on {
                    onPixelCount += 1
                }
            }
        }
        #expect(onPixelCount > 0)
    }

    @Test("RGB565 packing and channel extraction")
    func testRGB565() {
        #expect(RGB565.black.rawValue == 0x0000)
        #expect(RGB565.white.rawValue == 0xFFFF)

        let orange = RGB565(hex: 0xFF8000)
        #expect(orange.red == 0xFF)
        #expect(abs(Int(orange.green) - 0x80) <= 3)
        #expect(orange.blue == 0x00)
        #expect(orange.bigEndianBytes.high == 0xFC)

        // 5/6-bit channels expand back to their full 8-bit range.
        #expect(RGB565(red: 255, green: 255, blue: 255).green == 255)
    }

    @Test("ColorFrameBuffer drawing and colour text")
    func testColorFrameBuffer() {
        let buffer = ColorFrameBuffer(width: 64, height: 32)
        #expect(buffer.getPixel(at: Point(0, 0)) == .black)

        buffer.setPixel(at: Point(1, 1), color: .red)
        #expect(buffer.getPixel(at: Point(1, 1)) == .red)

        buffer.fillRect(Rect(x: 10, y: 10, width: 5, height: 5), color: .green)
        #expect(buffer.getPixel(at: Point(14, 14)) == .green)
        #expect(buffer.getPixel(at: Point(15, 15)) == .black)

        buffer.clear()
        buffer.drawString("HI", atX: 0, y: 0, font: .font8x8, color: .yellow)

        var yellowPixels = 0
        for y in 0..<16 {
            for x in 0..<32 where buffer.getPixel(at: Point(x, y)) == .yellow {
                yellowPixels += 1
            }
        }
        #expect(yellowPixels > 0)
    }

    @Test("Font presets compatibility")
    func testFontPresets() {
        #expect(ProportionalFont.title20.name == "title20")
        #expect(ProportionalFont.label11.name == "label11")
        #expect(ProportionalFont.counter44.name == "counter44")
        #expect(ProportionalFont.roundedBold18.name == "roundedBold18")
        #expect(ProportionalFont.label9.name == "label9")
        #expect(BitmapFont.menlo12.name == "menlo12")
        #expect(BitmapFont.font8x8.name == "font8x8")
    }
}
