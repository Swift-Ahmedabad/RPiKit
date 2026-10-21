import Foundation
import RPiHAL
#if os(Linux)
@preconcurrency import PeripheryKit
#endif

public final class LinuxGPIO: GPIOPin, @unchecked Sendable {
    public let pinNumber: Int
    private let chipPath: String

    #if os(Linux)
    private var gpio: GPIO
    private var isConfigured = false
    #endif

    public init(chipPath: String = "/dev/gpiochip0", pinNumber: Int) {
        self.chipPath = chipPath
        self.pinNumber = pinNumber
        #if os(Linux)
        self.gpio = GPIO(pin: .cdev(chipPath, pinNumber))
        #endif
    }

    public func open(direction: PinDirection, bias: PinBias = .none) throws {
        #if os(Linux)
        let pkDirection: GPIO.Direction
        switch direction {
        case .input:
            pkDirection = .input
        case .output(let initial):
            pkDirection = (initial == .high) ? .outputHigh : .outputLow
        }
        guard gpio.open(direction: pkDirection) else {
            throw GPIOError.openFailed(pin: pinNumber)
        }
        switch bias {
        case .pullUp:
            gpio.bias = .pullUp
        case .pullDown:
            gpio.bias = .pullDown
        case .none:
            gpio.bias = .disable
        }
        isConfigured = true
        #endif
    }

    public func read() throws -> PinState {
        #if os(Linux)
        guard isConfigured else {
            throw GPIOError.readFailed(pin: pinNumber)
        }
        switch gpio.read() {
        case .digital(let isHigh):
            return isHigh ? .high : .low
        default:
            throw GPIOError.readFailed(pin: pinNumber)
        }
        #else
        return .low
        #endif
    }

    public func write(_ state: PinState) throws {
        #if os(Linux)
        guard isConfigured else {
            throw GPIOError.writeFailed(pin: pinNumber)
        }
        gpio.write(.digital(state == .high))
        #endif
    }

    public func close() {
        #if os(Linux)
        if isConfigured {
            gpio.close()
            isConfigured = false
        }
        #endif
    }
}
