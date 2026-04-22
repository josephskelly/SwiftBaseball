import Foundation
@testable import SwiftBaseball
import Testing

@Suite("Sabermetrics Tests")
struct SabermetricsTests {
    // MARK: - Fixture decoding

    @Test("Decode sabermetric stats from fixture")
    func decodeSabermetrics() throws {
        let data = try Fixtures.load("player_sabermetrics_660271.json")
        let response = try JSONDecoder.mlb.decode(MLBSabermetricResponse.self, from: data)
        let ref = PlayerReference(id: 660_271, fullName: "Shohei Ohtani")
        let stats = MLBResponseConverters.playerSabermetrics(from: response, playerRef: ref)

        let entry = try #require(stats.first)
        #expect(entry.season == "2024")
        #expect(entry.group == .batting)
        #expect(entry.player.id == 660_271)
        #expect(entry.player.fullName == "Shohei Ohtani")
        #expect(entry.team?.id == 119)
        #expect(entry.team?.name == "Los Angeles Dodgers")
    }

    @Test("Sabermetric stats values decode correctly")
    func sabermetricValues() throws {
        let data = try Fixtures.load("player_sabermetrics_660271.json")
        let response = try JSONDecoder.mlb.decode(MLBSabermetricResponse.self, from: data)
        let ref = PlayerReference(id: 660_271, fullName: "")
        let stats = MLBResponseConverters.playerSabermetrics(from: response, playerRef: ref)

        let saber = try #require(stats.first?.sabermetrics)
        #expect(abs((saber.woba ?? 0) - 0.430549) < 0.0001)
        #expect(abs((saber.wRaa ?? 0) - 70.8202) < 0.01)
        #expect(abs((saber.wRc ?? 0) - 156.331) < 0.01)
        #expect(abs((saber.wRcPlus ?? 0) - 179.678) < 0.01)
        #expect(abs((saber.rar ?? 0) - 86.6456) < 0.01)
        #expect(abs((saber.war ?? 0) - 8.94856) < 0.001)
        #expect(abs((saber.batting ?? 0) - 69.6496) < 0.01)
        #expect(saber.fielding == 0.0)
        #expect(abs((saber.baseRunning ?? 0) - 9.73535) < 0.001)
        #expect(abs((saber.positional ?? 0) - -17.1759) < 0.01)
        #expect(abs((saber.wLeague ?? 0) - 2.33332) < 0.001)
        #expect(abs((saber.replacement ?? 0) - 22.1032) < 0.01)
        #expect(abs((saber.spd ?? 0) - 8.10565) < 0.001)
        #expect(abs((saber.ubr ?? 0) - 1.9) < 0.01)
        #expect(abs((saber.wGdp ?? 0) - 2.2) < 0.01)
        #expect(abs((saber.wSb ?? 0) - 8.7988) < 0.001)
    }

    @Test("Sabermetric entry has nil batting, pitching, fielding")
    func sabermetricGroupRouting() throws {
        let data = try Fixtures.load("player_sabermetrics_660271.json")
        let response = try JSONDecoder.mlb.decode(MLBSabermetricResponse.self, from: data)
        let ref = PlayerReference(id: 660_271, fullName: "")
        let stats = MLBResponseConverters.playerSabermetrics(from: response, playerRef: ref)

        let entry = try #require(stats.first)
        #expect(entry.batting == nil)
        #expect(entry.pitching == nil)
        #expect(entry.fielding == nil)
        #expect(entry.sabermetrics != nil)
    }

    // MARK: - Edge cases

    @Test("Empty splits returns empty array")
    func emptySplits() throws {
        let json = Data("""
        { "stats": [{ "type": {"displayName":"sabermetrics"}, "group": {"displayName":"hitting"}, "splits": [] }] }
        """.utf8)
        let response = try JSONDecoder.mlb.decode(MLBSabermetricResponse.self, from: json)
        let ref = PlayerReference(id: 1, fullName: "")
        let stats = MLBResponseConverters.playerSabermetrics(from: response, playerRef: ref)

        #expect(stats.isEmpty)
    }

    @Test("Empty stats response returns empty array")
    func emptyStatsResponse() throws {
        let json = Data("""
        { "stats": [] }
        """.utf8)
        let response = try JSONDecoder.mlb.decode(MLBSabermetricResponse.self, from: json)
        let ref = PlayerReference(id: 1, fullName: "")
        let stats = MLBResponseConverters.playerSabermetrics(from: response, playerRef: ref)

        #expect(stats.isEmpty)
    }

    @Test("Partial sabermetric payload decodes with nils")
    func partialPayload() throws {
        let json = Data("""
        { "stats": [{ "type": {"displayName":"sabermetrics"}, "group": {"displayName":"hitting"}, "splits": [{
            "season": "2024",
            "stat": { "war": 5.5, "woba": 0.380 },
            "player": {"id": 123, "fullName": "Test Player"},
            "team": {"id": 100, "name": "Test Team"}
        }] }] }
        """.utf8)
        let response = try JSONDecoder.mlb.decode(MLBSabermetricResponse.self, from: json)
        let ref = PlayerReference(id: 123, fullName: "Test Player")
        let stats = MLBResponseConverters.playerSabermetrics(from: response, playerRef: ref)

        let saber = try #require(stats.first?.sabermetrics)
        #expect(abs((saber.war ?? 0) - 5.5) < 0.01)
        #expect(abs((saber.woba ?? 0) - 0.380) < 0.001)
        #expect(saber.wRcPlus == nil)
        #expect(saber.spd == nil)
        #expect(saber.ubr == nil)
    }

    @Test("SabermetricStats.empty has all nil properties")
    func sabermetricStatsEmpty() {
        let empty = SabermetricStats.empty
        #expect(empty.woba == nil)
        #expect(empty.war == nil)
        #expect(empty.wRcPlus == nil)
        #expect(empty.spd == nil)
        #expect(empty.batting == nil)
        #expect(empty.fielding == nil)
    }

    // MARK: - Query builder

    @Test("playerSabermetrics() query builder constructs correct endpoint")
    func sabermetricsQueryBuilder() async throws {
        let mock = MockAPIClient()
        let data = try Fixtures.load("player_sabermetrics_660271.json")
        mock.stub(path: "people/660271/stats", data: data)

        let builder = QueryBuilder<[PlayerSeasonStats]>.playerSabermetrics(id: 660_271, client: mock)
        _ = try await builder.fetch()

        let endpoint = try #require(mock.lastEndpoint)
        #expect(endpoint.path == "people/660271/stats")
        #expect(endpoint.queryItems.contains { $0.name == "stats" && $0.value == "sabermetrics" })
        #expect(endpoint.queryItems.contains { $0.name == "group" && $0.value == "hitting" })
    }

    @Test("playerSabermetrics() with season modifier")
    func sabermetricsWithSeason() async throws {
        let mock = MockAPIClient()
        let data = try Fixtures.load("player_sabermetrics_660271.json")
        mock.stub(path: "people/660271/stats", data: data)

        let builder = QueryBuilder<[PlayerSeasonStats]>.playerSabermetrics(id: 660_271, client: mock)
            .season(2024)
        _ = try await builder.fetch()

        let items = mock.lastEndpoint?.queryItems ?? []
        #expect(items.contains { $0.name == "season" && $0.value == "2024" })
    }

    // MARK: - Regular stats have nil sabermetrics

    @Test("Season batting stats have nil sabermetrics field")
    func seasonStatsNilSabermetrics() throws {
        let data = try Fixtures.load("player_stats_batting_660271.json")
        let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: data)
        let ref = PlayerReference(id: 660_271, fullName: "")
        let stats = MLBResponseConverters.playerSeasonStats(from: response, playerRef: ref)

        let entry = try #require(stats.first)
        #expect(entry.sabermetrics == nil)
    }
}
