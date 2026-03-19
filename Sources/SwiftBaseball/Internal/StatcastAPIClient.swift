import Foundation

/// HTTP client for Baseball Savant / Statcast CSV endpoints.
///
/// Separate from `URLSessionAPIClient` because Savant uses a different
/// base URL, returns CSV (not JSON), and has its own rate limiting behavior.
final class StatcastAPIClient: Sendable {
    private let session: URLSession
    private let baseURL: URL
    private let rateLimiter: RateLimiter

    static let savantBaseURL = URL(string: "https://baseballsavant.mlb.com")!

    init(configuration: Configuration = .default) {
        self.baseURL = Self.savantBaseURL
        // Savant is more rate-limit sensitive — use lower concurrency.
        self.rateLimiter = RateLimiter(maxConcurrent: 1)
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = ["User-Agent": configuration.userAgent]
        self.session = URLSession(configuration: config)
    }

    /// Internal initializer for testing: injects a pre-configured URLSession and base URL.
    init(session: URLSession, baseURL: URL) {
        self.baseURL = baseURL
        self.rateLimiter = RateLimiter(maxConcurrent: 1)
        self.session = session
    }

    /// Fetches CSV data from a Statcast search endpoint.
    func fetchCSV(queryItems: [URLQueryItem]) async throws -> String {
        var components = URLComponents(
            url: baseURL.appendingPathComponent("statcast_search/csv"),
            resolvingAgainstBaseURL: false
        )!
        components.queryItems = queryItems

        guard let url = components.url else {
            throw SwiftBaseballError.configurationError(
                "Could not construct Statcast URL"
            )
        }

        await rateLimiter.acquire()
        defer { Task { await rateLimiter.release() } }

        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await session.data(from: url)
        } catch let urlError as URLError {
            throw SwiftBaseballError.networkError(urlError)
        }

        guard let http = response as? HTTPURLResponse else {
            throw SwiftBaseballError.unexpectedResponse
        }
        guard (200...299).contains(http.statusCode) else {
            if http.statusCode == 429 {
                let retryAfter = http.value(forHTTPHeaderField: "Retry-After")
                    .flatMap(TimeInterval.init)
                throw SwiftBaseballError.rateLimited(retryAfter: retryAfter)
            }
            throw SwiftBaseballError.invalidResponse(statusCode: http.statusCode)
        }

        guard let text = String(data: data, encoding: .utf8) else {
            throw SwiftBaseballError.unexpectedResponse
        }
        return text
    }
}
