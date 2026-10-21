import Foundation
import RPiHAL
import RPiLinux

/// A hardware button monitor with software debouncing and an AsyncStream event publisher.
public final class DebouncedButton: Sendable {
    private let pin: GPIOPin
    private let activeLow: Bool
    private let debounceInterval: TimeInterval
    private let pollInterval: TimeInterval

    public init(
        pin: GPIOPin,
        activeLow: Bool = true,
        debounceInterval: TimeInterval = 0.05,
        pollInterval: TimeInterval = 0.01
    ) {
        self.pin = pin
        self.activeLow = activeLow
        self.debounceInterval = debounceInterval
        self.pollInterval = pollInterval

        try? pin.open(direction: .input, bias: activeLow ? .pullUp : .pullDown)
    }

    #if os(Linux)
    public convenience init(
        chipPath: String = "/dev/gpiochip0",
        pinNumber: Int = 27,
        activeLow: Bool = true,
        debounceInterval: TimeInterval = 0.05,
        pollInterval: TimeInterval = 0.01
    ) {
        let pin = LinuxGPIO(chipPath: chipPath, pinNumber: pinNumber)
        self.init(pin: pin, activeLow: activeLow, debounceInterval: debounceInterval, pollInterval: pollInterval)
    }
    #else
    public convenience init(
        chipPath: String = "/dev/gpiochip0",
        pinNumber: Int = 27,
        activeLow: Bool = true,
        debounceInterval: TimeInterval = 0.05,
        pollInterval: TimeInterval = 0.01
    ) {
        let pin = MockGPIOPin(pinNumber: pinNumber, initialState: activeLow ? .high : .low)
        self.init(pin: pin, activeLow: activeLow, debounceInterval: debounceInterval, pollInterval: pollInterval)
    }
    #endif

    public func events() -> AsyncStream<ButtonEvent> {
        AsyncStream { continuation in
            let task = Task {
                var lastStablePressed = false
                var candidatePressed: Bool? = nil
                var candidateTimestamp = Date()

                while !Task.isCancelled {
                    if let pinState = try? pin.read() {
                        let isRawPressed = activeLow ? (pinState == .low) : (pinState == .high)
                        let now = Date()
                        if isRawPressed != lastStablePressed {
                            if candidatePressed == isRawPressed {
                                if now.timeIntervalSince(candidateTimestamp) >= debounceInterval {
                                    lastStablePressed = isRawPressed
                                    continuation.yield(isRawPressed ? .pressed : .released)
                                    candidatePressed = nil
                                }
                            } else {
                                candidatePressed = isRawPressed
                                candidateTimestamp = now
                            }
                        } else {
                            candidatePressed = nil
                        }
                    }

                    try? await Task.sleep(nanoseconds: UInt64(pollInterval * 1_000_000_000))
                }
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }
}
