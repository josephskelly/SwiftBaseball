import Foundation

/// Actor-based in-memory response cache with configurable TTL.
///
/// Enabled via ``Configuration/cacheEnabled``. Entries expire after the configured TTL.
public actor CacheManager {
    private struct Entry {
        let data: Data
        let expiresAt: Date
    }

    private var store: [String: Entry] = [:]
    private let defaultTTL: TimeInterval

    /// Creates a cache manager with the specified default TTL.
    ///
    /// - Parameter defaultTTL: Time-to-live in seconds for cached entries. Defaults to 3600 (1 hour).
    public init(defaultTTL: TimeInterval = 3600) {
        self.defaultTTL = defaultTTL
    }

    // MARK: - Public API

    /// Retrieves cached data for the given key, or `nil` if expired or missing.
    public func get(key: String) -> Data? {
        guard let entry = store[key], entry.expiresAt > Date() else {
            store.removeValue(forKey: key)
            return nil
        }
        return entry.data
    }

    /// Stores data in the cache with an optional custom TTL.
    public func set(key: String, data: Data, ttl: TimeInterval? = nil) {
        let expiry = Date().addingTimeInterval(ttl ?? defaultTTL)
        store[key] = Entry(data: data, expiresAt: expiry)
    }

    /// Removes a single entry from the cache.
    public func invalidate(key: String) {
        store.removeValue(forKey: key)
    }

    /// Removes all entries from the cache.
    public func purgeAll() {
        store.removeAll()
    }

    /// Removes all expired entries from the cache.
    public func purgeExpired() {
        let now = Date()
        store = store.filter { $0.value.expiresAt > now }
    }

    /// The number of entries currently in the cache (including expired).
    public var count: Int { store.count }
}

// MARK: - Caching APIClient wrapper

final class CachingAPIClient: APIClient {
    private let wrapped: any APIClient
    private let cache: CacheManager
    private let ttl: TimeInterval

    init(wrapped: any APIClient, cache: CacheManager, ttl: TimeInterval) {
        self.wrapped = wrapped
        self.cache = cache
        self.ttl = ttl
    }

    func fetchRaw(_ endpoint: Endpoint) async throws -> Data {
        let key = cacheKey(for: endpoint)

        if let cached = await cache.get(key: key) {
            return cached
        }

        let data = try await wrapped.fetchRaw(endpoint)
        await cache.set(key: key, data: data, ttl: ttl)
        return data
    }

    private func cacheKey(for endpoint: Endpoint) -> String {
        let params = endpoint.queryItems
            .sorted { $0.name < $1.name }
            .map { "\($0.name)=\($0.value ?? "")" }
            .joined(separator: "&")
        return "\(endpoint.path)?\(params)"
    }
}

extension CachingAPIClient: @unchecked Sendable {}
