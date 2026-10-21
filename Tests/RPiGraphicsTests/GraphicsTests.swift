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
