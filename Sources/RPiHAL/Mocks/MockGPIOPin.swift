import Foundation

public final class MockGPIOPin: GPIOPin, @unchecked Sendable {
    private let lock = Lock()
    public let pinNumber: Int

    private var _isOpen = false
    private var _direction: PinDirection = .input
    private var _bias: PinBias = .none
    private var _state: PinState
    private var _writeHistory: [PinState] = []

    public init(pinNumber: Int, initialState: PinState = .low) {
        self.pinNumber = pinNumber
        self._state = initialState
    }

    public var isOpen: Bool {
        lock.withLock { _isOpen }
    }

    public var state: PinState {
        lock.withLock { _state }
    }

    public var writeHistory: [PinState] {
        lock.withLock { _writeHistory }
    }

    public func open(direction: PinDirection, bias: PinBias = .none) throws {
        lock.withLock {
            _isOpen = true
            _direction = direction
            _bias = bias
            if case .output(let initial) = direction {
                _state = initial
                _writeHistory.append(initial)
            }
        }
    }

    public func read() throws -> PinState {
        lock.withLock {
            guard _isOpen else { return .low }
            return _state
        }
    }

    public func write(_ state: PinState) throws {
        lock.withLock {
            guard _isOpen else { return }
            _state = state
            _writeHistory.append(state)
        }
    }

    public func simulateInput(_ state: PinState) {
        lock.withLock {
            _state = state
        }
    }

    public func close() {
        lock.withLock {
            _isOpen = false
        }
    }
}
