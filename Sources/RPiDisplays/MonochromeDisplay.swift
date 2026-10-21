import Foundation
import RPiGraphics

public protocol MonochromeDisplay: MonochromeCanvas, Sendable {
    func initialize() throws
    func display() throws
    func sleep() throws
}

extension MonochromeDisplay {
    public func sleep() throws {}
}
