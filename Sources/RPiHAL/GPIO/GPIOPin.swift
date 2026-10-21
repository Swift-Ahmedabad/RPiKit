import Foundation

public protocol GPIOPin: AnyObject, Sendable {
    var pinNumber: Int { get }
    func open(direction: PinDirection, bias: PinBias) throws
    func close()
    func read() throws -> PinState
    func write(_ state: PinState) throws
}

extension GPIOPin {
    public func open(direction: PinDirection) throws {
        try open(direction: direction, bias: .none)
    }
}
