import Foundation

public struct BitmapFont: Sendable {
    public let name: String
    public let width: Int
    public let height: Int
    public let bytesPerRow: Int
    public let glyphs: [[UInt8]]

    public init(name: String, width: Int, height: Int, bytesPerRow: Int, glyphs: [[UInt8]]) {
        self.name = name
        self.width = width
        self.height = height
        self.bytesPerRow = bytesPerRow
        self.glyphs = glyphs
    }
}
