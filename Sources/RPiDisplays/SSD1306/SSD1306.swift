import Foundation
import RPiHAL
import RPiLinux
import RPiGraphics

public typealias OLED1306 = SSD1306

/// Driver for a 128x64 SSD1306 OLED (0.96" module wired for I2C).
public final class SSD1306: MonochromeDisplay, @unchecked Sendable {
    public static let width = 128
    public static let height = 64
    public static let pages = 8
    public static let bufferSize = (width * height) / 8 // 1024 bytes

    public var size: Size {
        Size(width: Self.width, height: Self.height)
    }

    private static let controlCommand: UInt8 = 0x00
    private static let controlData: UInt8 = 0x40

    private let lock = Lock()
    private let bus: I2CBus
    private let address: UInt16
    private var frameBuffer: [UInt8]

    public init(bus: I2CBus, address: UInt16 = 0x3C) {
        self.bus = bus
        self.address = address
        self.frameBuffer = [UInt8](repeating: 0x00, count: Self.bufferSize)
    }

    #if os(Linux)
    public convenience init(devicePath: String = "/dev/i2c-1", address: UInt16 = 0x3C) {
        let linuxBus = LinuxI2C(devicePath: devicePath)
        try? linuxBus.open()
        self.init(bus: linuxBus, address: address)
    }
    #else
    public convenience init(devicePath: String = "/dev/i2c-1", address: UInt16 = 0x3C) {
        let mockBus = MockI2CBus(devicePath: devicePath)
        try? mockBus.open()
        self.init(bus: mockBus, address: address)
    }
    #endif

    // MARK: - Low-level Communication

    private func write(_ buffer: [UInt8]) throws {
        try bus.write(to: address, data: buffer)
    }

    private func sendCommands(_ commands: [UInt8]) throws {
        try write([Self.controlCommand] + commands)
    }

    // MARK: - MonochromeCanvas Protocol

    public func clear(color: PixelColor = .off) {
        lock.lock()
        defer { lock.unlock() }
        let fill: UInt8 = color == .on ? 0xFF : 0x00
        for i in 0..<frameBuffer.count {
            frameBuffer[i] = fill
        }
    }

    public func setPixel(at point: Point, color: PixelColor) {
        guard point.x >= 0 && point.x < Self.width && point.y >= 0 && point.y < Self.height else { return }
        lock.lock()
        defer { lock.unlock() }
        let index = (point.y / 8) * Self.width + point.x
        let bit = point.y % 8
        if color == .on {
            frameBuffer[index] |= (1 << bit)
        } else {
            frameBuffer[index] &= ~(1 << bit)
        }
    }

    public func getPixel(at point: Point) -> PixelColor {
        guard point.x >= 0 && point.x < Self.width && point.y >= 0 && point.y < Self.height else { return .off }
        lock.lock()
        defer { lock.unlock() }
        let index = (point.y / 8) * Self.width + point.x
        let bit = point.y % 8
        return ((frameBuffer[index] & (1 << bit)) != 0) ? .on : .off
    }

    // MARK: - Display Control

    public func initialize() throws {
        try sendCommands([
            0xAE,       // Display off while configuring
            0xD5, 0x80, // Clock divide ratio / oscillator frequency
            0xA8, 0x3F, // Multiplex ratio: 64 rows
            0xD3, 0x00, // Display offset: none
            0x40,       // Start line: 0
            0x8D, 0x14, // Charge pump: enabled (required, runs from VCC)
            0x20, 0x00, // Addressing mode: horizontal
            0xA1,       // Segment remap: column 127 maps to SEG0
            0xC8,       // COM output scan direction: remapped
            0xDA, 0x12, // COM pins hardware configuration for 128x64
            0x81, 0x7F, // Contrast
            0xD9, 0xF1, // Pre-charge period
            0xDB, 0x40, // VCOMH deselect level
            0xA4,       // Display follows RAM contents
            0xA6,       // Normal (non-inverted) display
            0xAF,       // Display on
        ])
    }

    public func display() throws {
        lock.lock()
        let bufferCopy = frameBuffer
        lock.unlock()

        // Set column and page addressing windows
        try sendCommands([0x21, 0x00, 0x7F, 0x22, 0x00, 0x07])

        for page in 0..<Self.pages {
            let start = page * Self.width
            var buffer = [UInt8](repeating: 0x00, count: Self.width + 1)
            buffer[0] = Self.controlData
            for offset in 0..<Self.width {
                buffer[offset + 1] = bufferCopy[start + offset]
            }
            try write(buffer)
        }
    }

    public func sleep() throws {
        try sendCommands([0xAE]) // Display off
    }
}
