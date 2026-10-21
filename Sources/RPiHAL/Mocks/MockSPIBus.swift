import Foundation

public final class MockSPIBus: SPIBus, @unchecked Sendable {
    private let lock = Lock()
    public let path: String
    public var settings: SPISettings
    private var _isOpen = false
    private var _writtenBytes: [UInt8] = []

    public init(path: String = "/dev/spidev0.0", settings: SPISettings = .default) {
        self.path = path
        self.settings = settings
    }

    public var isOpen: Bool {
        lock.withLock { _isOpen }
    }

    public var writtenBytes: [UInt8] {
        lock.withLock { _writtenBytes }
    }

    public func open() throws {
        lock.withLock { _isOpen = true }
    }

    public func write(_ bytes: [UInt8]) throws {
        lock.withLock {
            _writtenBytes.append(contentsOf: bytes)
        }
    }

    public func clearHistory() {
        lock.withLock { _writtenBytes.removeAll() }
    }

    public func close() {
        lock.withLock { _isOpen = false }
    }
}
