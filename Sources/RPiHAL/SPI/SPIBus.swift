import Foundation

public enum SPIError: Error, Sendable, CustomStringConvertible {
    case openFailed(path: String, errno: Int32)
    case writeFailed(path: String, errno: Int32)
    case notOpen

    public var description: String {
        switch self {
        case .openFailed(let path, let errno):
            return "Failed to open SPI at \(path) (errno: \(errno))"
        case .writeFailed(let path, let errno):
            return "Failed to write to SPI at \(path) (errno: \(errno))"
        case .notOpen:
            return "SPI bus is not open"
        }
    }
}

public protocol SPIBus: AnyObject, Sendable {
    var path: String { get }
    func open() throws
    func close()
    func write(_ bytes: [UInt8]) throws
    func writeByte(_ byte: UInt8) throws
}

extension SPIBus {
    public func writeByte(_ byte: UInt8) throws {
        try write([byte])
    }
}
