import Foundation
import RPiGraphics

/// A colour display that can be configured, flushed, and put to sleep.
public protocol ColorDisplay: ColorCanvas, Sendable {
    func initialize() throws
    func display() throws
    func sleep() throws
}

extension ColorDisplay {
    public func sleep() throws {}
}
