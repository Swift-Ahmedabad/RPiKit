import Foundation

public final class MockI2CBus: I2CBus, @unchecked Sendable {
    private let lock = Lock()
    public let devicePath: String
    private var _isOpen = false
    private var _transactions: [(address: UInt16, data: [UInt8])] = []

    public init(devicePath: String = "/dev/i2c-1") {
        self.devicePath = devicePath
    }

    public var isOpen: Bool {
        lock.withLock { _isOpen }
    }

    public var transactions: [(address: UInt16, data: [UInt8])] {
        lock.withLock { _transactions }
    }

    public func open() throws {
        lock.withLock { _isOpen = true }
    }

    public func write(to address: UInt16, data: [UInt8]) throws {
        lock.withLock {
            _transactions.append((address: address, data: data))
        }
    }

    public func clearHistory() {
        lock.withLock { _transactions.removeAll() }
    }

    public func close() {
        lock.withLock { _isOpen = false }
    }
}
