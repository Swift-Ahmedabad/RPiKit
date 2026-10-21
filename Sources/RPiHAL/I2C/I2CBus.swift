import Foundation

public protocol I2CBus: AnyObject, Sendable {
    var devicePath: String { get }
    func open() throws
    func close()
    func write(to address: UInt16, data: [UInt8]) throws
    func transfer(to address: UInt16, writeData: [UInt8], readCount: Int) throws -> [UInt8]
}

extension I2CBus {
    public func transfer(to address: UInt16, writeData: [UInt8], readCount: Int) throws -> [UInt8] {
        try write(to: address, data: writeData)
        return []
    }
}
