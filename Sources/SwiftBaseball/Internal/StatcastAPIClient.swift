import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// HTTP client for Baseball Savant / Statcast CSV endpoints.
///
/// Separate from `URLSessionAPIClient` because Savant uses a different
/// base URL, returns CSV (not JSON), and has its own rate limiting behavior.
final class StatcastAPIClient: Sendable {
    private let session: URLSession
    private let baseURL: URL
    private let rateLimiter: RateLimiter

    // swiftlint:disable:next force_unwrapping
    static let savantBaseURL = URL(string: "https://baseballsavant.mlb.com")!

    init(configuration: Configuration = .default) {
        self.baseURL = Self.savantBaseURL
        // Allow up to 4 concurrent Savant requests. Batch callers send 3–5
        // requests total per roster load (vs the old 26 per-player approach),
        // so 4 concurrent is safe and lets all batch chunks fly in parallel.
        self.rateLimiter = RateLimiter(maxConcurrent: 4)
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
        try await fetchSavantCSV(path: "statcast_search/csv", queryItems: queryItems)
    }

    /// Fetches an HTML page from Baseball Savant.
    ///
    /// Used by leaderboard endpoints (e.g. `leaderboard/catcher-framing`) that embed
    /// their data in a `const data = [...]` JavaScript block rather than returning CSV.
    func fetchSavantPage(path: String, queryItems: [URLQueryItem]) async throws -> String {
        try await fetchSavantCSV(path: path, queryItems: queryItems)
    }

    /// Fetches CSV data from an arbitrary Baseball Savant path.
    ///
    /// Used by leaderboard endpoints (e.g. `leaderboard/sprint-speed`) that share
    /// the same rate limiter and error-handling as the main Statcast search.
    func fetchSavantCSV(path: String, queryItems: [URLQueryItem]) async throws -> String {
        guard var components = URLComponents(
            url: baseURL.appendingPathComponent(path),
            resolvingAgainstBaseURL: false
        ) else {
            throw SwiftBaseballError.configurationError(
                "Could not construct Statcast URL"
            )
        }
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
        guard (200 ... 299).contains(http.statusCode) else {
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
