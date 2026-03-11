import Testing
import Foundation
@testable import SwiftBaseball

@Suite("BatchStats Tests")
struct BatchStatsTests {

    // MARK: - Single player batch

    @Test("Batch of one player returns its stats")
    func batchSinglePlayer() async throws {
        let mock = MockAPIClient()
        let data = try Fixtures.load("player_stats_batting_660271.json")
        mock.stub(path: "people/660271/stats", data: data)

        let query = BatchStatsQuery(
            playerIds: [660271],
            group: .batting,
            seasonYear: 2024,
            client: mock
        )
        let results = try await query.fetch()

        #expect(!results.isEmpty)
        let entry = try #require(results.first)
        #expect(entry.player.id == 660271)
        #expect(entry.group == .batting)
    }

    // MARK: - Multi-player batch

    @Test("Batch of two players returns combined results")
    func batchTwoPlayers() async throws {
        let mock = MockAPIClient()
        let battingData = try Fixtures.load("player_stats_batting_660271.json")
        // Re-use the same fixture for player 592450 — we only care about result count
        mock.stub(path: "people/660271/stats", data: battingData)
        mock.stub(path: "people/592450/stats", data: battingData)

        let query = BatchStatsQuery(
            playerIds: [660271, 592450],
            group: .batting,
            seasonYear: 2024,
            client: mock
        )
        let results = try await query.fetch()
        // Two players × one season entry each
        #expect(results.count >= 2)
    }

    // MARK: - season() modifier

    @Test("season() modifier sets season year")
    func seasonModifier() {
        let mock = MockAPIClient()
        let query = BatchStatsQuery(playerIds: [660271], group: .batting, client: mock)
            .season(2023)
        #expect(query.seasonYear == 2023)
    }

    // MARK: - Empty player list

    @Test("Empty player list returns empty results")
    func emptyPlayerList() async throws {
        let mock = MockAPIClient()
        let query = BatchStatsQuery(playerIds: [], group: .batting, client: mock)
        let results = try await query.fetch()
        #expect(results.isEmpty)
    }

    // MARK: - Partial failure

    @Test("Partial failure (one bad player ID) propagates error")
    func partialFailurePropagates() async throws {
        let mock = MockAPIClient()
        let battingData = try Fixtures.load("player_stats_batting_660271.json")
        mock.stub(path: "people/660271/stats", data: battingData)
        // No stub for player 999999 — MockAPIClient will throw configurationError

        let query = BatchStatsQuery(
            playerIds: [660271, 999999],
            group: .batting,
            client: mock
        )
        await #expect(throws: SwiftBaseballError.self) {
            _ = try await query.fetch()
        }
    }

    // MARK: - SwiftBaseball namespace entry point

    @Test("SwiftBaseball.batchStats returns BatchStatsQuery")
    func namespacedBatchStats() {
        // Verifies the public API compiles and returns the right type
        let query = SwiftBaseball.batchStats([660271, 592450], group: .batting)
        #expect(query.playerIds == [660271, 592450])
        #expect(query.group == .batting)
    }
}
