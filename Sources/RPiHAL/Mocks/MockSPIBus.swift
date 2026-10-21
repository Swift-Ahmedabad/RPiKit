import Foundation

public final class MockSPIBus: SPIBus, @unchecked Sendable {
    private let lock = NSLock()
    public let path: String
    public private(set) var isOpen: Bool = false
    public private(set) var writtenBytes: [UInt8] = []

    public init(path: String = "/dev/spidev0.0") {
        self.path = path
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

    public func write(_ bytes: [UInt8]) throws {
        lock.lock()
        defer { lock.unlock() }
        self.writtenBytes.append(contentsOf: bytes)
    }

    public func clearHistory() {
        lock.lock()
        defer { lock.unlock() }
        self.writtenBytes.removeAll()
    }
}
