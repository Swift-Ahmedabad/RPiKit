import Foundation

public enum PixelColor: Sendable, Equatable {
    /// Lit on OLED, Dark ink on e-Paper
    case on
    /// Dark on OLED, White background on e-Paper
    case off

    public var isOn: Bool {
        self == .on
    }

    public var isBlack: Bool {
        self == .on
    }

    public var inverted: PixelColor {
        self == .on ? .off : .on
    }
}
