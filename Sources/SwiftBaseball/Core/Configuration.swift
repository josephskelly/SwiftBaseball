import Foundation

/// Configuration for the SwiftBaseball API client.
///
/// Controls base URL, caching behavior, concurrency limits, and user agent.
/// Use ``default`` for standard MLB Stats API settings.
public struct Configuration: Sendable {
    /// Base URL for the MLB Stats API.
    public var baseURL: URL
    /// Whether response caching is enabled.
    public var cacheEnabled: Bool
    /// Time-to-live for cached responses, in seconds.
    public var cacheTTL: TimeInterval
    /// Maximum number of concurrent API requests.
    public var maxConcurrentRequests: Int
    /// User-Agent header sent with each request.
    public var userAgent: String

    // swiftlint:disable:next force_unwrapping
    private static let defaultBaseURL = URL(string: "https://statsapi.mlb.com/api/v1/")!

    /// Creates a new configuration.
    ///
    /// - Parameters:
    ///   - baseURL: Base URL for the MLB Stats API. Defaults to `https://statsapi.mlb.com/api/v1/`.
    ///   - cacheEnabled: Whether to cache responses. Defaults to `false`.
    ///   - cacheTTL: Cache time-to-live in seconds. Defaults to `3600`.
    ///   - maxConcurrentRequests: Maximum concurrent requests. Defaults to `5`.
    ///   - userAgent: User-Agent header value. Defaults to `"SwiftBaseball/0.1.0"`.
    public init(
        baseURL: URL? = nil,
        cacheEnabled: Bool = false,
        cacheTTL: TimeInterval = 3600,
        maxConcurrentRequests: Int = 5,
        userAgent: String = "SwiftBaseball/0.1.0"
    ) {
        self.baseURL = baseURL ?? Self.defaultBaseURL
        self.cacheEnabled = cacheEnabled
        self.cacheTTL = cacheTTL
        self.maxConcurrentRequests = maxConcurrentRequests
        self.userAgent = userAgent
    }

    /// Default configuration targeting the MLB Stats API.
    public static let `default` = Configuration()
}
