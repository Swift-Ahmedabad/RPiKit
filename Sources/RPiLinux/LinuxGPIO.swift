import Foundation
import RPiHAL
#if os(Linux)
@preconcurrency import PeripheryKit
#endif

public final class LinuxGPIO: GPIOPin, @unchecked Sendable {
    public let pinNumber: Int
    public let chipPath: String

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
        if isConfigured { return }
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
            // Do not override default line bias for output/general pins,
            // as re-requesting bias on Linux cdev can reset line state.
            break
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
        guard gpio.write(.digital(state == .high)) else {
            throw GPIOError.writeFailed(pin: pinNumber)
        }
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
