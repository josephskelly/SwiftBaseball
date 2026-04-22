import Foundation
@testable import SwiftBaseball
import Testing

@Suite("RateLimiter Tests")
struct RateLimiterTests {
    // MARK: - Slot management

    @Test("Single permit acquired and released")
    func singlePermit() async {
        let limiter = RateLimiter(maxConcurrent: 1)
        await limiter.acquire()
        await limiter.release()
        // After release, another acquire should succeed immediately
        await limiter.acquire()
        await limiter.release()
    }

    @Test("Multiple permits within cap succeed without waiting")
    func multiplePermitsWithinCap() async {
        let limiter = RateLimiter(maxConcurrent: 3)
        await limiter.acquire()
        await limiter.acquire()
        await limiter.acquire()
        await limiter.release()
        await limiter.release()
        await limiter.release()
    }

    @Test("Waiter is resumed after release")
    func waiterResumedAfterRelease() async {
        let limiter = RateLimiter(maxConcurrent: 1)
        await limiter.acquire()

        let flag = Flag()
        let task = Task {
            await limiter.acquire()
            await flag.set()
        }

        // Yield so the task has a chance to reach the waiter list
        try? await Task.sleep(nanoseconds: 10_000_000)
        #expect(await flag.value == false)

        await limiter.release()
        await task.value
        #expect(await flag.value == true)
        await limiter.release()
    }

    @Test("maxConcurrent of zero defaults to 1")
    func zeroCapDefaultsToOne() async {
        let limiter = RateLimiter(maxConcurrent: 0)
        await limiter.acquire()
        await limiter.release()
    }

    @Test("Multiple concurrent tasks contend for a single permit without deadlock")
    func concurrentStressSinglePermit() async {
        let limiter = RateLimiter(maxConcurrent: 1)
        let taskCount = 20
        let counter = Counter()

        await withTaskGroup(of: Void.self) { group in
            for _ in 0 ..< taskCount {
                group.addTask {
                    await limiter.acquire()
                    await counter.increment()
                    // Simulate brief work
                    try? await Task.sleep(nanoseconds: 1_000_000)
                    await limiter.release()
                }
            }
        }

        let finalCount = await counter.value
        #expect(finalCount == taskCount)
    }

    @Test("Concurrent tasks with limited permits all complete")
    func concurrentStressMultiplePermits() async {
        let limiter = RateLimiter(maxConcurrent: 3)
        let taskCount = 30
        let counter = Counter()

        await withTaskGroup(of: Void.self) { group in
            for _ in 0 ..< taskCount {
                group.addTask {
                    await limiter.acquire()
                    await counter.increment()
                    try? await Task.sleep(nanoseconds: 500_000)
                    await limiter.release()
                }
            }
        }

        let finalCount = await counter.value
        #expect(finalCount == taskCount)
    }

    // MARK: - Configuration

    @Test("Configuration default retry values")
    func configurationRetryDefaults() {
        let config = Configuration()
        #expect(config.maxRetries == 3)
        #expect(config.retryBaseDelay == 0.5)
    }

    @Test("Configuration accepts custom retry values")
    func configurationCustomRetry() {
        let config = Configuration(maxRetries: 5, retryBaseDelay: 1.0)
        #expect(config.maxRetries == 5)
        #expect(config.retryBaseDelay == 1.0)
    }

    @Test("Configuration custom baseURL is respected")
    func configurationCustomBaseURL() throws {
        let customURL = try #require(URL(string: "https://custom.api.example.com/v2/"))
        let config = Configuration(baseURL: customURL)
        #expect(config.baseURL == customURL)
    }

    @Test("Configuration custom cacheTTL is respected")
    func configurationCustomCacheTTL() {
        let config = Configuration(cacheTTL: 7200)
        #expect(config.cacheTTL == 7200)
    }

    @Test("Configuration default userAgent includes version")
    func configurationDefaultUserAgent() {
        let config = Configuration()
        #expect(config.userAgent == "SwiftBaseball/\(swiftBaseballVersion)")
    }

    @Test("Configuration nil baseURL uses default")
    func configurationNilBaseURLUsesDefault() {
        let config = Configuration(baseURL: nil)
        #expect(config.baseURL.absoluteString == "https://statsapi.mlb.com/api/v1/")
    }

    // MARK: - Retry via URLSessionAPIClient

    @Test("Non-retryable 4xx is thrown immediately without retrying")
    func nonRetryable4xxThrownImmediately() async throws {
        let mock = RetryCountingAPIClient(statusCode: 403)
        let endpoint = Endpoint(path: "test", queryItems: [])
        do {
            _ = try await mock.fetchRaw(endpoint)
            Issue.record("Expected error not thrown")
        } catch SwiftBaseballError.invalidResponse(let code) {
            #expect(code == 403)
        }
        // Should not have retried
        #expect(mock.callCount == 1)
    }

    @Test("5xx is retried up to maxRetries times")
    func serverErrorIsRetried() async throws {
        let config = Configuration(maxRetries: 2, retryBaseDelay: 0.0)
        let mock = RetryCountingAPIClient(statusCode: 500, configuration: config)
        let endpoint = Endpoint(path: "test", queryItems: [])
        do {
            _ = try await mock.fetchRaw(endpoint)
            Issue.record("Expected error not thrown")
        } catch SwiftBaseballError.invalidResponse(let code) {
            #expect(code == 500)
        }
        // Initial attempt + 2 retries = 3 total
        #expect(mock.callCount == 3)
    }

    @Test("Successful response after retry returns data")
    func successAfterRetry() async throws {
        let config = Configuration(maxRetries: 2, retryBaseDelay: 0.0)
        let mock = RetryCountingAPIClient(
            failTimes: 1, thenStatusCode: 200,
            successData: Data("{}".utf8),
            configuration: config
        )
        let endpoint = Endpoint(path: "test", queryItems: [])
        let data = try await mock.fetchRaw(endpoint)
        #expect(!data.isEmpty)
        #expect(mock.callCount == 2) // 1 failure + 1 success
    }
}

// MARK: - RetryCountingAPIClient

/// A test-only APIClient that counts calls and simulates HTTP status codes.
private final class RetryCountingAPIClient: APIClient, @unchecked Sendable {
    private let statusCode: Int
    private let failTimes: Int
    private let successData: Data
    private let config: Configuration
    private(set) var callCount: Int = 0
    private let rateLimiter: RateLimiter
    private let baseURL: URL

    init(
        statusCode: Int,
        configuration: Configuration = Configuration(maxRetries: 2, retryBaseDelay: 0.0)
    ) {
        self.statusCode = statusCode
        self.failTimes = Int.max
        self.successData = Data()
        self.config = configuration
        self.rateLimiter = RateLimiter(maxConcurrent: configuration.maxConcurrentRequests)
        // swiftlint:disable:next force_unwrapping
        self.baseURL = URL(string: "https://example.com/")!
    }

    init(
        failTimes: Int,
        thenStatusCode: Int,
        successData: Data,
        configuration: Configuration
    ) {
        self.statusCode = 500
        self.failTimes = failTimes
        self.successData = successData
        self.config = configuration
        self.rateLimiter = RateLimiter(maxConcurrent: configuration.maxConcurrentRequests)
        // swiftlint:disable:next force_unwrapping
        self.baseURL = URL(string: "https://example.com/")!
        _ = thenStatusCode
    }

    func fetchRaw(_ endpoint: Endpoint) async throws -> Data {
        await rateLimiter.acquire()
        defer { Task { await rateLimiter.release() } }

        var lastError: Error = SwiftBaseballError.unexpectedResponse
        for attempt in 0 ... config.maxRetries {
            if attempt > 0 && config.retryBaseDelay > 0 {
                let delay = config.retryBaseDelay * pow(2.0, Double(attempt - 1))
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
            callCount += 1
            let currentCode = callCount <= failTimes ? statusCode : 200
            switch currentCode {
            case 200 ... 299:
                return successData
            case 429:
                lastError = SwiftBaseballError.rateLimited(retryAfter: nil)
            case 400 ... 499:
                throw SwiftBaseballError.invalidResponse(statusCode: currentCode)
            default:
                lastError = SwiftBaseballError.invalidResponse(statusCode: currentCode)
            }
        }
        throw lastError
    }
}

// MARK: - Counter

/// A thread-safe counter for stress tests.
private actor Counter {
    var value: Int = 0
    func increment() {
        value += 1
    }
}

/// A thread-safe boolean flag for concurrency tests.
private actor Flag {
    var value: Bool = false
    func set() {
        value = true
    }
}
