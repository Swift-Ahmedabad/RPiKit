import Foundation

public final class MockI2CBus: I2CBus, @unchecked Sendable {
    private let lock = NSLock()
    public let devicePath: String
    public private(set) var isOpen: Bool = false
    public private(set) var transactions: [(address: UInt16, data: [UInt8])] = []

    public init(devicePath: String = "/dev/i2c-1") {
        self.devicePath = devicePath
    }

    public func open() throws {
        lock.lock()
        defer { lock.unlock() }
        self.isOpen = true
    }

    public func close() {
        lock.lock()
        defer { lock.unlock() }
        self.isOpen = false
    }

    public func write(to address: UInt16, data: [UInt8]) throws {
        lock.lock()
        defer { lock.unlock() }
        self.transactions.append((address: address, data: data))
    }

    public func clearHistory() {
        lock.lock()
        defer { lock.unlock() }
        self.transactions.removeAll()
    }
}
