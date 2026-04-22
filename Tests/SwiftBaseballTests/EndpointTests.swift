import Foundation
@testable import SwiftBaseball
import Testing

@Suite("Endpoint Tests")
struct EndpointTests {
    private let baseURL = URL(string: "https://statsapi.mlb.com/api/v1/")!

    // MARK: - URL construction

    @Test("url() builds correct URL for simple path")
    func urlSimplePath() {
        let endpoint = Endpoint(path: "people/660271")

        let url = endpoint.url(baseURL: baseURL)

        #expect(url?.absoluteString == "https://statsapi.mlb.com/api/v1/people/660271")
    }

    @Test("url() appends query items to URL")
    func urlWithQueryItems() throws {
        let endpoint = Endpoint(path: "schedule", queryItems: [
            URLQueryItem(name: "sportId", value: "1"),
            URLQueryItem(name: "date", value: "2024-07-04")
        ])

        let url = try #require(endpoint.url(baseURL: baseURL))

        let components = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
        let items = components.queryItems ?? []
        #expect(items.contains { $0.name == "sportId" && $0.value == "1" })
        #expect(items.contains { $0.name == "date" && $0.value == "2024-07-04" })
    }

    @Test("url() with no query items produces clean URL")
    func urlNoQueryItems() throws {
        let endpoint = Endpoint(path: "teams")

        let url = try #require(endpoint.url(baseURL: baseURL))

        #expect(url.query == nil)
    }

    // MARK: - adding()

    @Test("adding() appends a new query item")
    func addingAppendsItem() {
        let endpoint = Endpoint(path: "teams")

        let modified = endpoint.adding(name: "season", value: "2024")

        #expect(modified.queryItems.count == 1)
        #expect(modified.queryItems.first?.name == "season")
        #expect(modified.queryItems.first?.value == "2024")
    }

    @Test("adding() with nil value returns unchanged endpoint")
    func addingNilValueIsNoop() {
        let endpoint = Endpoint(path: "teams", queryItems: [
            URLQueryItem(name: "season", value: "2024")
        ])

        let modified = endpoint.adding(name: "league", value: nil)

        #expect(modified.queryItems.count == 1)
        #expect(modified.queryItems == endpoint.queryItems)
    }

    @Test("adding() does not replace existing item with same name")
    func addingDoesNotReplaceDuplicate() {
        let endpoint = Endpoint(path: "teams", queryItems: [
            URLQueryItem(name: "season", value: "2024")
        ])

        let modified = endpoint.adding(name: "season", value: "2025")

        #expect(modified.queryItems.count == 2)
    }

    // MARK: - replacing()

    @Test("replacing() replaces existing item with same name")
    func replacingSwapsValue() {
        let endpoint = Endpoint(path: "standings", queryItems: [
            URLQueryItem(name: "leagueId", value: "103"),
            URLQueryItem(name: "season", value: "2024")
        ])

        let modified = endpoint.replacing(name: "leagueId", value: "104")

        let leagueItems = modified.queryItems.filter { $0.name == "leagueId" }
        #expect(leagueItems.count == 1)
        #expect(leagueItems.first?.value == "104")
    }

    @Test("replacing() adds item when not present")
    func replacingAddsIfAbsent() {
        let endpoint = Endpoint(path: "standings")

        let modified = endpoint.replacing(name: "leagueId", value: "103")

        #expect(modified.queryItems.count == 1)
        #expect(modified.queryItems.first?.value == "103")
    }

    @Test("replacing() preserves other query items")
    func replacingPreservesOtherItems() {
        let endpoint = Endpoint(path: "standings", queryItems: [
            URLQueryItem(name: "leagueId", value: "103"),
            URLQueryItem(name: "season", value: "2024"),
            URLQueryItem(name: "hydrate", value: "division")
        ])

        let modified = endpoint.replacing(name: "leagueId", value: "104")

        #expect(modified.queryItems.count == 3)
        #expect(modified.queryItems.contains { $0.name == "season" && $0.value == "2024" })
        #expect(modified.queryItems.contains { $0.name == "hydrate" && $0.value == "division" })
    }

    // MARK: - Immutability

    @Test("adding() does not mutate original endpoint")
    func addingIsImmutable() {
        let original = Endpoint(path: "teams")

        _ = original.adding(name: "season", value: "2024")

        #expect(original.queryItems.isEmpty)
    }

    @Test("replacing() does not mutate original endpoint")
    func replacingIsImmutable() {
        let original = Endpoint(path: "standings", queryItems: [
            URLQueryItem(name: "leagueId", value: "103")
        ])

        _ = original.replacing(name: "leagueId", value: "104")

        #expect(original.queryItems.first?.value == "103")
    }
}
