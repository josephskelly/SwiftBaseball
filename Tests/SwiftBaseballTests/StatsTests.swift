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
        #expect(abs((pitching.obp ?? 0) - 0.302) < 0.001)
        #expect(abs((pitching.slg ?? 0) - 0.362) < 0.001)
        #expect(abs((pitching.ops ?? 0) - 0.664) < 0.001)
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

    // MARK: - Fielding stats

    @Test("Decode fielding stats from fixture")
    func decodeFieldingStats() throws {
        let data = try Fixtures.load("player_stats_fielding_660271.json")
        let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: data)
        let ref = PlayerReference(id: 660271, fullName: "Shohei Ohtani")
        let stats = MLBResponseConverters.playerSeasonStats(from: response, playerRef: ref)

        let entry = try #require(stats.first)
        #expect(entry.season == "2023")
        #expect(entry.group == .fielding)
        #expect(entry.team?.id == 108)

        let fielding = try #require(entry.fielding)
        #expect(fielding.gamesPlayed == 23)
        #expect(fielding.gamesStarted == 23)
        #expect(fielding.assists == 12)
        #expect(fielding.putOuts == 8)
        #expect(fielding.errors == 1)
        #expect(fielding.chances == 21)
        #expect(fielding.doublePlays == 2)
        #expect(fielding.triplePlays == 0)
        #expect(fielding.passedBalls == 0)
    }

    @Test("Fielding rate stats decode from strings")
    func fieldingRateStats() throws {
        let data = try Fixtures.load("player_stats_fielding_660271.json")
        let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: data)
        let ref = PlayerReference(id: 660271, fullName: "")
        let stats = MLBResponseConverters.playerSeasonStats(from: response, playerRef: ref)

        let fielding = try #require(stats.first?.fielding)
        #expect(abs((fielding.innings ?? 0) - 132.0) < 0.01)
        #expect(abs((fielding.fielding ?? 0) - 0.952) < 0.001)
    }

    @Test("Fielding group produces nil batting and pitching")
    func fieldingGroupRouting() throws {
        let data = try Fixtures.load("player_stats_fielding_660271.json")
        let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: data)
        let ref = PlayerReference(id: 660271, fullName: "")
        let stats = MLBResponseConverters.playerSeasonStats(from: response, playerRef: ref)

        let entry = try #require(stats.first)
        #expect(entry.batting == nil)
        #expect(entry.pitching == nil)
        #expect(entry.fielding != nil)
    }

    // MARK: - Edge cases

    @Test("Empty splits returns empty array")
    func emptySplits() throws {
        let json = """
        { "stats": [{ "type": {"displayName":"season"}, "group": {"displayName":"hitting"}, "splits": [] }] }
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
        { "stats": [{ "type": {"displayName":"season"}, "group": {"displayName":"hitting"}, "splits": [{
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

    // MARK: - Projected stats

    @Test("Decode projected batting stats from fixture")
    func decodeProjectedBattingStats() throws {
        let data = try Fixtures.load("player_stats_projected_660271.json")
        let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: data)
        let ref = PlayerReference(id: 660271, fullName: "Shohei Ohtani")
        let stats = MLBResponseConverters.playerSeasonStats(from: response, playerRef: ref)

        let entry = try #require(stats.first)
        #expect(entry.season == "2024")
        #expect(entry.group == .batting)
        #expect(entry.player.id == 660271)

        let batting = try #require(entry.batting)
        #expect(batting.gamesPlayed == 155)
        #expect(batting.homeRuns == 48)
        #expect(batting.stolenBases == 52)
        #expect(abs((batting.avg ?? 0) - 0.305) < 0.001)
        #expect(abs((batting.ops ?? 0) - 1.015) < 0.001)
    }

    @Test("playerProjectedStats endpoint uses stats=projected")
    func playerProjectedStatsEndpointParams() async throws {
        let mock = MockAPIClient()
        let data = try Fixtures.load("player_stats_projected_660271.json")
        mock.stub(path: "people/660271/stats", data: data)
        _ = try await QueryBuilder<[PlayerSeasonStats]>
            .playerProjectedStats(id: 660271, client: mock)
            .group(.batting)
            .fetch()
        let items = mock.lastEndpoint?.queryItems ?? []
        #expect(items.contains { $0.name == "stats" && $0.value == "projected" })
        #expect(items.contains { $0.name == "group" && $0.value == "hitting" })
    }

    @Test("SwiftBaseball.playerProjectedStats is accessible")
    func namespacedPlayerProjected() {
        _ = SwiftBaseball.playerProjectedStats(id: 660271)
    }

    @Test("Projected stats empty response returns empty array")
    func projectedStatsEmptyResponse() throws {
        let json = """
        { "stats": [] }
        """.data(using: .utf8)!
        let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: json)
        let ref = PlayerReference(id: 660271, fullName: "")
        let stats = MLBResponseConverters.playerSeasonStats(from: response, playerRef: ref)
        #expect(stats.isEmpty)
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
        #expect(empty.obp == nil)
        #expect(empty.slg == nil)
        #expect(empty.ops == nil)
    }

    @Test("FieldingStats.empty has all nil properties")
    func fieldingStatsEmpty() {
        let empty = FieldingStats.empty
        #expect(empty.gamesPlayed == nil)
        #expect(empty.errors == nil)
        #expect(empty.fielding == nil)
    }

    // MARK: - Platoon splits

    @Test("Decode platoon splits from fixture")
    func decodePlatoonSplits() throws {
        let data = try Fixtures.load("player_stats_platoon_660271.json")
        let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: data)
        let ref = PlayerReference(id: 660271, fullName: "Shohei Ohtani")
        let platoon = MLBResponseConverters.playerPlatoonStats(from: response, playerRef: ref)

        let vsLeft = try #require(platoon.vsLeft)
        #expect(vsLeft.gamesPlayed == 114)
        #expect(vsLeft.homeRuns == 12)
        #expect(vsLeft.ops == 0.867)
        #expect(vsLeft.avg == 0.288)

        let vsRight = try #require(platoon.vsRight)
        #expect(vsRight.gamesPlayed == 145)
        #expect(vsRight.homeRuns == 42)
        #expect(vsRight.ops == 1.128)
        #expect(vsRight.avg == 0.322)
    }

    @Test("Empty platoon splits returns both nil")
    func emptyPlatoonSplits() throws {
        let json = """
        { "stats": [{ "type": {"displayName":"statSplits"}, "group": {"displayName":"hitting"}, "splits": [] }] }
        """.data(using: .utf8)!
        let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: json)
        let ref = PlayerReference(id: 1, fullName: "")
        let platoon = MLBResponseConverters.playerPlatoonStats(from: response, playerRef: ref)

        #expect(platoon.vsLeft == nil)
        #expect(platoon.vsRight == nil)
    }

    @Test("Platoon splits with only vs-left present")
    func platoonSplitsOnlyVsLeft() throws {
        let json = """
        { "stats": [{ "type": {"displayName":"statSplits"}, "group": {"displayName":"hitting"}, "splits": [{
            "season": "2024",
            "stat": {
                "gamesPlayed": 50, "plateAppearances": 100, "atBats": 90,
                "runs": 10, "hits": 25, "doubles": 5, "triples": 1, "homeRuns": 3,
                "rbi": 12, "stolenBases": 2, "caughtStealing": 1, "baseOnBalls": 8,
                "intentionalWalks": 0, "strikeOuts": 20, "hitByPitch": 1,
                "sacFlies": 1, "sacBunts": 0, "groundIntoDoublePlay": 2,
                "totalBases": 41, "leftOnBase": 30,
                "avg": ".278", "obp": ".340", "slg": ".456", "ops": ".796", "babip": ".310"
            },
            "split": {"code": "vl", "description": "vs Left"}
        }] }] }
        """.data(using: .utf8)!
        let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: json)
        let ref = PlayerReference(id: 1, fullName: "")
        let platoon = MLBResponseConverters.playerPlatoonStats(from: response, playerRef: ref)

        #expect(platoon.vsLeft != nil)
        #expect(platoon.vsLeft?.ops == 0.796)
        #expect(platoon.vsRight == nil)
    }

    @Test("playerPlatoonStats() query builder constructs correct endpoint")
    func platoonStatsQueryBuilder() async throws {
        let mock = MockAPIClient()
        let data = try Fixtures.load("player_stats_platoon_660271.json")
        mock.stub(path: "people/660271/stats", data: data)

        let builder = QueryBuilder<PlayerPlatoonStats>.playerPlatoonStats(id: 660271, client: mock)
            .season(2024)
        _ = try await builder.fetch()

        let items = mock.lastEndpoint?.queryItems ?? []
        #expect(items.contains { $0.name == "stats" && $0.value == "statSplits" })
        #expect(items.contains { $0.name == "sitCodes" && $0.value == "vl,vr" })
        #expect(items.contains { $0.name == "group" && $0.value == "hitting" })
        #expect(items.contains { $0.name == "season" && $0.value == "2024" })
    }

    // MARK: - Pitcher platoon splits

    @Test("Decode pitcher platoon splits from fixture")
    func decodePitcherPlatoonSplits() throws {
        let data = try Fixtures.load("pitcher_stats_platoon_660271.json")
        let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: data)
        let ref = PlayerReference(id: 660271, fullName: "Shohei Ohtani")
        let platoon = MLBResponseConverters.pitcherPlatoonStats(from: response, playerRef: ref)

        let vsLeft = try #require(platoon.vsLeft)
        #expect(vsLeft.gamesPlayed == 23)
        #expect(vsLeft.ops == 0.653)
        #expect(vsLeft.obp == 0.276)
        #expect(vsLeft.whip == 1.08)
        #expect(vsLeft.strikeOuts == 76)
        #expect(vsLeft.battersFaced == 255)

        let vsRight = try #require(platoon.vsRight)
        #expect(vsRight.gamesPlayed == 23)
        #expect(vsRight.ops == 0.582)
        #expect(vsRight.obp == 0.293)
        #expect(vsRight.whip == 1.05)
        #expect(vsRight.strikeOuts == 91)
        #expect(vsRight.battersFaced == 276)
    }

    @Test("Empty pitcher platoon splits returns both nil")
    func emptyPitcherPlatoonSplits() throws {
        let json = """
        { "stats": [{ "type": {"displayName":"statSplits"}, "group": {"displayName":"pitching"}, "splits": [] }] }
        """.data(using: .utf8)!
        let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: json)
        let ref = PlayerReference(id: 1, fullName: "")
        let platoon = MLBResponseConverters.pitcherPlatoonStats(from: response, playerRef: ref)

        #expect(platoon.vsLeft == nil)
        #expect(platoon.vsRight == nil)
    }

    @Test("Pitcher platoon splits with only vs-left present")
    func pitcherPlatoonSplitsOnlyVsLeft() throws {
        let json = """
        { "stats": [{ "type": {"displayName":"statSplits"}, "group": {"displayName":"pitching"}, "splits": [{
            "season": "2023",
            "stat": {
                "gamesPlayed": 20, "hits": 30, "runs": 15, "earnedRuns": 12,
                "homeRuns": 5, "strikeOuts": 50, "baseOnBalls": 10,
                "intentionalWalks": 0, "hitByPitch": 1, "balks": 0, "wildPitches": 2,
                "battersFaced": 150, "inningsPitched": "45.0",
                "avg": ".210", "obp": ".290", "slg": ".350", "ops": ".640",
                "whip": "0.89"
            },
            "split": {"code": "vl", "description": "vs Left"}
        }] }] }
        """.data(using: .utf8)!
        let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: json)
        let ref = PlayerReference(id: 1, fullName: "")
        let platoon = MLBResponseConverters.pitcherPlatoonStats(from: response, playerRef: ref)

        #expect(platoon.vsLeft != nil)
        #expect(platoon.vsLeft?.ops == 0.640)
        #expect(platoon.vsRight == nil)
    }

    @Test("pitcherPlatoonStats() query builder constructs correct endpoint")
    func pitcherPlatoonStatsQueryBuilder() async throws {
        let mock = MockAPIClient()
        let data = try Fixtures.load("pitcher_stats_platoon_660271.json")
        mock.stub(path: "people/660271/stats", data: data)

        let builder = QueryBuilder<PitcherPlatoonStats>.pitcherPlatoonStats(id: 660271, client: mock)
            .season(2023)
        _ = try await builder.fetch()

        let items = mock.lastEndpoint?.queryItems ?? []
        #expect(items.contains { $0.name == "stats" && $0.value == "statSplits" })
        #expect(items.contains { $0.name == "sitCodes" && $0.value == "vl,vr" })
        #expect(items.contains { $0.name == "group" && $0.value == "pitching" })
        #expect(items.contains { $0.name == "season" && $0.value == "2023" })
    }

    // MARK: - Deduplication and aggregation across game types

    @Test("Batter platoon deduplicates repeated splits from comma-separated gameType")
    func batterPlatoonDedup() throws {
        // Simulate the API returning 8× duplicated splits (as observed with gameType=R,S,E,F,D,L,W,A)
        let json = """
        { "stats": [{ "type": {"displayName":"statSplits"}, "group": {"displayName":"hitting"}, "splits": [
            {"split":{"code":"vl","description":"vs Left"},"gameType":"R","stat":{"gamesPlayed":100,"plateAppearances":200,"atBats":180,"hits":50,"doubles":10,"triples":1,"homeRuns":8,"rbi":30,"stolenBases":5,"caughtStealing":1,"baseOnBalls":15,"intentionalWalks":0,"strikeOuts":40,"hitByPitch":2,"sacFlies":1,"sacBunts":0,"groundIntoDoublePlay":3,"totalBases":90,"leftOnBase":60,"avg":".278","obp":".338","slg":".500","ops":".838","babip":".310"}},
            {"split":{"code":"vl","description":"vs Left"},"gameType":"S","stat":{"gamesPlayed":5,"plateAppearances":10,"atBats":9,"hits":3,"doubles":1,"triples":0,"homeRuns":1,"rbi":2,"stolenBases":0,"caughtStealing":0,"baseOnBalls":1,"intentionalWalks":0,"strikeOuts":2,"hitByPitch":0,"sacFlies":0,"sacBunts":0,"groundIntoDoublePlay":0,"totalBases":7,"leftOnBase":3,"avg":".333","obp":".400","slg":".778","ops":"1.178","babip":".286"}},
            {"split":{"code":"vl","description":"vs Left"},"gameType":"R","stat":{"gamesPlayed":100,"plateAppearances":200,"atBats":180,"hits":50,"doubles":10,"triples":1,"homeRuns":8,"rbi":30,"stolenBases":5,"caughtStealing":1,"baseOnBalls":15,"intentionalWalks":0,"strikeOuts":40,"hitByPitch":2,"sacFlies":1,"sacBunts":0,"groundIntoDoublePlay":3,"totalBases":90,"leftOnBase":60,"avg":".278","obp":".338","slg":".500","ops":".838","babip":".310"}},
            {"split":{"code":"vl","description":"vs Left"},"gameType":"S","stat":{"gamesPlayed":5,"plateAppearances":10,"atBats":9,"hits":3,"doubles":1,"triples":0,"homeRuns":1,"rbi":2,"stolenBases":0,"caughtStealing":0,"baseOnBalls":1,"intentionalWalks":0,"strikeOuts":2,"hitByPitch":0,"sacFlies":0,"sacBunts":0,"groundIntoDoublePlay":0,"totalBases":7,"leftOnBase":3,"avg":".333","obp":".400","slg":".778","ops":"1.178","babip":".286"}},
            {"split":{"code":"vr","description":"vs Right"},"gameType":"R","stat":{"gamesPlayed":120,"plateAppearances":400,"atBats":350,"hits":100,"doubles":20,"triples":3,"homeRuns":30,"rbi":70,"stolenBases":15,"caughtStealing":2,"baseOnBalls":40,"intentionalWalks":5,"strikeOuts":80,"hitByPitch":3,"sacFlies":2,"sacBunts":0,"groundIntoDoublePlay":5,"totalBases":220,"leftOnBase":100,"avg":".286","obp":".362","slg":".629","ops":".990","babip":".300"}},
            {"split":{"code":"vr","description":"vs Right"},"gameType":"R","stat":{"gamesPlayed":120,"plateAppearances":400,"atBats":350,"hits":100,"doubles":20,"triples":3,"homeRuns":30,"rbi":70,"stolenBases":15,"caughtStealing":2,"baseOnBalls":40,"intentionalWalks":5,"strikeOuts":80,"hitByPitch":3,"sacFlies":2,"sacBunts":0,"groundIntoDoublePlay":5,"totalBases":220,"leftOnBase":100,"avg":".286","obp":".362","slg":".629","ops":".990","babip":".300"}}
        ]}]}
        """.data(using: .utf8)!

        let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: json)
        let ref = PlayerReference(id: 1, fullName: "Test")
        let platoon = MLBResponseConverters.playerPlatoonStats(from: response, playerRef: ref)

        // vL should aggregate R + S (not count duplicates)
        let vl = try #require(platoon.vsLeft)
        #expect(vl.plateAppearances == 210)  // 200 + 10
        #expect(vl.atBats == 189)  // 180 + 9
        #expect(vl.hits == 53)  // 50 + 3
        #expect(vl.homeRuns == 9)  // 8 + 1
        #expect(vl.totalBases == 97)  // 90 + 7

        // OPS recomputed from aggregated counts
        let obpDenom = 189 + 16 + 2 + 1  // AB + BB + HBP + SF
        let expectedOBP = Double(53 + 16 + 2) / Double(obpDenom)
        let expectedSLG = Double(97) / Double(189)
        let expectedOPS = expectedOBP + expectedSLG
        #expect(abs((vl.ops ?? 0) - expectedOPS) < 0.001)

        // vR should have only R (one unique gameType)
        let vr = try #require(platoon.vsRight)
        #expect(vr.plateAppearances == 400)
        #expect(vr.atBats == 350)
        #expect(vr.ops == 0.990)  // Single entry, returned as-is
    }

    @Test("Pitcher platoon deduplicates and aggregates across game types")
    func pitcherPlatoonDedup() throws {
        let json = """
        { "stats": [{ "type": {"displayName":"statSplits"}, "group": {"displayName":"pitching"}, "splits": [
            {"split":{"code":"vl","description":"vs Left"},"gameType":"R","stat":{"gamesPlayed":20,"gamesStarted":20,"wins":5,"losses":3,"saves":0,"saveOpportunities":0,"holds":0,"blownSaves":0,"completeGames":0,"shutouts":0,"hits":60,"runs":25,"earnedRuns":22,"homeRuns":8,"baseOnBalls":20,"intentionalWalks":0,"strikeOuts":70,"hitByPitch":3,"wildPitches":2,"balks":0,"battersFaced":250,"era":"3.50","whip":"1.20","avg":".264","obp":".332","slg":".440","ops":".772","inningsPitched":"56.2"}},
            {"split":{"code":"vl","description":"vs Left"},"gameType":"S","stat":{"gamesPlayed":3,"gamesStarted":3,"wins":1,"losses":0,"saves":0,"saveOpportunities":0,"holds":0,"blownSaves":0,"completeGames":0,"shutouts":0,"hits":5,"runs":2,"earnedRuns":2,"homeRuns":1,"baseOnBalls":2,"intentionalWalks":0,"strikeOuts":8,"hitByPitch":0,"wildPitches":0,"balks":0,"battersFaced":25,"era":"3.00","whip":"1.05","avg":".217","obp":".280","slg":".391","ops":".671","inningsPitched":"6.0"}},
            {"split":{"code":"vl","description":"vs Left"},"gameType":"R","stat":{"gamesPlayed":20,"gamesStarted":20,"wins":5,"losses":3,"saves":0,"saveOpportunities":0,"holds":0,"blownSaves":0,"completeGames":0,"shutouts":0,"hits":60,"runs":25,"earnedRuns":22,"homeRuns":8,"baseOnBalls":20,"intentionalWalks":0,"strikeOuts":70,"hitByPitch":3,"wildPitches":2,"balks":0,"battersFaced":250,"era":"3.50","whip":"1.20","avg":".264","obp":".332","slg":".440","ops":".772","inningsPitched":"56.2"}},
            {"split":{"code":"vr","description":"vs Right"},"gameType":"R","stat":{"gamesPlayed":20,"gamesStarted":20,"wins":4,"losses":2,"saves":0,"saveOpportunities":0,"holds":0,"blownSaves":0,"completeGames":0,"shutouts":0,"hits":50,"runs":20,"earnedRuns":18,"homeRuns":6,"baseOnBalls":15,"intentionalWalks":0,"strikeOuts":85,"hitByPitch":2,"wildPitches":1,"balks":0,"battersFaced":270,"era":"2.80","whip":"1.00","avg":".197","obp":".249","slg":".350","ops":".599","inningsPitched":"57.2"}},
            {"split":{"code":"vr","description":"vs Right"},"gameType":"R","stat":{"gamesPlayed":20,"gamesStarted":20,"wins":4,"losses":2,"saves":0,"saveOpportunities":0,"holds":0,"blownSaves":0,"completeGames":0,"shutouts":0,"hits":50,"runs":20,"earnedRuns":18,"homeRuns":6,"baseOnBalls":15,"intentionalWalks":0,"strikeOuts":85,"hitByPitch":2,"wildPitches":1,"balks":0,"battersFaced":270,"era":"2.80","whip":"1.00","avg":".197","obp":".249","slg":".350","ops":".599","inningsPitched":"57.2"}}
        ]}]}
        """.data(using: .utf8)!

        let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: json)
        let ref = PlayerReference(id: 1, fullName: "Test")
        let platoon = MLBResponseConverters.pitcherPlatoonStats(from: response, playerRef: ref)

        // vL should aggregate R + S
        let vl = try #require(platoon.vsLeft)
        #expect(vl.battersFaced == 275)  // 250 + 25
        #expect(vl.strikeOuts == 78)  // 70 + 8
        #expect(vl.hits == 65)  // 60 + 5

        // OPS is BF-weighted: (0.772 * 250 + 0.671 * 25) / 275
        let expectedOPS = (0.772 * 250.0 + 0.671 * 25.0) / 275.0
        #expect(abs((vl.ops ?? 0) - expectedOPS) < 0.001)

        // vR should have only R (single entry)
        let vr = try #require(platoon.vsRight)
        #expect(vr.battersFaced == 270)
        #expect(vr.ops == 0.599)
    }

    // MARK: - Career platoon splits (batter)

    @Test("Decode career batter platoon splits from fixture")
    func decodeCareerBatterPlatoonSplits() throws {
        let data = try Fixtures.load("player_career_stats_platoon_660271.json")
        let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: data)
        let ref = PlayerReference(id: 660271, fullName: "Shohei Ohtani")
        let p = MLBResponseConverters.playerPlatoonStats(from: response, playerRef: ref)
        let career = PlayerCareerPlatoonStats(vsLeft: p.vsLeft, vsRight: p.vsRight)

        let vsLeft = try #require(career.vsLeft)
        #expect(vsLeft.homeRuns == 70)
        #expect(vsLeft.gamesPlayed == 420)
        #expect(vsLeft.ops == 0.937)

        let vsRight = try #require(career.vsRight)
        #expect(vsRight.homeRuns == 247)
        #expect(vsRight.gamesPlayed == 710)
        #expect(vsRight.ops == 0.984)
    }

    @Test("Career batter platoon fixture splits have no season field")
    func careerBatterPlatoonNoSeason() throws {
        let data = try Fixtures.load("player_career_stats_platoon_660271.json")
        let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: data)
        let allSplits = response.stats.flatMap(\.splits)
        #expect(allSplits.allSatisfy { $0.season == nil })
    }

    @Test("playerCareerPlatoonStats() query builder sends careerStatSplits param")
    func careerBatterPlatoonQueryBuilder() async throws {
        let mock = MockAPIClient()
        let data = try Fixtures.load("player_career_stats_platoon_660271.json")
        mock.stub(path: "people/660271/stats", data: data)

        let builder = QueryBuilder<PlayerCareerPlatoonStats>.playerCareerPlatoonStats(id: 660271, client: mock)
        _ = try await builder.fetch()

        let items = mock.lastEndpoint?.queryItems ?? []
        #expect(items.contains { $0.name == "stats" && $0.value == "careerStatSplits" })
        #expect(items.contains { $0.name == "sitCodes" && $0.value == "vl,vr" })
        #expect(items.contains { $0.name == "group" && $0.value == "hitting" })
        #expect(!items.contains { $0.name == "season" })
    }

    @Test("Empty career batter platoon splits returns both nil")
    func emptyCareerBatterPlatoonSplits() throws {
        let json = """
        { "stats": [{ "type": {"displayName":"careerStatSplits"}, "group": {"displayName":"hitting"}, "splits": [] }] }
        """.data(using: .utf8)!
        let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: json)
        let ref = PlayerReference(id: 1, fullName: "")
        let p = MLBResponseConverters.playerPlatoonStats(from: response, playerRef: ref)
        let career = PlayerCareerPlatoonStats(vsLeft: p.vsLeft, vsRight: p.vsRight)

        #expect(career.vsLeft == nil)
        #expect(career.vsRight == nil)
    }

    // MARK: - Career platoon splits (pitcher)

    @Test("Decode career pitcher platoon splits from fixture")
    func decodeCareerPitcherPlatoonSplits() throws {
        let data = try Fixtures.load("pitcher_career_stats_platoon_660271.json")
        let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: data)
        let ref = PlayerReference(id: 660271, fullName: "Shohei Ohtani")
        let p = MLBResponseConverters.pitcherPlatoonStats(from: response, playerRef: ref)
        let career = PitcherCareerPlatoonStats(vsLeft: p.vsLeft, vsRight: p.vsRight)

        let vsLeft = try #require(career.vsLeft)
        #expect(vsLeft.strikeOuts == 295)
        #expect(vsLeft.battersFaced == 936)
        #expect(vsLeft.ops == 0.634)
        // New fields decoded from API response
        #expect(vsLeft.atBats == 853)
        #expect(vsLeft.doubles == 16)
        #expect(vsLeft.triples == 1)
        #expect(vsLeft.sacFlies == 4)

        let vsRight = try #require(career.vsRight)
        #expect(vsRight.strikeOuts == 325)
        #expect(vsRight.battersFaced == 961)
        #expect(vsRight.ops == 0.543)
        #expect(vsRight.atBats == 861)
        #expect(vsRight.doubles == 14)
        #expect(vsRight.triples == 0)
        #expect(vsRight.sacFlies == 3)
    }

    @Test("pitcherCareerPlatoonStats() query builder sends careerStatSplits param")
    func careerPitcherPlatoonQueryBuilder() async throws {
        let mock = MockAPIClient()
        let data = try Fixtures.load("pitcher_career_stats_platoon_660271.json")
        mock.stub(path: "people/660271/stats", data: data)

        let builder = QueryBuilder<PitcherCareerPlatoonStats>.pitcherCareerPlatoonStats(id: 660271, client: mock)
        _ = try await builder.fetch()

        let items = mock.lastEndpoint?.queryItems ?? []
        #expect(items.contains { $0.name == "stats" && $0.value == "careerStatSplits" })
        #expect(items.contains { $0.name == "sitCodes" && $0.value == "vl,vr" })
        #expect(items.contains { $0.name == "group" && $0.value == "pitching" })
        #expect(!items.contains { $0.name == "season" })
    }

    @Test("Empty career pitcher platoon splits returns both nil")
    func emptyCareerPitcherPlatoonSplits() throws {
        let json = """
        { "stats": [{ "type": {"displayName":"careerStatSplits"}, "group": {"displayName":"pitching"}, "splits": [] }] }
        """.data(using: .utf8)!
        let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: json)
        let ref = PlayerReference(id: 1, fullName: "")
        let p = MLBResponseConverters.pitcherPlatoonStats(from: response, playerRef: ref)
        let career = PitcherCareerPlatoonStats(vsLeft: p.vsLeft, vsRight: p.vsRight)

        #expect(career.vsLeft == nil)
        #expect(career.vsRight == nil)
    }

    // MARK: - Career stats

    @Test("Decode career batting stats from fixture")
    func decodeCareerStats() throws {
        let data = try Fixtures.load("player_career_stats_batting_660271.json")
        let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: data)
        let ref = PlayerReference(id: 660271, fullName: "Shohei Ohtani")
        let stats = MLBResponseConverters.playerSeasonStats(from: response, playerRef: ref)

        #expect(stats.count == 1)
        let entry = try #require(stats.first)
        #expect(entry.player.id == 660271)
        #expect(entry.group == .batting)
        // Career splits have no season value in the API response
        #expect(entry.season == "")

        let batting = try #require(entry.batting)
        #expect(batting.gamesPlayed == 1024)
        #expect(batting.homeRuns == 305)
        #expect(batting.stolenBases == 179)
        #expect(abs((batting.avg ?? 0) - 0.299) < 0.001)
        #expect(abs((batting.ops ?? 0) - 0.934) < 0.001)
    }

    @Test("Career stats endpoint builds correct URL parameter")
    func careerStatsEndpointParam() async throws {
        let mock = MockAPIClient()
        let data = try Fixtures.load("player_career_stats_batting_660271.json")
        mock.stub(path: "people/660271/stats", data: data)
        _ = try await QueryBuilder<[PlayerSeasonStats]>.playerCareerStats(id: 660271, client: mock).fetch()
        let endpoint = try #require(mock.lastEndpoint)
        #expect(endpoint.path == "people/660271/stats")
        #expect(endpoint.queryItems.contains { $0.name == "stats" && $0.value == "career" })
    }

    @Test("SwiftBaseball.playerCareerStats supports group and gameType modifiers")
    func careerStatsModifiers() async throws {
        let mock = MockAPIClient()
        let data = try Fixtures.load("player_career_stats_batting_660271.json")
        mock.stub(path: "people/660271/stats", data: data)
        _ = try await QueryBuilder<[PlayerSeasonStats]>.playerCareerStats(id: 660271, client: mock)
            .group(.batting)
            .gameType(.regularSeason)
            .fetch()
        let items = mock.lastEndpoint?.queryItems ?? []
        #expect(items.contains { $0.name == "stats" && $0.value == "career" })
        #expect(items.contains { $0.name == "group" && $0.value == "hitting" })
        #expect(items.contains { $0.name == "gameType" && $0.value == "R" })
    }

    // MARK: - Year-by-year stats

    @Test("Decode year-by-year batting stats from fixture")
    func decodeYearByYearStats() throws {
        let data = try Fixtures.load("player_year_by_year_batting_660271.json")
        let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: data)
        let ref = PlayerReference(id: 660271, fullName: "Shohei Ohtani")
        let stats = MLBResponseConverters.playerSeasonStats(from: response, playerRef: ref)

        #expect(stats.count == 3)
        #expect(stats[0].season == "2018")
        #expect(stats[1].season == "2021")
        #expect(stats[2].season == "2024")
        #expect(stats.allSatisfy { $0.group == .batting })
    }

    @Test("Year-by-year entries are ordered and have correct team references")
    func yearByYearTeamRefs() throws {
        let data = try Fixtures.load("player_year_by_year_batting_660271.json")
        let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: data)
        let ref = PlayerReference(id: 660271, fullName: "Shohei Ohtani")
        let stats = MLBResponseConverters.playerSeasonStats(from: response, playerRef: ref)

        #expect(stats[0].team?.id == 108)   // Angels
        #expect(stats[1].team?.id == 108)   // Angels
        #expect(stats[2].team?.id == 119)   // Dodgers
    }

    @Test("Year-by-year batting values match fixture for each season")
    func yearByYearBattingValues() throws {
        let data = try Fixtures.load("player_year_by_year_batting_660271.json")
        let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: data)
        let ref = PlayerReference(id: 660271, fullName: "Shohei Ohtani")
        let stats = MLBResponseConverters.playerSeasonStats(from: response, playerRef: ref)

        let s2018 = try #require(stats[0].batting)
        #expect(s2018.homeRuns == 22)
        #expect(abs((s2018.avg ?? 0) - 0.285) < 0.001)

        let s2021 = try #require(stats[1].batting)
        #expect(s2021.homeRuns == 46)
        #expect(abs((s2021.ops ?? 0) - 0.965) < 0.001)

        let s2024 = try #require(stats[2].batting)
        #expect(s2024.homeRuns == 54)
        #expect(abs((s2024.avg ?? 0) - 0.310) < 0.001)
    }

    @Test("Year-by-year endpoint builds correct URL parameter")
    func yearByYearEndpointParam() async throws {
        let mock = MockAPIClient()
        let data = try Fixtures.load("player_year_by_year_batting_660271.json")
        mock.stub(path: "people/660271/stats", data: data)
        _ = try await QueryBuilder<[PlayerSeasonStats]>.playerYearByYear(id: 660271, client: mock).fetch()
        let endpoint = try #require(mock.lastEndpoint)
        #expect(endpoint.path == "people/660271/stats")
        #expect(endpoint.queryItems.contains { $0.name == "stats" && $0.value == "yearByYear" })
    }

    @Test("SwiftBaseball.playerYearByYear supports group modifier")
    func yearByYearModifiers() async throws {
        let mock = MockAPIClient()
        let data = try Fixtures.load("player_year_by_year_batting_660271.json")
        mock.stub(path: "people/660271/stats", data: data)
        _ = try await QueryBuilder<[PlayerSeasonStats]>.playerYearByYear(id: 660271, client: mock)
            .group(.pitching)
            .fetch()
        let items = mock.lastEndpoint?.queryItems ?? []
        #expect(items.contains { $0.name == "stats" && $0.value == "yearByYear" })
        #expect(items.contains { $0.name == "group" && $0.value == "pitching" })
    }

    @Test("Batter platoon with no gameType field still works (backwards compat)")
    func batterPlatoonNoGameType() throws {
        // Existing fixture has no gameType on splits — should still parse fine
        let data = try Fixtures.load("player_stats_platoon_660271.json")
        let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: data)
        let ref = PlayerReference(id: 660271, fullName: "Shohei Ohtani")
        let platoon = MLBResponseConverters.playerPlatoonStats(from: response, playerRef: ref)

        // Single vl and vr entries with nil gameType — no aggregation needed
        let vsLeft = try #require(platoon.vsLeft)
        #expect(vsLeft.gamesPlayed == 114)
        #expect(vsLeft.ops == 0.867)

        let vsRight = try #require(platoon.vsRight)
        #expect(vsRight.gamesPlayed == 145)
        #expect(vsRight.ops == 1.128)
    }

    // MARK: - Minor league stats

    @Test("Minor league batting stats decode sport and league fields")
    func minorLeagueBattingStatsSportAndLeague() throws {
        let data = try Fixtures.load("player_stats_batting_mib_656185.json")
        let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: data)
        let ref = PlayerReference(id: 656185, fullName: "Greg Allen")
        let stats = MLBResponseConverters.playerSeasonStats(from: response, playerRef: ref)

        #expect(stats.count == 1)
        let entry = try #require(stats.first)
        #expect(entry.sport == .tripleA)
        #expect(entry.league?.id == 117)
        #expect(entry.league?.name == "International League")
        #expect(entry.team?.id == 531)
        #expect(entry.team?.name == "Scranton/Wilkes-Barre RailRiders")
        #expect(entry.season == "2024")
    }

    @Test("Minor league batting stat values decode correctly")
    func minorLeagueBattingStatValues() throws {
        let data = try Fixtures.load("player_stats_batting_mib_656185.json")
        let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: data)
        let ref = PlayerReference(id: 656185, fullName: "Greg Allen")
        let stats = MLBResponseConverters.playerSeasonStats(from: response, playerRef: ref)

        let batting = try #require(stats.first?.batting)
        #expect(batting.gamesPlayed == 58)
        #expect(batting.homeRuns == 3)
        #expect(batting.stolenBases == 13)
        #expect(batting.avg == 0.225)
        #expect(batting.ops == 0.698)
    }

    @Test("Minor league pitching stats decode sport and league fields")
    func minorLeaguePitchingStatsSportAndLeague() throws {
        let data = try Fixtures.load("player_stats_pitching_mib_687607.json")
        let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: data)
        let ref = PlayerReference(id: 687607, fullName: "Edgar Barclay")
        let stats = MLBResponseConverters.playerSeasonStats(from: response, playerRef: ref)

        #expect(stats.count == 1)
        let entry = try #require(stats.first)
        #expect(entry.sport == .tripleA)
        #expect(entry.league?.id == 117)
        #expect(entry.group == .pitching)
    }

    @Test("Minor league pitching stat values decode correctly")
    func minorLeaguePitchingStatValues() throws {
        let data = try Fixtures.load("player_stats_pitching_mib_687607.json")
        let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: data)
        let ref = PlayerReference(id: 687607, fullName: "Edgar Barclay")
        let stats = MLBResponseConverters.playerSeasonStats(from: response, playerRef: ref)

        let pitching = try #require(stats.first?.pitching)
        #expect(pitching.gamesPlayed == 29)
        #expect(pitching.gamesStarted == 29)
        #expect(pitching.wins == 7)
        #expect(pitching.losses == 9)
        #expect(pitching.era == 5.98)
        #expect(pitching.whip == 1.54)
    }

    @Test("MLB season stats have nil sport and league (API omits these for MLB)")
    func mlbStatsHaveNilSportAndLeague() throws {
        let data = try Fixtures.load("player_stats_batting_660271.json")
        let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: data)
        let ref = PlayerReference(id: 660271, fullName: "Shohei Ohtani")
        let stats = MLBResponseConverters.playerSeasonStats(from: response, playerRef: ref)

        let entry = try #require(stats.first)
        #expect(entry.sport == nil)
        #expect(entry.league == nil)
    }

    @Test("playerStats sport modifier appends sportId query param")
    func playerStatsSportModifier() async throws {
        let data = try Fixtures.load("player_stats_batting_mib_656185.json")
        let mock = MockAPIClient()
        mock.stub(path: "people/656185/stats", data: data)

        _ = try await QueryBuilder<[PlayerSeasonStats]>.playerStats(id: 656185, client: mock)
            .season(2024)
            .group(.batting)
            .sport(.tripleA)
            .fetch()

        let items = mock.lastEndpoint?.queryItems ?? []
        #expect(items.contains { $0.name == "sportId" && $0.value == "11" })
        #expect(items.contains { $0.name == "season" && $0.value == "2024" })
        #expect(items.contains { $0.name == "group" && $0.value == "hitting" })
    }

    @Test("playerYearByYear sport modifier appends sportId")
    func playerYearByYearSportModifier() async throws {
        let data = try Fixtures.load("player_stats_batting_mib_656185.json")
        let mock = MockAPIClient()
        mock.stub(path: "people/656185/stats", data: data)

        _ = try await QueryBuilder<[PlayerSeasonStats]>.playerYearByYear(id: 656185, client: mock)
            .group(.batting)
            .sport(.tripleA)
            .fetch()

        let items = mock.lastEndpoint?.queryItems ?? []
        #expect(items.contains { $0.name == "stats" && $0.value == "yearByYear" })
        #expect(items.contains { $0.name == "sportId" && $0.value == "11" })
    }

    @Test("playerCareerStats sport modifier appends sportId")
    func playerCareerStatsSportModifier() async throws {
        let data = try Fixtures.load("player_stats_batting_mib_656185.json")
        let mock = MockAPIClient()
        mock.stub(path: "people/656185/stats", data: data)

        _ = try await QueryBuilder<[PlayerSeasonStats]>.playerCareerStats(id: 656185, client: mock)
            .group(.batting)
            .sport(.doubleA)
            .fetch()

        let items = mock.lastEndpoint?.queryItems ?? []
        #expect(items.contains { $0.name == "sportId" && $0.value == "12" })
    }

    @Test("All Sport enum cases map to expected sportId values")
    func sportEnumRawValues() {
        #expect(Sport.mlb.rawValue == 1)
        #expect(Sport.tripleA.rawValue == 11)
        #expect(Sport.doubleA.rawValue == 12)
        #expect(Sport.highA.rawValue == 13)
        #expect(Sport.singleA.rawValue == 14)
        #expect(Sport.rookie.rawValue == 16)
        #expect(Sport.complexLeague.rawValue == 17)
    }

    // MARK: - Team bulk stats

    @Test("Decode team sabermetrics from fixture returns all players")
    func decodeTeamSabermetrics() throws {
        let data = try Fixtures.load("team_sabermetrics_147_2025.json")
        let response = try JSONDecoder.mlb.decode(MLBSabermetricResponse.self, from: data)
        let stub = PlayerReference(id: 0, fullName: "")
        let stats = MLBResponseConverters.playerSabermetrics(from: response, playerRef: stub)

        #expect(stats.count == 3)
        let judge = try #require(stats.first { $0.player.id == 592450 })
        #expect(judge.player.fullName == "Aaron Judge")
        #expect(judge.season == "2025")
        let saber = try #require(judge.sabermetrics)
        #expect(abs((saber.woba ?? 0) - 0.430549) < 0.000001)
        #expect(abs((saber.wRcPlus ?? 0) - 179.678) < 0.001)
    }

    @Test("teamSabermetrics QueryBuilder sends correct parameters")
    func teamSabermetricsQueryBuilderParams() async throws {
        let mock = MockAPIClient()
        let data = try Fixtures.load("team_sabermetrics_147_2025.json")
        mock.stub(path: "stats", data: data)

        _ = try await QueryBuilder<[PlayerSeasonStats]>.teamSabermetrics(teamId: 147, client: mock)
            .season(2025)
            .fetch()

        let items = mock.lastEndpoint?.queryItems ?? []
        #expect(items.contains { $0.name == "stats" && $0.value == "sabermetrics" })
        #expect(items.contains { $0.name == "group" && $0.value == "hitting" })
        #expect(items.contains { $0.name == "teamId" && $0.value == "147" })
        #expect(items.contains { $0.name == "playerPool" && $0.value == "All" })
        #expect(items.contains { $0.name == "season" && $0.value == "2025" })
        #expect(!items.contains { $0.name == "stats" && $0.value == "season" })
    }

    @Test("teamSabermetrics with empty splits returns empty array")
    func emptyTeamSabermetrics() throws {
        let json = #"{"stats":[{"type":{"displayName":"sabermetrics"},"group":{"displayName":"hitting"},"splits":[]}]}"#
        let data = Data(json.utf8)
        let response = try JSONDecoder.mlb.decode(MLBSabermetricResponse.self, from: data)
        let stub = PlayerReference(id: 0, fullName: "")
        let stats = MLBResponseConverters.playerSabermetrics(from: response, playerRef: stub)
        #expect(stats.isEmpty)
    }

    @Test("Decode team batting stats from fixture returns all players")
    func decodeTeamBattingStats() throws {
        let data = try Fixtures.load("team_stats_batting_147_2025.json")
        let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: data)
        let stub = PlayerReference(id: 0, fullName: "")
        let stats = MLBResponseConverters.playerSeasonStats(from: response, playerRef: stub)

        #expect(stats.count == 3)
        let judge = try #require(stats.first { $0.player.id == 592450 })
        #expect(judge.player.fullName == "Aaron Judge")
        #expect(judge.season == "2025")
        let batting = try #require(judge.batting)
        #expect(batting.homeRuns == 18)
        #expect(batting.gamesPlayed == 40)
    }

    @Test("teamStats QueryBuilder sends correct parameters")
    func teamStatsQueryBuilderParams() async throws {
        let mock = MockAPIClient()
        let data = try Fixtures.load("team_stats_batting_147_2025.json")
        mock.stub(path: "stats", data: data)

        _ = try await QueryBuilder<[PlayerSeasonStats]>.teamStats(teamId: 147, group: .batting, client: mock)
            .season(2025)
            .fetch()

        let items = mock.lastEndpoint?.queryItems ?? []
        #expect(items.contains { $0.name == "stats" && $0.value == "season" })
        #expect(items.contains { $0.name == "group" && $0.value == "hitting" })
        #expect(items.contains { $0.name == "teamId" && $0.value == "147" })
        #expect(items.contains { $0.name == "playerPool" && $0.value == "All" })
        #expect(items.contains { $0.name == "season" && $0.value == "2025" })
    }

    @Test("teamStats group parameter uses StatGroup apiValue")
    func teamStatsGroupParam() async throws {
        let mock = MockAPIClient()
        let data = try Fixtures.load("team_stats_batting_147_2025.json")
        mock.stub(path: "stats", data: data)

        _ = try await QueryBuilder<[PlayerSeasonStats]>.teamStats(teamId: 147, group: .pitching, client: mock).fetch()

        let items = mock.lastEndpoint?.queryItems ?? []
        #expect(items.contains { $0.name == "group" && $0.value == "pitching" })
        #expect(!items.contains { $0.name == "group" && $0.value == "hitting" })
    }

    // MARK: - wOBA computed property

    @Test("BattingStats.woba computes correctly from known values")
    func wobaNormalCase() throws {
        // Shohei Ohtani 2024: AB=636 H=197 2B=38 3B=7 HR=54 BB=81 IBB=20 HBP=7 SF=5
        // 1B=98  uBB=61
        // num = 0.696*61 + 0.726*7 + 0.883*98 + 1.244*38 + 1.569*7 + 2.007*54
        //     = 42.456 + 5.082 + 86.534 + 47.272 + 10.983 + 108.378 = 300.705
        // den = 636 + 61 + 5 + 7 = 709
        // wOBA ≈ 0.424
        let stats = BattingStats(
            gamesPlayed: 159, plateAppearances: 731, atBats: 636, runs: 134,
            hits: 197, doubles: 38, triples: 7, homeRuns: 54, rbi: 130,
            stolenBases: 59, caughtStealing: 4, baseOnBalls: 81,
            intentionalWalks: 20, strikeOuts: 162, hitByPitch: 7,
            sacFlies: 5, sacBunts: 2, groundIntoDoublePlay: 10,
            totalBases: 411, leftOnBase: 80,
            avg: 0.310, obp: 0.390, slg: 0.646, ops: 1.036, babip: 0.334
        )
        let expected = 300.705 / 709.0
        let result = try #require(stats.woba)
        #expect(abs(result - expected) < 0.001)
    }

    @Test("BattingStats.woba returns nil when any required field is nil")
    func wobaNilField() {
        #expect(BattingStats.empty.woba == nil)
    }

    // MARK: - wobaAgainst

    @Test("PitchingStats.wobaAgainst computes correctly from career platoon fixture values")
    func wobaAgainstNormalCase() throws {
        // vsLeft from pitcher_career_stats_platoon_660271.json:
        // AB=853 H=169 2B=16 3B=1 HR=19 BB=69 IBB=2 HBP=7 SF=4
        // 1B=133 uBB=67
        // num = 0.696*67 + 0.726*7 + 0.883*133 + 1.244*16 + 1.569*1 + 2.007*19 = 228.759
        // den = 853 + 67 + 4 + 7 = 931
        let stats = PitchingStats(
            gamesPlayed: nil, gamesStarted: nil, wins: nil, losses: nil,
            saves: nil, saveOpportunities: nil, holds: nil, blownSaves: nil,
            completeGames: nil, shutouts: nil, hits: 169, doubles: 16, triples: 1,
            runs: nil, earnedRuns: nil, homeRuns: 19, atBats: 853, baseOnBalls: 69,
            intentionalWalks: 2, strikeOuts: 295, hitByPitch: 7, sacFlies: 4,
            wildPitches: nil, balks: nil, battersFaced: 936,
            numberOfPitches: nil,
            era: nil, whip: nil, avg: nil, obp: nil, slg: nil, ops: nil,
            inningsPitched: nil
        )
        let expected = 228.759 / 931.0
        let result = try #require(stats.wobaAgainst)
        #expect(abs(result - expected) < 0.001)
    }

    @Test("PitchingStats.wobaAgainst returns nil when required fields are missing")
    func wobaAgainstNilField() {
        #expect(PitchingStats.empty.wobaAgainst == nil)
    }

    @Test("PitchingStats.wobaAgainst returns nil when denominator is zero")
    func wobaAgainstZeroDenominator() {
        let stats = PitchingStats(
            gamesPlayed: nil, gamesStarted: nil, wins: nil, losses: nil,
            saves: nil, saveOpportunities: nil, holds: nil, blownSaves: nil,
            completeGames: nil, shutouts: nil, hits: 0, doubles: 0, triples: 0,
            runs: nil, earnedRuns: nil, homeRuns: 0, atBats: 0, baseOnBalls: 0,
            intentionalWalks: 0, strikeOuts: 0, hitByPitch: 0, sacFlies: 0,
            wildPitches: nil, balks: nil, battersFaced: nil,
            numberOfPitches: nil,
            era: nil, whip: nil, avg: nil, obp: nil, slg: nil, ops: nil,
            inningsPitched: nil
        )
        #expect(stats.wobaAgainst == nil)
    }

    @Test("PitchingStats.wobaAgainst decoded from career platoon fixture end-to-end")
    func wobaAgainstFromFixture() throws {
        let data = try Fixtures.load("pitcher_career_stats_platoon_660271.json")
        let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: data)
        let ref = PlayerReference(id: 660271, fullName: "Shohei Ohtani")
        let p = MLBResponseConverters.pitcherPlatoonStats(from: response, playerRef: ref)
        let vsLeft = try #require(p.vsLeft)
        let result = try #require(vsLeft.wobaAgainst)
        let expected = 228.759 / 931.0
        #expect(abs(result - expected) < 0.001)
    }

    @Test("BattingStats.woba returns nil when denominator is zero")
    func wobaZeroDenominator() {
        // AB=0, BB=0, IBB=0, SF=0, HBP=0 → den = 0
        let stats = BattingStats(
            gamesPlayed: 0, plateAppearances: 0, atBats: 0, runs: 0,
            hits: 0, doubles: 0, triples: 0, homeRuns: 0, rbi: 0,
            stolenBases: 0, caughtStealing: 0, baseOnBalls: 0,
            intentionalWalks: 0, strikeOuts: 0, hitByPitch: 0,
            sacFlies: 0, sacBunts: 0, groundIntoDoublePlay: 0,
            totalBases: 0, leftOnBase: 0,
            avg: nil, obp: nil, slg: nil, ops: nil, babip: nil
        )
        #expect(stats.woba == nil)
    }
}
