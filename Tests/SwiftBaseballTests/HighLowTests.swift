import Foundation
@testable import SwiftBaseball
import Testing

@Suite("High / Low Tests")
struct HighLowTests {
    @Test("Player highLow decodes peaks with player and stat value")
    func playerDecodesPeaks() async throws {
        let mock = MockAPIClient()
        let data = try Fixtures.load("highlow_player_homeruns_2024.json")
        mock.stub(path: "highLow/player", data: data)

        let splits = try await QueryBuilder<[HighLowSplit]>
            .highLowPlayer(
                group: .batting,
                sortStat: .homeRuns,
                season: 2024,
                direction: .high,
                client: mock
            )
            .fetch()

        #expect(splits.count == 5)
        let top = try #require(splits.first)
        #expect(top.season == 2024)
        #expect(top.statName == "homeRuns")
        #expect(top.statValue == 3)
        #expect(top.player?.fullName == "Yordan Alvarez")
        #expect(top.team.id == 117)
        #expect(top.opponent.id == 143)
        #expect(top.rank == 1)
        #expect(top.gamePk == 745_541)
        #expect(top.isHome == false)
    }

    @Test("Team highLow decodes peaks with no player attached")
    func teamDecodesPeaks() async throws {
        let mock = MockAPIClient()
        let data = try Fixtures.load("highlow_team_homeruns_2024.json")
        mock.stub(path: "highLow/team", data: data)

        let splits = try await QueryBuilder<[HighLowSplit]>
            .highLowTeam(
                group: .batting,
                sortStat: .homeRuns,
                season: 2024,
                direction: .high,
                client: mock
            )
            .fetch()

        #expect(splits.count == 5)
        let top = try #require(splits.first)
        #expect(top.statValue == 8)
        #expect(top.team.id == 133)
        #expect(top.opponent.id == 143)
        #expect(top.player == nil)
    }

    @Test("Player query builder uses correct path and params")
    func playerEndpointBuilder() async throws {
        let mock = MockAPIClient()
        let data = try Fixtures.load("highlow_player_homeruns_2024.json")
        mock.stub(path: "highLow/player", data: data)

        _ = try await QueryBuilder<[HighLowSplit]>
            .highLowPlayer(
                group: .batting,
                sortStat: .homeRuns,
                season: 2024,
                direction: .high,
                client: mock
            )
            .fetch()

        let endpoint = try #require(mock.lastEndpoint)
        #expect(endpoint.path == "highLow/player")
        let params = Dictionary(uniqueKeysWithValues: endpoint.queryItems.compactMap { item in
            item.value.map { (item.name, $0) }
        })
        #expect(params["statGroup"] == "hitting")
        #expect(params["season"] == "2024")
        #expect(params["sortStat"] == "homeRuns")
        #expect(params["highLow"] == "high")
    }

    @Test("Direction switches highLow query parameter")
    func directionParameter() async throws {
        let mock = MockAPIClient()
        let data = try Fixtures.load("highlow_player_homeruns_2024.json")
        mock.stub(path: "highLow/player", data: data)

        _ = try await QueryBuilder<[HighLowSplit]>
            .highLowPlayer(
                group: .batting,
                sortStat: .homeRuns,
                season: 2024,
                direction: .low,
                client: mock
            )
            .fetch()

        let item = mock.lastEndpoint?.queryItems.first { $0.name == "highLow" }
        #expect(item?.value == "low")
    }
}
