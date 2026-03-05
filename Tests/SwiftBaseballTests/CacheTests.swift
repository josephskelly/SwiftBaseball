import Testing
import Foundation
@testable import SwiftBaseball

@Suite("Cache Tests")
struct CacheTests {

    @Test("Cache stores and retrieves data")
    func cacheStoresAndRetrieves() async {
        let cache = CacheManager(defaultTTL: 60)
        let data = "hello".data(using: .utf8)!

        await cache.set(key: "test", data: data)
        let retrieved = await cache.get(key: "test")

        #expect(retrieved == data)
    }

    @Test("Cache returns nil for missing key")
    func cacheMissReturnsNil() async {
        let cache = CacheManager()
        let result = await cache.get(key: "nonexistent")
        #expect(result == nil)
    }

    @Test("Cache evicts expired entries")
    func cacheEvictsExpired() async throws {
        let cache = CacheManager(defaultTTL: 0.05)  // 50ms TTL
        let data = "expires_soon".data(using: .utf8)!

        await cache.set(key: "short-lived", data: data)

        // Verify it's there immediately
        let immediate = await cache.get(key: "short-lived")
        #expect(immediate != nil)

        // Wait for expiry
        try await Task.sleep(for: .milliseconds(100))

        let afterExpiry = await cache.get(key: "short-lived")
        #expect(afterExpiry == nil)
    }

    @Test("Cache count reflects stored entries")
    func cacheCount() async {
        let cache = CacheManager()

        #expect(await cache.count == 0)

        await cache.set(key: "a", data: Data())
        await cache.set(key: "b", data: Data())
        #expect(await cache.count == 2)
    }

    @Test("purgeAll removes all entries")
    func cachePurgeAll() async {
        let cache = CacheManager()
        await cache.set(key: "a", data: Data())
        await cache.set(key: "b", data: Data())

        await cache.purgeAll()

        #expect(await cache.count == 0)
        #expect(await cache.get(key: "a") == nil)
    }

    @Test("invalidate removes specific key")
    func cacheInvalidateKey() async {
        let cache = CacheManager()
        let dataA = "a".data(using: .utf8)!
        let dataB = "b".data(using: .utf8)!

        await cache.set(key: "a", data: dataA)
        await cache.set(key: "b", data: dataB)
        await cache.invalidate(key: "a")

        #expect(await cache.get(key: "a") == nil)
        #expect(await cache.get(key: "b") != nil)
    }

    @Test("CachingAPIClient returns cached data on second call")
    func cachingClientHit() async throws {
        let mock = MockAPIClient()
        let data = try Fixtures.load("player_search_ohtani.json")
        mock.stub(path: "people/search", data: data)

        let cache = CacheManager(defaultTTL: 60)
        let client = CachingAPIClient(wrapped: mock, cache: cache, ttl: 60)

        let endpoint = Endpoint(path: "people/search", queryItems: [
            URLQueryItem(name: "names", value: "Ohtani")
        ])

        _ = try await client.fetchRaw(endpoint)
        _ = try await client.fetchRaw(endpoint)

        // Underlying mock should only have been called once (second call was cached)
        #expect(mock.callCount == 1)
    }
}
