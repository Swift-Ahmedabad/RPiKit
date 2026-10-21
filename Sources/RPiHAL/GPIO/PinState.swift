import Foundation

public enum PinState: UInt8, Sendable, Equatable, Hashable {
    case low = 0
    case high = 1

    public var boolValue: Bool {
        self == .high
    }

    public var inverted: PinState {
        self == .high ? .low : .high
    }

    public init(boolValue: Bool) {
        self = boolValue ? .high : .low
    }
}
