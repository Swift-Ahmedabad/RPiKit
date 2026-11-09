import Testing
@testable import RPiHAL
@testable import RPiGraphics
@testable import RPiDisplays

@Suite("Display Drivers Tests")
struct DisplayTests {

    @Test("SSD1306 initialization and display commands")
    func testSSD1306() throws {
        let mockBus = MockI2CBus()
        let display = SSD1306(bus: mockBus, address: 0x3C)

        try display.initialize()
        #expect(!mockBus.transactions.isEmpty)

        display.clear()
        display.drawString("RPi", atX: 0, y: 0, font: .label11)
        try display.display()

        // Verify page commands and data packets were written
        #expect(mockBus.transactions.count > 8)
    }

    @Test("SSD1681 E-Paper initialization and buffer flush")
    func testSSD1681() throws {
        let mockSPI = MockSPIBus()
        let rst = MockGPIOPin(pinNumber: 17)
        let dc = MockGPIOPin(pinNumber: 25)
        let cs = MockGPIOPin(pinNumber: 8)
        let busy = MockGPIOPin(pinNumber: 24)

        let epaper = SSD1681(spi: mockSPI, rst: rst, dc: dc, cs: cs, busy: busy)

        try epaper.initialize()
        #expect(!mockSPI.writtenBytes.isEmpty)

        epaper.clear()
        epaper.drawString("EPD", atX: 10, y: 10, font: .title20)
        try epaper.display()

        // Verify 0x24 and 0x26 were sent along with frame buffer chunks
        #expect(mockSPI.writtenBytes.contains(0x24))
        #expect(mockSPI.writtenBytes.contains(0x26))
        #expect(mockSPI.writtenBytes.contains(0x22))
        #expect(mockSPI.writtenBytes.contains(0x20))
    }

    @Test("ST7735 TFT initialization and RGB565 flush")
    func testST7735() throws {
        let mockSPI = MockSPIBus()
        let rst = MockGPIOPin(pinNumber: 24)
        let dc = MockGPIOPin(pinNumber: 25)
        let cs = MockGPIOPin(pinNumber: 8)
        let backlight = MockGPIOPin(pinNumber: 18)

        let tft = ST7735(spi: mockSPI, rst: rst, dc: dc, cs: cs, backlight: backlight)

        try tft.initialize()
        #expect(tft.size == Size(width: 128, height: 160))
        #expect(backlight.state == .high)
        #expect(!mockSPI.writtenBytes.isEmpty)

        tft.clear(color: .red)
        tft.drawRect(Rect(x: 0, y: 0, width: 128, height: 160), color: .blue)
        tft.drawString("TFT", atX: 4, y: 4, font: .title20, color: .white)
        #expect(tft.getPixel(at: Point(0, 0)) == .blue)

        try tft.display()

        // Software reset, sleep out, memory write, and 16-bit pixel format.
        #expect(mockSPI.writtenBytes.contains(0x01))
        #expect(mockSPI.writtenBytes.contains(0x11))
        #expect(mockSPI.writtenBytes.contains(0x2C))
        #expect(mockSPI.writtenBytes.contains(0x3A))
    }

    @Test("ST7735 supports runtime rotation")
    func testST7735Rotation() throws {
        let tft = ST7735(
            spi: MockSPIBus(),
            rst: MockGPIOPin(pinNumber: 24),
            dc: MockGPIOPin(pinNumber: 25)
        )
        try tft.initialize()
        #expect(tft.size == Size(width: 128, height: 160))

        try tft.setRotation(.landscape)
        #expect(tft.size == Size(width: 160, height: 128))

        tft.setPixel(at: Point(159, 127), color: .cyan)
        #expect(tft.getPixel(at: Point(159, 127)) == .cyan)
        #expect(tft.getPixel(at: Point(160, 0)) == .black)
    }

    @Test("VirtualDisplay ASCII preview")
    func testVirtualDisplay() throws {
        let virtual = VirtualDisplay(size: Size(width: 32, height: 16))
        try virtual.initialize()
        virtual.drawString("HI", atX: 0, y: 0, font: .font8x8)
        let preview = virtual.asciiPreview()
        #expect(preview.contains("+--------------------------------+"))
        #expect(preview.contains("#"))
    }
}
