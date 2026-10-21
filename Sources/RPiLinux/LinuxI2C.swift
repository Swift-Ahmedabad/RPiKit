import Foundation
import RPiHAL

#if os(Linux)
@preconcurrency import PeripheryKit

public final class LinuxI2C: I2CBus, @unchecked Sendable {
    public let devicePath: String
    private var i2c: I2C?

    public init(devicePath: String = "/dev/i2c-1") {
        self.devicePath = devicePath
    }

    public func open() throws {
        let i2c = I2C(chip: .i2c(devicePath))
        if i2c.open() {
            self.i2c = i2c
        } else {
            print("I2C Error: Failed to open \(devicePath). Is I2C enabled and the device mapped?")
        }
    }

    public func close() {
        _ = i2c?.close()
        self.i2c = nil
    }

    public func write(to address: UInt16, data: [UInt8]) throws {
        guard let i2c = self.i2c else { return }
        let request = I2C.Request(address: address, flags: .NONE, data: Data(data))
        _ = i2c.tranfer(requests: [request])
    }
}
#else
public final class LinuxI2C: I2CBus, @unchecked Sendable {
    public let devicePath: String

    public init(devicePath: String = "/dev/i2c-1") {
        self.devicePath = devicePath
    }

    public func open() throws {}
    public func close() {}
    public func write(to address: UInt16, data: [UInt8]) throws {}
}
#endif
