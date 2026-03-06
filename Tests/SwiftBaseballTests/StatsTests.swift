import Testing
import Foundation
@testable import SwiftBaseball

@Suite("Stats Tests")
struct StatsTests {

    // MARK: - Batting stats

    @Test("Decode batting stats from fixture")
    func decodeBattingStats() throws {
        let data = try Fixtures.load("player_stats_batting_660271.json")
        let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: data)
        let ref = PlayerReference(id: 660271, fullName: "Shohei Ohtani")
        let stats = MLBResponseConverters.playerSeasonStats(from: response, playerRef: ref)

        let entry = try #require(stats.first)
        #expect(entry.season == "2024")
        #expect(entry.group == .batting)
        #expect(entry.player.id == 660271)
        #expect(entry.player.fullName == "Shohei Ohtani")
        #expect(entry.team?.id == 119)
        #expect(entry.team?.name == "Los Angeles Dodgers")

        let batting = try #require(entry.batting)
        #expect(batting.gamesPlayed == 159)
        #expect(batting.plateAppearances == 731)
        #expect(batting.atBats == 636)
        #expect(batting.runs == 134)
        #expect(batting.hits == 197)
        #expect(batting.doubles == 38)
        #expect(batting.triples == 7)
        #expect(batting.homeRuns == 54)
        #expect(batting.rbi == 130)
        #expect(batting.stolenBases == 59)
        #expect(batting.caughtStealing == 4)
        #expect(batting.baseOnBalls == 81)
        #expect(batting.intentionalWalks == 20)
        #expect(batting.strikeOuts == 162)
        #expect(batting.hitByPitch == 7)
        #expect(batting.sacFlies == 5)
        #expect(batting.sacBunts == 2)
        #expect(batting.groundIntoDoublePlay == 10)
        #expect(batting.totalBases == 411)
        #expect(batting.leftOnBase == 80)
    }

    @Test("Batting rate stats decode from strings")
    func battingRateStats() throws {
        let data = try Fixtures.load("player_stats_batting_660271.json")
        let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: data)
        let ref = PlayerReference(id: 660271, fullName: "")
        let stats = MLBResponseConverters.playerSeasonStats(from: response, playerRef: ref)

        let batting = try #require(stats.first?.batting)
        #expect(batting.avg != nil)
        #expect(abs((batting.avg ?? 0) - 0.310) < 0.001)
        #expect(abs((batting.obp ?? 0) - 0.390) < 0.001)
        #expect(abs((batting.slg ?? 0) - 0.646) < 0.001)
        #expect(abs((batting.ops ?? 0) - 1.036) < 0.001)
        #expect(abs((batting.babip ?? 0) - 0.334) < 0.001)
    }

    @Test("Batting group produces nil pitching and fielding")
    func battingGroupRouting() throws {
        let data = try Fixtures.load("player_stats_batting_660271.json")
        let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: data)
        let ref = PlayerReference(id: 660271, fullName: "")
        let stats = MLBResponseConverters.playerSeasonStats(from: response, playerRef: ref)

        let entry = try #require(stats.first)
        #expect(entry.batting != nil)
        #expect(entry.pitching == nil)
        #expect(entry.fielding == nil)
    }

    // MARK: - Pitching stats

    @Test("Decode pitching stats from fixture")
    func decodePitchingStats() throws {
        let data = try Fixtures.load("player_stats_pitching_660271.json")
        let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: data)
        let ref = PlayerReference(id: 660271, fullName: "Shohei Ohtani")
        let stats = MLBResponseConverters.playerSeasonStats(from: response, playerRef: ref)

        let entry = try #require(stats.first)
        #expect(entry.season == "2023")
        #expect(entry.group == .pitching)
        #expect(entry.team?.id == 108)

        let pitching = try #require(entry.pitching)
        #expect(pitching.gamesPlayed == 23)
        #expect(pitching.gamesStarted == 23)
        #expect(pitching.wins == 10)
        #expect(pitching.losses == 5)
        #expect(pitching.saves == 0)
        #expect(pitching.saveOpportunities == 0)
        #expect(pitching.holds == 0)
        #expect(pitching.blownSaves == 0)
        #expect(pitching.completeGames == 1)
        #expect(pitching.shutouts == 1)
        #expect(pitching.hits == 99)
        #expect(pitching.runs == 50)
        #expect(pitching.earnedRuns == 46)
        #expect(pitching.homeRuns == 15)
        #expect(pitching.baseOnBalls == 55)
        #expect(pitching.intentionalWalks == 2)
        #expect(pitching.strikeOuts == 167)
        #expect(pitching.hitByPitch == 3)
        #expect(pitching.wildPitches == 5)
        #expect(pitching.balks == 0)
        #expect(pitching.battersFaced == 548)
    }

    @Test("Pitching rate stats decode from strings")
    func pitchingRateStats() throws {
        let data = try Fixtures.load("player_stats_pitching_660271.json")
        let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: data)
        let ref = PlayerReference(id: 660271, fullName: "")
        let stats = MLBResponseConverters.playerSeasonStats(from: response, playerRef: ref)

        let pitching = try #require(stats.first?.pitching)
        #expect(abs((pitching.era ?? 0) - 3.14) < 0.01)
        #expect(abs((pitching.whip ?? 0) - 1.06) < 0.01)
        #expect(abs((pitching.avg ?? 0) - 0.196) < 0.001)
        #expect(abs((pitching.inningsPitched ?? 0) - 132.0) < 0.1)
    }

    @Test("Pitching homeRunsAllowed maps to PitchingStats.homeRuns")
    func pitchingHomeRunsMapping() throws {
        let data = try Fixtures.load("player_stats_pitching_660271.json")
        let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: data)
        let ref = PlayerReference(id: 660271, fullName: "")
        let stats = MLBResponseConverters.playerSeasonStats(from: response, playerRef: ref)

        let pitching = try #require(stats.first?.pitching)
        #expect(pitching.homeRuns == 15)
    }

    @Test("Pitching group produces nil batting and fielding")
    func pitchingGroupRouting() throws {
        let data = try Fixtures.load("player_stats_pitching_660271.json")
        let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: data)
        let ref = PlayerReference(id: 660271, fullName: "")
        let stats = MLBResponseConverters.playerSeasonStats(from: response, playerRef: ref)

        let entry = try #require(stats.first)
        #expect(entry.batting == nil)
        #expect(entry.pitching != nil)
        #expect(entry.fielding == nil)
    }

    // MARK: - Edge cases

    @Test("Empty splits returns empty array")
    func emptySplits() throws {
        let json = """
        { "stats": [{ "type": {"displayName":"season","code":"season"}, "group": {"displayName":"hitting","code":"hitting"}, "splits": [] }] }
        """.data(using: .utf8)!
        let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: json)
        let ref = PlayerReference(id: 1, fullName: "")
        let stats = MLBResponseConverters.playerSeasonStats(from: response, playerRef: ref)

        #expect(stats.isEmpty)
    }

    @Test("Empty stats response returns empty array")
    func emptyStatsResponse() throws {
        let json = """
        { "stats": [] }
        """.data(using: .utf8)!
        let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: json)
        let ref = PlayerReference(id: 1, fullName: "")
        let stats = MLBResponseConverters.playerSeasonStats(from: response, playerRef: ref)

        #expect(stats.isEmpty)
    }

    @Test("Zero stat line (0 PA, .000 AVG)")
    func zeroStatLine() throws {
        let json = """
        { "stats": [{ "type": {"displayName":"season","code":"season"}, "group": {"displayName":"hitting","code":"hitting"}, "splits": [{
            "season": "2024",
            "stat": {
                "gamesPlayed": 1, "plateAppearances": 0, "atBats": 0,
                "runs": 0, "hits": 0, "doubles": 0, "triples": 0, "homeRuns": 0,
                "rbi": 0, "stolenBases": 0, "caughtStealing": 0, "baseOnBalls": 0,
                "intentionalWalks": 0, "strikeOuts": 0, "hitByPitch": 0,
                "sacFlies": 0, "sacBunts": 0, "groundIntoDoublePlay": 0,
                "totalBases": 0, "leftOnBase": 0,
                "avg": ".000", "obp": ".000", "slg": ".000", "ops": ".000", "babip": ".000"
            },
            "player": {"id": 999, "fullName": "Test Player"},
            "team": {"id": 100, "name": "Test Team"}
        }] }] }
        """.data(using: .utf8)!
        let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: json)
        let ref = PlayerReference(id: 999, fullName: "Test Player")
        let stats = MLBResponseConverters.playerSeasonStats(from: response, playerRef: ref)

        let batting = try #require(stats.first?.batting)
        #expect(batting.plateAppearances == 0)
        #expect(batting.avg == 0.0)
        #expect(batting.ops == 0.0)
    }

    // MARK: - Query builder

    @Test("playerStats() query builder constructs correct path")
    func playerStatsQueryBuilder() async throws {
        let mock = MockAPIClient()
        let data = try Fixtures.load("player_stats_batting_660271.json")
        mock.stub(path: "people/660271/stats", data: data)

        let builder = QueryBuilder<[PlayerSeasonStats]>.playerStats(id: 660271, client: mock)
        _ = try await builder.fetch()

        let endpoint = try #require(mock.lastEndpoint)
        #expect(endpoint.path == "people/660271/stats")
        #expect(endpoint.queryItems.contains { $0.name == "stats" && $0.value == "season" })
    }

    @Test("playerStats() with season and group modifiers")
    func playerStatsWithModifiers() async throws {
        let mock = MockAPIClient()
        let data = try Fixtures.load("player_stats_batting_660271.json")
        mock.stub(path: "people/660271/stats", data: data)

        let builder = QueryBuilder<[PlayerSeasonStats]>.playerStats(id: 660271, client: mock)
            .season(2024)
            .group(.batting)
        _ = try await builder.fetch()

        let items = mock.lastEndpoint?.queryItems ?? []
        #expect(items.contains { $0.name == "season" && $0.value == "2024" })
        #expect(items.contains { $0.name == "group" && $0.value == "hitting" })
    }

    // MARK: - Static empty instances

    @Test("BattingStats.empty has all nil properties")
    func battingStatsEmpty() {
        let empty = BattingStats.empty
        #expect(empty.gamesPlayed == nil)
        #expect(empty.homeRuns == nil)
        #expect(empty.avg == nil)
    }

    @Test("PitchingStats.empty has all nil properties")
    func pitchingStatsEmpty() {
        let empty = PitchingStats.empty
        #expect(empty.gamesPlayed == nil)
        #expect(empty.era == nil)
        #expect(empty.wins == nil)
    }

    @Test("FieldingStats.empty has all nil properties")
    func fieldingStatsEmpty() {
        let empty = FieldingStats.empty
        #expect(empty.gamesPlayed == nil)
        #expect(empty.errors == nil)
        #expect(empty.fielding == nil)
    }
}
