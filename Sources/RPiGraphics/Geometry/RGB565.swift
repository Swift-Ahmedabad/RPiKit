import Foundation

/// A 16-bit RGB565 colour, the native pixel format of most SPI TFT controllers
/// (including the ST7735 used by 1.8" 128x160 modules).
///
/// Bits are packed as `RRRRRGGGGGGBBBBB` (5 red, 6 green, 5 blue).
public struct RGB565: Sendable, Hashable {
    /// The packed 16-bit value written to the panel.
    public var rawValue: UInt16

    public init(rawValue: UInt16) {
        self.rawValue = rawValue
    }

    public init(red: UInt8, green: UInt8, blue: UInt8) {
        let r = UInt16(red >> 3)
        let g = UInt16(green >> 2)
        let b = UInt16(blue >> 3)
        self.rawValue = (r << 11) | (g << 5) | b
    }

    /// Creates a colour from a 24-bit `0xRRGGBB` value.
    public init(hex: UInt32) {
        self.init(
            red: UInt8((hex >> 16) & 0xFF),
            green: UInt8((hex >> 8) & 0xFF),
            blue: UInt8(hex & 0xFF)
        )
    }

    /// Creates a colour from 8-bit channel components.
    public init(_ red: UInt8, _ green: UInt8, _ blue: UInt8) {
        self.init(red: red, green: green, blue: blue)
    }

    public var red: UInt8 {
        let value = UInt8((rawValue >> 11) & 0x1F)
        return (value << 3) | (value >> 2)
    }

    public var green: UInt8 {
        let value = UInt8((rawValue >> 5) & 0x3F)
        return (value << 2) | (value >> 4)
    }

    public var blue: UInt8 {
        let value = UInt8(rawValue & 0x1F)
        return (value << 3) | (value >> 2)
    }

    /// The colour as big-endian bytes, ready for a TFT data bus.
    public var bigEndianBytes: (high: UInt8, low: UInt8) {
        (UInt8(rawValue >> 8), UInt8(rawValue & 0xFF))
    }

    // MARK: - Common Colours

    public static let black = RGB565(0, 0, 0)
    public static let white = RGB565(255, 255, 255)
    public static let red = RGB565(255, 0, 0)
    public static let green = RGB565(0, 255, 0)
    public static let blue = RGB565(0, 0, 255)
    public static let yellow = RGB565(255, 255, 0)
    public static let cyan = RGB565(0, 255, 255)
    public static let magenta = RGB565(255, 0, 255)
    public static let orange = RGB565(255, 165, 0)
    public static let gray = RGB565(128, 128, 128)
}
