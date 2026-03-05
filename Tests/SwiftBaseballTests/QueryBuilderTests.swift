import Testing
import Foundation
@testable import SwiftBaseball

@Suite("QueryBuilder Tests")
struct QueryBuilderTests {

    // MARK: - Fluent modifier chain

    @Test("season() appends season query item")
    func seasonModifier() async throws {
        let mock = MockAPIClient()
        let data = try Fixtures.load("teams_2024.json")
        mock.stub(path: "teams", data: data)

        let builder = QueryBuilder<[Team]>.teams(.all(season: 2024), client: mock)
            .season(2025)  // Override season

        _ = try await builder.fetch()

        let items = mock.lastEndpoint?.queryItems ?? []
        // Both season=2024 (from TeamQuery) and season=2025 (from modifier) will be present
        // The modifier appends — last value wins in most URL implementations
        #expect(items.contains { $0.name == "season" && $0.value == "2025" })
    }

    @Test("limit() appends limit query item")
    func limitModifier() {
        let mock = MockAPIClient()
        let builder = QueryBuilder<[Team]>.teams(.all(season: 2024), client: mock)
            .limit(10)

        let items = builder.endpoint.queryItems
        #expect(items.contains { $0.name == "limit" && $0.value == "10" })
    }

    @Test("league() appends leagueId query item for AL")
    func leagueModifierAL() {
        let mock = MockAPIClient()
        let builder = QueryBuilder<[Team]>.teams(.all(season: 2024), client: mock)
            .league(.american)

        let items = builder.endpoint.queryItems
        #expect(items.contains { $0.name == "leagueId" && $0.value == "103" })
    }

    @Test("league() appends leagueId query item for NL")
    func leagueModifierNL() {
        let mock = MockAPIClient()
        let builder = QueryBuilder<[Team]>.teams(.all(season: 2024), client: mock)
            .league(.national)

        let items = builder.endpoint.queryItems
        #expect(items.contains { $0.name == "leagueId" && $0.value == "104" })
    }

    @Test("teamId() appends teamId query item")
    func teamIdModifier() {
        let mock = MockAPIClient()
        let builder = QueryBuilder<[ScheduleEntry]>.schedule(.season(2024), client: mock)
            .teamId(147)

        let items = builder.endpoint.queryItems
        #expect(items.contains { $0.name == "teamId" && $0.value == "147" })
    }

    @Test("dateRange() appends start/end date items")
    func dateRangeModifier() {
        let mock = MockAPIClient()
        let builder = QueryBuilder<[ScheduleEntry]>.schedule(.season(2024), client: mock)
            .dateRange(start: "2024-04-01", end: "2024-09-30")

        let items = builder.endpoint.queryItems
        #expect(items.contains { $0.name == "startDate" && $0.value == "2024-04-01" })
        #expect(items.contains { $0.name == "endDate" && $0.value == "2024-09-30" })
    }

    @Test("Chained modifiers are immutable — original unchanged")
    func immutableChaining() {
        let mock = MockAPIClient()
        let original = QueryBuilder<[ScheduleEntry]>.schedule(.season(2024), client: mock)
        let modified = original.teamId(147).limit(50)

        let originalItems = original.endpoint.queryItems
        let modifiedItems = modified.endpoint.queryItems

        #expect(!originalItems.contains { $0.name == "teamId" })
        #expect(modifiedItems.contains { $0.name == "teamId" && $0.value == "147" })
        #expect(modifiedItems.contains { $0.name == "limit" && $0.value == "50" })
    }

    @Test("fetch() propagates network errors")
    func fetchPropagatesNetworkErrors() async throws {
        let mock = MockAPIClient()
        let urlError = URLError(.notConnectedToInternet)
        mock.stub(path: "teams", error: SwiftBaseballError.networkError(urlError))

        let builder = QueryBuilder<[Team]>.teams(.all(season: 2024), client: mock)

        await #expect(throws: SwiftBaseballError.self) {
            _ = try await builder.fetch()
        }
    }

    @Test("fetch() throws decodingError for malformed JSON")
    func fetchThrowsDecodingError() async throws {
        let mock = MockAPIClient()
        let badJSON = "{ invalid }".data(using: .utf8)!
        mock.stub(path: "teams", data: badJSON)

        let builder = QueryBuilder<[Team]>.teams(.all(season: 2024), client: mock)

        await #expect(throws: SwiftBaseballError.self) {
            _ = try await builder.fetch()
        }
    }
}
