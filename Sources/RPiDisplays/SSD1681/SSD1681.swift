import Foundation
import RPiHAL
import RPiLinux
import RPiGraphics

public typealias EPaper154 = SSD1681

/// Driver for a 200x200 Waveshare 1.54" SSD1681 E-Paper Display (SPI).
public final class SSD1681: MonochromeDisplay, @unchecked Sendable {
    public static let width = 200
    public static let height = 200
    public static let bufferSize = (width * height) / 8 // 5000 bytes

    public var size: Size {
        Size(width: Self.width, height: Self.height)
    }

    private let lock = Lock()
    private let spi: SPIBus
    private let rst: GPIOPin
    private let dc: GPIOPin
    private let cs: GPIOPin
    private let busy: GPIOPin
    private var frameBuffer: [UInt8]

    public init(spi: SPIBus, rst: GPIOPin, dc: GPIOPin, cs: GPIOPin, busy: GPIOPin) {
        self.spi = spi
        self.rst = rst
        self.dc = dc
        self.cs = cs
        self.busy = busy
        self.frameBuffer = [UInt8](repeating: 0xFF, count: Self.bufferSize)

        try? rst.open(direction: .outputHigh)
        try? dc.open(direction: .outputLow)
        try? cs.open(direction: .outputHigh)
        try? busy.open(direction: .input)
        try? spi.open()
    }

    #if os(Linux)
    public convenience init(
        spiPath: String = "/dev/spidev0.0",
        rstPin: Int = 17,
        dcPin: Int = 25,
        csPin: Int = 8,
        busyPin: Int = 24
    ) {
        let spi = LinuxSPI(path: spiPath)
        let rst = LinuxGPIO(pinNumber: rstPin)
        let dc = LinuxGPIO(pinNumber: dcPin)
        let cs = LinuxGPIO(pinNumber: csPin)
        let busy = LinuxGPIO(pinNumber: busyPin)
        self.init(spi: spi, rst: rst, dc: dc, cs: cs, busy: busy)
    }
    #else
    public convenience init(
        spiPath: String = "/dev/spidev0.0",
        rstPin: Int = 17,
        dcPin: Int = 25,
        csPin: Int = 8,
        busyPin: Int = 24
    ) {
        let spi = MockSPIBus(path: spiPath)
        let rst = MockGPIOPin(pinNumber: rstPin, initialState: .high)
        let dc = MockGPIOPin(pinNumber: dcPin, initialState: .low)
        let cs = MockGPIOPin(pinNumber: csPin, initialState: .high)
        let busy = MockGPIOPin(pinNumber: busyPin, initialState: .low)
        self.init(spi: spi, rst: rst, dc: dc, cs: cs, busy: busy)
    }
    #endif

    // MARK: - Low-level Communication

    private func sendCommand(_ command: UInt8) throws {
        try dc.write(.low)
        try cs.write(.low)
        try spi.writeByte(command)
        try cs.write(.high)
    }

    private func sendData(_ data: UInt8) throws {
        try dc.write(.high)
        try cs.write(.low)
        try spi.writeByte(data)
        try cs.write(.high)
    }

    private func sendBuffer(_ buffer: [UInt8]) throws {
        try dc.write(.high)
        try cs.write(.low)
        let chunkSize = 1000
        var offset = 0
        while offset < buffer.count {
            let count = min(chunkSize, buffer.count - offset)
            let chunk = Array(buffer[offset..<(offset + count)])
            try spi.write(chunk)
            offset += count
        }
        try cs.write(.high)
    }

    private func waitUntilIdle(timeoutSeconds: Double = 6.0) {
        let start = Date()
        while let state = try? busy.read(), state == .high {
            if Date().timeIntervalSince(start) > timeoutSeconds {
                print("SSD1681: Timeout (\(timeoutSeconds)s) waiting for BUSY pin. Proceeding.")
                break
            }
            Thread.sleep(forTimeInterval: 0.01)
        }
    }

    // MARK: - MonochromeCanvas Protocol

    public func clear(color: PixelColor = .off) {
        lock.lock()
        defer { lock.unlock() }
        let fill: UInt8 = color == .on ? 0x00 : 0xFF // In e-Paper: 0x00 is black, 0xFF is white
        for i in 0..<frameBuffer.count {
            frameBuffer[i] = fill
        }
    }

    public func setPixel(at point: Point, color: PixelColor) {
        guard point.x >= 0 && point.x < Self.width && point.y >= 0 && point.y < Self.height else { return }
        lock.lock()
        defer { lock.unlock() }
        let index = (point.x / 8) + (point.y * (Self.width / 8))
        let bit = 7 - (point.x % 8)
        if color == .on {
            frameBuffer[index] &= ~(1 << bit) // 0 is black
        } else {
            frameBuffer[index] |= (1 << bit)  // 1 is white
        }
    }

    public func getPixel(at point: Point) -> PixelColor {
        guard point.x >= 0 && point.x < Self.width && point.y >= 0 && point.y < Self.height else { return .off }
        lock.lock()
        defer { lock.unlock() }
        let index = (point.x / 8) + (point.y * (Self.width / 8))
        let bit = 7 - (point.x % 8)
        return ((frameBuffer[index] & (1 << bit)) == 0) ? .on : .off
    }

    // MARK: - Display Control

    public func reset() throws {
        try rst.write(.high)
        Thread.sleep(forTimeInterval: 0.05)
        try rst.write(.low)
        Thread.sleep(forTimeInterval: 0.01)
        try rst.write(.high)
        Thread.sleep(forTimeInterval: 0.05)
        waitUntilIdle(timeoutSeconds: 2.0)
    }

    public func initialize() throws {
        try reset()

        try sendCommand(0x12) // SWRESET
        waitUntilIdle(timeoutSeconds: 3.0)

        // Driver output control: 200 gate lines
        try sendCommand(0x01)
        try sendData(0xC7)
        try sendData(0x00)
        try sendData(0x00)

        // Data entry mode: 0x03 = X increment, Y increment
        try sendCommand(0x11)
        try sendData(0x03)

        // Set RAM-X address start/end: 0x00 -> 0x18 (25 bytes = 200 pixels)
        try sendCommand(0x44)
        try sendData(0x00)
        try sendData(0x18)

        // Set RAM-Y address start/end: 0 -> 199 (0xC7)
        try sendCommand(0x45)
        try sendData(0x00)
        try sendData(0x00)
        try sendData(0xC7)
        try sendData(0x00)

        // Border waveform control: White border (LUT1)
        try sendCommand(0x3C)
        try sendData(0x01)

        // Internal temperature sensor
        try sendCommand(0x18)
        try sendData(0x80)

        waitUntilIdle(timeoutSeconds: 2.0)
    }

    public func display() throws {
        lock.lock()
        let bufferCopy = frameBuffer
        lock.unlock()

        // 1. Reset RAM address pointers for 0x24 (Current frame)
        try sendCommand(0x4E)
        try sendData(0x00)
        try sendCommand(0x4F)
        try sendData(0x00)
        try sendData(0x00)

        try sendCommand(0x24)
        try sendBuffer(bufferCopy)

        // 2. Reset RAM address pointers for 0x26 (Previous frame)
        try sendCommand(0x4E)
        try sendData(0x00)
        try sendCommand(0x4F)
        try sendData(0x00)
        try sendData(0x00)

        try sendCommand(0x26)
        try sendBuffer(bufferCopy)

        // 3. Full refresh trigger
        try sendCommand(0x22)
        try sendData(0xF7)
        try sendCommand(0x20) // Master activation
        waitUntilIdle(timeoutSeconds: 8.0)
    }

    public func sleep() throws {
        try sendCommand(0x10) // Deep sleep
        try sendData(0x01)
    }
}
