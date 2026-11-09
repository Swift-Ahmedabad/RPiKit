import Foundation
import RPiHAL
import RPiLinux
import RPiGraphics

/// Alias for the common 1.8" 128x160 TFT modules.
public typealias TFT18 = ST7735

/// Controller name aliases used by different 1.8" module variants.
public typealias ST7735R = ST7735
public typealias ST7735S = ST7735

/// Driver for a 1.8" 128x160 RGB565 TFT using the ST7735/ST7735S controller.
///
/// The module uses the usual 8-pin SPI header:
/// `VCC`, `GND`, `CS`, `RESET`, `A0/DC`, `SDA/MOSI`, `SCK`, and `LED/BL`.
/// The backlight pin is optional: tie `LED` to 3.3V if it is not driven by GPIO.
///
/// The driver keeps an RGB565 framebuffer (`128 * 160 * 2` bytes) and flushes it
/// on `display()`. Rotation can be changed at runtime with `setRotation(_:)`.
public final class ST7735: ColorDisplay, @unchecked Sendable {
    public static let nativeWidth = 128
    public static let nativeHeight = 160
    public static let width = nativeWidth
    public static let height = nativeHeight
    public static let bufferSize = nativeWidth * nativeHeight

    /// Display orientation. Portrait is the module's native 128x160 layout.
    public enum Rotation: Sendable, Equatable {
        case portrait
        case landscape
        case portraitUpsideDown
        case landscapeUpsideDown
    }

    /// Whether the panel expects RGB or BGR channel order. If red and blue are
    /// swapped on your module, initialise it with `.bgr`.
    public enum ColorOrder: Sendable, Equatable {
        case rgb
        case bgr
    }

    private enum Command {
        static let softwareReset: UInt8 = 0x01
        static let sleepOut: UInt8 = 0x11
        static let normalMode: UInt8 = 0x13
        static let invertOff: UInt8 = 0x20
        static let invertOn: UInt8 = 0x21
        static let displayOff: UInt8 = 0x28
        static let displayOn: UInt8 = 0x29
        static let columnAddressSet: UInt8 = 0x2A
        static let rowAddressSet: UInt8 = 0x2B
        static let memoryWrite: UInt8 = 0x2C
        static let memoryAccessControl: UInt8 = 0x36
        static let pixelFormat: UInt8 = 0x3A
        static let sleepIn: UInt8 = 0x10
    }

    private let lock = Lock()
    private let spi: SPIBus
    private let rst: GPIOPin
    private let dc: GPIOPin
    private let cs: GPIOPin?
    private let backlight: GPIOPin?
    private let backlightActiveHigh: Bool
    private let colorOrder: ColorOrder
    private let xOffset: Int
    private let yOffset: Int

    private var _rotation: Rotation
    private var _isInverted: Bool
    private var frameBuffer: [UInt16]

    public var size: Size {
        lock.withLock { Self.size(for: _rotation) }
    }

    public var rotation: Rotation {
        lock.withLock { _rotation }
    }

    public var isInverted: Bool {
        lock.withLock { _isInverted }
    }

    public init(
        spi: SPIBus,
        rst: GPIOPin,
        dc: GPIOPin,
        cs: GPIOPin? = nil,
        backlight: GPIOPin? = nil,
        backlightActiveHigh: Bool = true,
        rotation: Rotation = .portrait,
        xOffset: Int = 0,
        yOffset: Int = 0,
        colorOrder: ColorOrder = .rgb,
        inverted: Bool = false
    ) {
        self.spi = spi
        self.rst = rst
        self.dc = dc
        self.cs = cs
        self.backlight = backlight
        self.backlightActiveHigh = backlightActiveHigh
        self.colorOrder = colorOrder
        self.xOffset = xOffset
        self.yOffset = yOffset
        self._rotation = rotation
        self._isInverted = inverted
        self.frameBuffer = [UInt16](repeating: RGB565.black.rawValue, count: Self.bufferSize)

        do {
            try ensureConfigured()
        } catch {
            print("ST7735: Initial configuration warning (will retry on initialize()): \(error)")
        }
    }

    #if os(Linux)
    public convenience init(
        chipPath: String = ProcessInfo.processInfo.environment["GPIO_CHIP"] ?? "/dev/gpiochip0",
        spiPath: String = "/dev/spidev0.0",
        rstPin: Int = 24,
        dcPin: Int = 25,
        csPin: Int? = nil,
        backlightPin: Int? = nil,
        backlightActiveHigh: Bool = true,
        rotation: Rotation = .portrait,
        xOffset: Int = 0,
        yOffset: Int = 0,
        colorOrder: ColorOrder = .rgb,
        inverted: Bool = false
    ) {
        let spi = LinuxSPI(path: spiPath)
        let rst = LinuxGPIO(chipPath: chipPath, pinNumber: rstPin)
        let dc = LinuxGPIO(chipPath: chipPath, pinNumber: dcPin)
        let cs = csPin.map { LinuxGPIO(chipPath: chipPath, pinNumber: $0) }
        let backlight = backlightPin.map { LinuxGPIO(chipPath: chipPath, pinNumber: $0) }
        self.init(
            spi: spi,
            rst: rst,
            dc: dc,
            cs: cs,
            backlight: backlight,
            backlightActiveHigh: backlightActiveHigh,
            rotation: rotation,
            xOffset: xOffset,
            yOffset: yOffset,
            colorOrder: colorOrder,
            inverted: inverted
        )
    }
    #else
    public convenience init(
        chipPath: String = "/dev/gpiochip0",
        spiPath: String = "/dev/spidev0.0",
        rstPin: Int = 24,
        dcPin: Int = 25,
        csPin: Int? = nil,
        backlightPin: Int? = nil,
        backlightActiveHigh: Bool = true,
        rotation: Rotation = .portrait,
        xOffset: Int = 0,
        yOffset: Int = 0,
        colorOrder: ColorOrder = .rgb,
        inverted: Bool = false
    ) {
        let spi = MockSPIBus(path: spiPath)
        let rst = MockGPIOPin(pinNumber: rstPin, initialState: .high)
        let dc = MockGPIOPin(pinNumber: dcPin, initialState: .low)
        let cs = csPin.map { MockGPIOPin(pinNumber: $0, initialState: .high) }
        let backlight = backlightPin.map { MockGPIOPin(pinNumber: $0, initialState: .low) }
        self.init(
            spi: spi,
            rst: rst,
            dc: dc,
            cs: cs,
            backlight: backlight,
            backlightActiveHigh: backlightActiveHigh,
            rotation: rotation,
            xOffset: xOffset,
            yOffset: yOffset,
            colorOrder: colorOrder,
            inverted: inverted
        )
    }
    #endif

    // MARK: - Configuration

    public func ensureConfigured() throws {
        try rst.open(direction: .outputHigh)
        try dc.open(direction: .outputLow)
        if let cs = self.cs {
            do {
                try cs.open(direction: .outputHigh)
            } catch {
                print("ST7735: Note - Software CS pin \(cs.pinNumber) open failed (\(error)). Using hardware SPI chip-select.")
            }
        }
        if let backlight = self.backlight {
            do {
                try backlight.open(direction: backlightActiveHigh ? .outputLow : .outputHigh)
            } catch {
                print("ST7735: Note - Backlight pin \(backlight.pinNumber) open failed (\(error)).")
            }
        }
        try spi.open()
    }

    // MARK: - Low-level Communication

    private func sendCommand(_ command: UInt8, data: [UInt8] = []) throws {
        try dc.write(.low)
        try? cs?.write(.low)
        try spi.writeByte(command)

        if !data.isEmpty {
            try dc.write(.high)
            try spi.write(data)
        }
        try? cs?.write(.high)
    }

    private func sendPixels(_ pixels: [UInt16]) throws {
        try dc.write(.high)
        try? cs?.write(.low)
        defer { try? cs?.write(.high) }

        // Keep each transfer below the Linux spidev buffer limit.
        let chunkPixels = 512
        var offset = 0
        while offset < pixels.count {
            let count = min(chunkPixels, pixels.count - offset)
            var bytes = [UInt8](repeating: 0, count: count * 2)
            for i in 0..<count {
                let pixel = pixels[offset + i]
                bytes[i * 2] = UInt8(pixel >> 8)
                bytes[i * 2 + 1] = UInt8(pixel & 0xFF)
            }
            try spi.write(bytes)
            offset += count
        }
    }

    private func setAddressWindow(x: Int, y: Int, width: Int, height: Int) throws {
        let x0 = UInt16(x)
        let x1 = UInt16(x + width - 1)
        let y0 = UInt16(y)
        let y1 = UInt16(y + height - 1)

        try sendCommand(Command.columnAddressSet, data: [
            UInt8(x0 >> 8), UInt8(x0 & 0xFF),
            UInt8(x1 >> 8), UInt8(x1 & 0xFF),
        ])
        try sendCommand(Command.rowAddressSet, data: [
            UInt8(y0 >> 8), UInt8(y0 & 0xFF),
            UInt8(y1 >> 8), UInt8(y1 & 0xFF),
        ])
    }

    // MARK: - ColorCanvas

    public func clear(color: RGB565) {
        lock.withLock {
            for i in 0..<frameBuffer.count {
                frameBuffer[i] = color.rawValue
            }
        }
    }

    public func setPixel(at point: Point, color: RGB565) {
        lock.withLock {
            let size = Self.size(for: _rotation)
            guard point.x >= 0 && point.x < size.width && point.y >= 0 && point.y < size.height else {
                return
            }
            frameBuffer[point.y * size.width + point.x] = color.rawValue
        }
    }

    public func getPixel(at point: Point) -> RGB565 {
        lock.withLock {
            let size = Self.size(for: _rotation)
            guard point.x >= 0 && point.x < size.width && point.y >= 0 && point.y < size.height else {
                return .black
            }
            return RGB565(rawValue: frameBuffer[point.y * size.width + point.x])
        }
    }

    // MARK: - Display Control

    public func reset() throws {
        print("ST7735: Hardware reset...")
        try rst.write(.high)
        Thread.sleep(forTimeInterval: 0.01)
        try rst.write(.low)
        Thread.sleep(forTimeInterval: 0.01)
        try rst.write(.high)
        Thread.sleep(forTimeInterval: 0.12)
    }

    public func initialize() throws {
        print("ST7735: Initializing ST7735 controller...")
        try ensureConfigured()
        try reset()

        let (rotation, inverted) = lock.withLock { (_rotation, _isInverted) }

        try sendCommand(Command.softwareReset)
        Thread.sleep(forTimeInterval: 0.15)

        try sendCommand(Command.sleepOut)
        Thread.sleep(forTimeInterval: 0.5)

        // Frame rate control
        try sendCommand(0xB1, data: [0x01, 0x2C, 0x2D])
        try sendCommand(0xB2, data: [0x01, 0x2C, 0x2D])
        try sendCommand(0xB3, data: [0x01, 0x2C, 0x2D, 0x01, 0x2C, 0x2D])
        try sendCommand(0xB4, data: [0x07]) // Column inversion

        // Power control
        try sendCommand(0xC0, data: [0xA2, 0x02, 0x84])
        try sendCommand(0xC1, data: [0xC5])
        try sendCommand(0xC2, data: [0x0A, 0x00])
        try sendCommand(0xC3, data: [0x8A, 0x2A])
        try sendCommand(0xC4, data: [0x8A, 0xEE])
        try sendCommand(0xC5, data: [0x0E]) // VCOM

        try sendCommand(inverted ? Command.invertOn : Command.invertOff)
        try sendCommand(Command.memoryAccessControl, data: [madCTL(for: rotation)])
        try sendCommand(Command.pixelFormat, data: [0x05]) // 16-bit RGB565

        // Gamma
        try sendCommand(0xE0, data: [
            0x02, 0x1C, 0x07, 0x12, 0x37, 0x32, 0x29, 0x2D,
            0x29, 0x25, 0x2B, 0x39, 0x00, 0x01, 0x03, 0x10,
        ])
        try sendCommand(0xE1, data: [
            0x03, 0x1D, 0x07, 0x06, 0x2E, 0x2C, 0x29, 0x2D,
            0x2E, 0x2E, 0x37, 0x3F, 0x00, 0x00, 0x02, 0x10,
        ])

        try sendCommand(Command.normalMode)
        Thread.sleep(forTimeInterval: 0.01)
        try sendCommand(Command.displayOn)
        Thread.sleep(forTimeInterval: 0.1)

        try setBacklight(true)
        print("ST7735: Initialization completed.")
    }

    public func display() throws {
        let (rotation, buffer) = lock.withLock { (_rotation, frameBuffer) }
        let size = Self.size(for: rotation)
        let offsets = startOffsets(for: rotation)

        try setAddressWindow(
            x: offsets.x,
            y: offsets.y,
            width: size.width,
            height: size.height
        )
        try sendCommand(Command.memoryWrite)
        try sendPixels(buffer)
    }

    /// Rotates the display and updates the controller's memory access mode.
    public func setRotation(_ rotation: Rotation) throws {
        lock.withLock { _rotation = rotation }
        try sendCommand(Command.memoryAccessControl, data: [madCTL(for: rotation)])
    }

    /// Enables or disables the panel's colour inversion.
    public func setInverted(_ inverted: Bool) throws {
        lock.withLock { _isInverted = inverted }
        try sendCommand(inverted ? Command.invertOn : Command.invertOff)
    }

    /// Turns the backlight on or off when a backlight GPIO pin is configured.
    public func setBacklight(_ isOn: Bool) throws {
        guard let backlight = self.backlight else { return }
        let state: PinState = (isOn == backlightActiveHigh) ? .high : .low
        try backlight.write(state)
    }

    public func sleep() throws {
        try? setBacklight(false)
        try sendCommand(Command.displayOff)
        try sendCommand(Command.sleepIn)
        try sendCommand(0x00) // NOP: confirm the sleep command
    }

    // MARK: - Helpers

    private static func size(for rotation: Rotation) -> Size {
        switch rotation {
        case .portrait, .portraitUpsideDown:
            return Size(width: nativeWidth, height: nativeHeight)
        case .landscape, .landscapeUpsideDown:
            return Size(width: nativeHeight, height: nativeWidth)
        }
    }

    private func startOffsets(for rotation: Rotation) -> (x: Int, y: Int) {
        switch rotation {
        case .portrait, .portraitUpsideDown:
            return (xOffset, yOffset)
        case .landscape, .landscapeUpsideDown:
            return (yOffset, xOffset)
        }
    }

    private func madCTL(for rotation: Rotation) -> UInt8 {
        var value: UInt8
        switch rotation {
        case .portrait:
            value = 0x40 | 0x80 // MX | MY
        case .landscape:
            value = 0x80 | 0x20 // MY | MV
        case .portraitUpsideDown:
            value = 0x00
        case .landscapeUpsideDown:
            value = 0x40 | 0x20 // MX | MV
        }
        if colorOrder == .bgr {
            value |= 0x08
        }
        return value
    }
}
