import Foundation
@testable import SwiftBaseball
import Testing

@Suite("BatchStats Tests")
struct BatchStatsTests {
    // MARK: - Single player batch

    @Test("Batch of one player returns its stats")
    func batchSinglePlayer() async throws {
        let mock = MockAPIClient()
        let data = try Fixtures.load("player_stats_batting_660271.json")
        mock.stub(path: "people/660271/stats", data: data)

        let query = BatchStatsQuery(
            playerIds: [660_271],
            group: .batting,
            seasonYear: 2024,
            client: mock
        )
        let results = try await query.fetch()

        #expect(!results.isEmpty)
        let entry = try #require(results.first)
        #expect(entry.player.id == 660_271)
        #expect(entry.group == .batting)
    }

    // MARK: - Multi-player batch

    @Test("Batch of two players returns combined results with correct per-player data")
    func batchTwoPlayers() async throws {
        let mock = MockAPIClient()
        let ohtaniData = try Fixtures.load("player_stats_batting_660271.json")
        let judgeData = try Fixtures.load("player_stats_batting_592450.json")
        mock.stub(path: "people/660271/stats", data: ohtaniData)
        mock.stub(path: "people/592450/stats", data: judgeData)

        let query = BatchStatsQuery(
            playerIds: [660_271, 592_450],
            group: .batting,
            seasonYear: 2024,
            client: mock
        )
        let results = try await query.fetch()

        #expect(results.count == 2)
        let ohtani = try #require(results.first { $0.player.id == 660_271 })
        let judge = try #require(results.first { $0.player.id == 592_450 })

        #expect(ohtani.batting?.homeRuns == 54)
        #expect(judge.batting?.homeRuns == 58)
        #expect(ohtani.player.fullName == "Shohei Ohtani")
        #expect(judge.player.fullName == "Aaron Judge")
    }

    // MARK: - season() modifier

    @Test("season() modifier sets season year")
    func seasonModifier() {
        let mock = MockAPIClient()
        let query = BatchStatsQuery(playerIds: [660_271], group: .batting, client: mock)
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
            playerIds: [660_271, 999_999],
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
        let query = SwiftBaseball.batchStats([660_271, 592_450], group: .batting)
        #expect(query.playerIds == [660_271, 592_450])
        #expect(query.group == .batting)
    }
}
