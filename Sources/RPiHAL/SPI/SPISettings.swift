import Foundation

public struct SPISettings: Sendable, Equatable {
    public let mode: UInt8
    public let bitsPerWord: UInt8
    public let maxSpeedHz: UInt32

    public init(mode: UInt8 = 0, bitsPerWord: UInt8 = 8, maxSpeedHz: UInt32 = 2_000_000) {
        self.mode = mode
        self.bitsPerWord = bitsPerWord
        self.maxSpeedHz = maxSpeedHz
    }

    public static let standard = SPISettings()
    public static let `default` = SPISettings()
}
