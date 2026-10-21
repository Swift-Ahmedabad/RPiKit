import Testing
@testable import RPiHAL

@Suite("Hardware Abstraction Layer Tests")
struct HALTests {

    @Test("Mock GPIO pin operations")
    func testMockGPIOPin() throws {
        let pin = MockGPIOPin(pinNumber: 27, initialState: .low)
        #expect(pin.pinNumber == 27)
        #expect(pin.isOpen == false)

        try pin.open(direction: .outputHigh, bias: .pullUp)
        #expect(pin.isOpen == true)
        #expect(try pin.read() == .high)

        try pin.write(.low)
        #expect(try pin.read() == .low)
        #expect(pin.writeHistory == [.high, .low])

        pin.simulateInput(.high)
        #expect(try pin.read() == .high)

        pin.close()
        #expect(pin.isOpen == false)
    }

    @Test("Mock I2C bus transactions")
    func testMockI2CBus() throws {
        let bus = MockI2CBus(devicePath: "/dev/i2c-1")
        try bus.open()
        #expect(bus.isOpen)

        try bus.write(to: 0x3C, data: [0x00, 0xAF])
        #expect(bus.transactions.count == 1)
        #expect(bus.transactions[0].address == 0x3C)
        #expect(bus.transactions[0].data == [0x00, 0xAF])

        bus.clearHistory()
        #expect(bus.transactions.isEmpty)
        bus.close()
        #expect(!bus.isOpen)
    }

    @Test("Mock SPI bus transactions")
    func testMockSPIBus() throws {
        let bus = MockSPIBus(path: "/dev/spidev0.0")
        try bus.open()
        #expect(bus.isOpen)

        try bus.writeByte(0x12)
        try bus.write([0x01, 0x02, 0x03])
        #expect(bus.writtenBytes == [0x12, 0x01, 0x02, 0x03])

        bus.clearHistory()
        #expect(bus.writtenBytes.isEmpty)
        bus.close()
        #expect(!bus.isOpen)
    }
}
