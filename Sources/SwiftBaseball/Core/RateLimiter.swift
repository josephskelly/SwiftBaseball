import Foundation

/// Concurrency limiter that caps simultaneous in-flight API requests.
///
/// Callers `acquire()` a permit before making a request and `release()` when done.
/// If all permits are taken, `acquire()` suspends until one becomes available.
actor RateLimiter {
    private var available: Int
    private var waiters: [CheckedContinuation<Void, Never>] = []

    /// Creates a rate limiter with the given concurrency cap.
    /// - Parameter maxConcurrent: Maximum simultaneous permits.
    init(maxConcurrent: Int) {
        self.available = max(1, maxConcurrent)
    }

    /// Acquires a permit, suspending if none are available.
    func acquire() async {
        if available > 0 {
            available -= 1
        } else {
            await withCheckedContinuation { continuation in
                waiters.append(continuation)
            }
        }
    }

    /// Releases a permit and resumes the next waiting caller, if any.
    func release() {
        if let next = waiters.first {
            waiters.removeFirst()
            next.resume()
        } else {
            available += 1
        }
    }
}
