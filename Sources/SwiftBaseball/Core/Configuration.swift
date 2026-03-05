import Foundation

public struct Configuration: Sendable {
    public var baseURL: URL
    public var cacheEnabled: Bool
    public var cacheTTL: TimeInterval
    public var maxConcurrentRequests: Int
    public var userAgent: String

    public init(
        baseURL: URL = URL(string: "https://statsapi.mlb.com/api/v1/")!,
        cacheEnabled: Bool = false,
        cacheTTL: TimeInterval = 3600,
        maxConcurrentRequests: Int = 5,
        userAgent: String = "SwiftBaseball/0.1.0"
    ) {
        self.baseURL = baseURL
        self.cacheEnabled = cacheEnabled
        self.cacheTTL = cacheTTL
        self.maxConcurrentRequests = maxConcurrentRequests
        self.userAgent = userAgent
    }

    public static let `default` = Configuration()
}
