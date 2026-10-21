import Foundation

public enum GPIOError: Error, Sendable, CustomStringConvertible {
    case openFailed(pin: Int)
    case writeFailed(pin: Int)
    case readFailed(pin: Int)

    public var description: String {
        switch self {
        case .openFailed(let pin):
            return "Failed to open GPIO pin \(pin)"
        case .writeFailed(let pin):
            return "Failed to write to GPIO pin \(pin)"
        case .readFailed(let pin):
            return "Failed to read from GPIO pin \(pin)"
        }
    }
}

public protocol GPIOPin: AnyObject, Sendable {
    var pinNumber: Int { get }
    func open(direction: PinDirection, bias: PinBias) throws
    func read() throws -> PinState
    func write(_ state: PinState) throws
    func close()
}

extension GPIOPin {
    public func open(direction: PinDirection) throws {
        try open(direction: direction, bias: .none)
    }
}
