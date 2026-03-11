import Foundation

// MARK: - Protocol

protocol APIClient: Sendable {
    func fetchRaw(_ endpoint: Endpoint) async throws -> Data
}

// MARK: - URLSession implementation

final class URLSessionAPIClient: APIClient {
    private let session: URLSession
    private let baseURL: URL
    private let rateLimiter: RateLimiter
    private let maxRetries: Int
    private let retryBaseDelay: TimeInterval

    init(configuration: Configuration = .default) {
        self.baseURL = configuration.baseURL
        self.rateLimiter = RateLimiter(maxConcurrent: configuration.maxConcurrentRequests)
        self.maxRetries = configuration.maxRetries
        self.retryBaseDelay = configuration.retryBaseDelay
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = ["User-Agent": configuration.userAgent]
        self.session = URLSession(configuration: config)
    }

    /// Internal initializer for testing: injects a pre-configured URLSession.
    init(session: URLSession, configuration: Configuration) {
        self.baseURL = configuration.baseURL
        self.rateLimiter = RateLimiter(maxConcurrent: configuration.maxConcurrentRequests)
        self.maxRetries = configuration.maxRetries
        self.retryBaseDelay = configuration.retryBaseDelay
        self.session = session
    }

    func fetchRaw(_ endpoint: Endpoint) async throws -> Data {
        guard let url = endpoint.url(baseURL: baseURL) else {
            throw SwiftBaseballError.configurationError(
                "Could not construct URL for path: \(endpoint.path)"
            )
        }

        await rateLimiter.acquire()
        defer { Task { await rateLimiter.release() } }

        var lastError: Error = SwiftBaseballError.unexpectedResponse
        for attempt in 0...maxRetries {
            if attempt > 0 {
                let delay = retryBaseDelay * pow(2.0, Double(attempt - 1))
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            }
            do {
                let (data, response): (Data, URLResponse)
                do {
                    (data, response) = try await session.data(from: url)
                } catch let urlError as URLError {
                    lastError = SwiftBaseballError.networkError(urlError)
                    continue
                }
                guard let http = response as? HTTPURLResponse else {
                    throw SwiftBaseballError.unexpectedResponse
                }
                switch http.statusCode {
                case 200...299:
                    return data
                case 429:
                    let retryAfter = http.value(forHTTPHeaderField: "Retry-After")
                        .flatMap(TimeInterval.init)
                    lastError = SwiftBaseballError.rateLimited(retryAfter: retryAfter)
                    if let delay = retryAfter, attempt < maxRetries {
                        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    }
                case 400...499:
                    // Non-retryable client errors
                    throw SwiftBaseballError.invalidResponse(statusCode: http.statusCode)
                default:
                    // 5xx — retryable
                    lastError = SwiftBaseballError.invalidResponse(statusCode: http.statusCode)
                }
            } catch let sbError as SwiftBaseballError {
                throw sbError
            }
        }
        throw lastError
    }
}

extension URLSessionAPIClient: @unchecked Sendable {}

// MARK: - Shared JSONDecoder

extension JSONDecoder {
    static let mlb: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)

            // Try date-only format first (most common in MLB API)
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.timeZone = TimeZone(identifier: "UTC")
            dateFormatter.dateFormat = "yyyy-MM-dd"
            if let date = dateFormatter.date(from: string) {
                return date
            }

            // Fall back to full ISO8601
            let iso = ISO8601DateFormatter()
            iso.formatOptions = [.withInternetDateTime]
            if let date = iso.date(from: string) {
                return date
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date string: \(string)"
            )
        }
        return decoder
    }()
}
