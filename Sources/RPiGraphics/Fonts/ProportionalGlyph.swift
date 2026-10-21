import Foundation

public struct ProportionalGlyph: Sendable {
    public let advance: UInt8
    public let width: UInt8
    public let height: UInt8
    public let left: Int8
    public let top: Int8
    public let bytes: [UInt8]

    public init(advance: UInt8, width: UInt8, height: UInt8, left: Int8, top: Int8, bytes: [UInt8]) {
        self.advance = advance
        self.width = width
        self.height = height
        self.left = left
        self.top = top
        self.bytes = bytes
    }
}
