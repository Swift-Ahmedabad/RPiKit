import Foundation

public struct ProportionalFont: Sendable {
    public let name: String
    public let lineHeight: Int
    public let glyphs: [ProportionalGlyph]

    public init(name: String, lineHeight: Int, glyphs: [ProportionalGlyph]) {
        self.name = name
        self.lineHeight = lineHeight
        self.glyphs = glyphs
    }

    public func glyph(for ascii: UInt8) -> ProportionalGlyph? {
        guard ascii >= 32 && ascii <= 126 else { return nil }
        let idx = Int(ascii - 32)
        guard idx < glyphs.count else { return nil }
        return glyphs[idx]
    }
}
