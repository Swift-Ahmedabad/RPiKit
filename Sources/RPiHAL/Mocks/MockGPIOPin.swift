import Foundation

public final class MockGPIOPin: GPIOPin, @unchecked Sendable {
    private let lock = NSLock()
    public let pinNumber: Int
    public private(set) var isOpen: Bool = false
    public private(set) var direction: PinDirection?
    public private(set) var bias: PinBias = .none
    public var currentState: PinState = .low
    public private(set) var writeHistory: [PinState] = []

    public init(pinNumber: Int, initialState: PinState = .low) {
        self.pinNumber = pinNumber
        self.currentState = initialState
    }

    public func open(direction: PinDirection, bias: PinBias) throws {
        lock.lock()
        defer { lock.unlock() }
        self.isOpen = true
        self.direction = direction
        self.bias = bias
        if case .output(let initial) = direction {
            self.currentState = initial
            self.writeHistory.append(initial)
        }
    }

    public func close() {
        lock.lock()
        defer { lock.unlock() }
        self.isOpen = false
    }

    public func read() throws -> PinState {
        lock.lock()
        defer { lock.unlock() }
        return currentState
    }

    public func write(_ state: PinState) throws {
        lock.lock()
        defer { lock.unlock() }
        self.currentState = state
        self.writeHistory.append(state)
    }

    public func simulateInput(_ state: PinState) {
        lock.lock()
        defer { lock.unlock() }
        self.currentState = state
    }
}
