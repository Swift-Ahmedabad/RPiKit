#if canImport(Darwin)
import Darwin
#elseif os(Windows)
import WinSDK
#elseif canImport(Glibc)
import Glibc
#elseif canImport(Musl)
import Musl
#elseif canImport(Bionic)
import Bionic
#else
#error("Unsupported platform")
#endif

/// A threading lock based on `pthread_mutex_t` (and `SRWLOCK` on Windows),
/// identical to the zero-dependency implementation used in Apple's `swift-log`.
public final class Lock: @unchecked Sendable {
    #if os(Windows)
    private let mutex: UnsafeMutablePointer<SRWLOCK> =
        UnsafeMutablePointer.allocate(capacity: 1)
    #else
    private let mutex: UnsafeMutablePointer<pthread_mutex_t> =
        UnsafeMutablePointer.allocate(capacity: 1)
    #endif

    public init() {
        #if os(Windows)
        InitializeSRWLock(self.mutex)
        #else
        var attr = pthread_mutexattr_t()
        pthread_mutexattr_init(&attr)
        pthread_mutexattr_settype(&attr, .init(PTHREAD_MUTEX_ERRORCHECK))
        let err = pthread_mutex_init(self.mutex, &attr)
        precondition(err == 0, "\(#function) failed in pthread_mutex with error \(err)")
        let attrDestroyErr = pthread_mutexattr_destroy(&attr)
        precondition(
            attrDestroyErr == 0,
            "\(#function) failed in pthread_mutexattr_destroy with error \(attrDestroyErr)"
        )
        #endif
    }

    deinit {
        #if os(Windows)
        self.mutex.deallocate()
        #else
        let err = pthread_mutex_destroy(self.mutex)
        precondition(err == 0, "\(#function) failed in pthread_mutex with error \(err)")
        self.mutex.deallocate()
        #endif
    }

    /// Acquire the lock.
    public func lock() {
        #if os(Windows)
        AcquireSRWLockExclusive(self.mutex)
        #else
        let err = pthread_mutex_lock(self.mutex)
        precondition(err == 0, "\(#function) failed in pthread_mutex with error \(err)")
        #endif
    }

    /// Release the lock.
    public func unlock() {
        #if os(Windows)
        ReleaseSRWLockExclusive(self.mutex)
        #else
        let err = pthread_mutex_unlock(self.mutex)
        precondition(err == 0, "\(#function) failed in pthread_mutex with error \(err)")
        #endif
    }

    /// Acquire the lock for the duration of the given block.
    @inlinable
    public func withLock<T>(_ body: () throws -> T) rethrows -> T {
        self.lock()
        defer {
            self.unlock()
        }
        return try body()
    }

    @inlinable
    public func withLockVoid(_ body: () throws -> Void) rethrows {
        try self.withLock(body)
    }
}
