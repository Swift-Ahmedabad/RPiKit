import Foundation
import RPiHAL
#if os(Linux)
import Glibc
#endif

public final class LinuxSPI: SPIBus, @unchecked Sendable {
    public let path: String
    public let settings: SPISettings
    private var fd: Int32 = -1

    // Linux spidev ioctl request codes:
    private static let SPI_IOC_WR_MODE: UInt = 0x40016b01
    private static let SPI_IOC_WR_BITS_PER_WORD: UInt = 0x40016b03
    private static let SPI_IOC_WR_MAX_SPEED_HZ: UInt = 0x40046b04

    public init(path: String = "/dev/spidev0.0", settings: SPISettings = .standard) {
        self.path = path
        self.settings = settings
    }

    public func open() throws {
        #if os(Linux)
        if fd >= 0 { return }
        self.fd = Glibc.open(path, O_RDWR)
        guard self.fd >= 0 else {
            let err = errno
            print("SPI Error: Failed to open \(path) (errno: \(err))")
            throw SPIError.openFailed(path: path, errno: err)
        }

        var mode: UInt8 = settings.mode
        var bits: UInt8 = settings.bitsPerWord
        var speed: UInt32 = settings.maxSpeedHz

        _ = ioctl(self.fd, Self.SPI_IOC_WR_MODE, &mode)
        _ = ioctl(self.fd, Self.SPI_IOC_WR_BITS_PER_WORD, &bits)
        _ = ioctl(self.fd, Self.SPI_IOC_WR_MAX_SPEED_HZ, &speed)
        #endif
    }

    public func close() {
        #if os(Linux)
        if fd >= 0 {
            Glibc.close(fd)
            fd = -1
        }
        #endif
    }

    public func write(_ bytes: [UInt8]) throws {
        #if os(Linux)
        guard fd >= 0 else {
            throw SPIError.notOpen
        }
        let written = bytes.withUnsafeBytes { ptr -> Int in
            guard let base = ptr.baseAddress else { return 0 }
            return Glibc.write(fd, base, bytes.count)
        }
        if written < 0 {
            let err = errno
            print("SPI Error: Failed to write to \(path) (errno: \(err))")
            throw SPIError.writeFailed(path: path, errno: err)
        }
        #endif
    }
}
