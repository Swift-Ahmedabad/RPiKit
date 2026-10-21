import Foundation
import RPiHAL

#if os(Linux)
@preconcurrency import PeripheryKit

public final class LinuxGPIO: GPIOPin, @unchecked Sendable {
    public let pinNumber: Int
    public let chipPath: String
    private let gpio: GPIO

    public init(chipPath: String = "/dev/gpiochip0", pinNumber: Int) {
        self.chipPath = chipPath
        self.pinNumber = pinNumber
        self.gpio = GPIO(pin: .cdev(chipPath, pinNumber))
    }

    public func open(direction: PinDirection, bias: PinBias) throws {
        let pDirection: GPIO.Direction
        switch direction {
        case .input:
            pDirection = .input
        case .output(let initial):
            pDirection = initial == .high ? .outputHigh : .outputLow
        }
        gpio.open(direction: pDirection)

        switch bias {
        case .pullUp:
            gpio.bias = .pullUp
        case .pullDown:
            gpio.bias = .pullDown
        case .none:
            gpio.bias = .none
        }
    }

    public func close() {
        gpio.close()
    }

    public func read() throws -> PinState {
        switch gpio.read() {
        case .digital(let isHigh):
            return isHigh ? .high : .low
        @unknown default:
            return .low
        }
    }

    public func write(_ state: PinState) throws {
        gpio.write(.digital(state == .high))
    }
}
#else
public final class LinuxGPIO: GPIOPin, @unchecked Sendable {
    public let pinNumber: Int
    public let chipPath: String

    public init(chipPath: String = "/dev/gpiochip0", pinNumber: Int) {
        self.chipPath = chipPath
        self.pinNumber = pinNumber
    }

    public func open(direction: PinDirection, bias: PinBias) throws {}
    public func close() {}
    public func read() throws -> PinState { .low }
    public func write(_ state: PinState) throws {}
}
#endif
