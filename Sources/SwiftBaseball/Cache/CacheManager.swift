import Foundation

// Actor-based in-memory response cache with TTL.
// Enabled via Configuration(cacheEnabled: true).

public actor CacheManager {
    private struct Entry {
        let data: Data
        let expiresAt: Date
    }

    private var store: [String: Entry] = [:]
    private let defaultTTL: TimeInterval

    public init(defaultTTL: TimeInterval = 3600) {
        self.defaultTTL = defaultTTL
    }

    // MARK: - Public API

    public func get(key: String) -> Data? {
        guard let entry = store[key], entry.expiresAt > Date() else {
            store.removeValue(forKey: key)
            return nil
        }
        return entry.data
    }

    public func set(key: String, data: Data, ttl: TimeInterval? = nil) {
        let expiry = Date().addingTimeInterval(ttl ?? defaultTTL)
        store[key] = Entry(data: data, expiresAt: expiry)
    }

    public func invalidate(key: String) {
        store.removeValue(forKey: key)
    }

    public func purgeAll() {
        store.removeAll()
    }

    public func purgeExpired() {
        let now = Date()
        store = store.filter { $0.value.expiresAt > now }
    }

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
