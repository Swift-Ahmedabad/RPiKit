import Foundation

public enum PinDirection: Sendable, Equatable {
    case input
    case output(initialValue: PinState)

    public static var outputHigh: PinDirection {
        .output(initialValue: .high)
    }

    public static var outputLow: PinDirection {
        .output(initialValue: .low)
    }
}
