import Foundation

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
