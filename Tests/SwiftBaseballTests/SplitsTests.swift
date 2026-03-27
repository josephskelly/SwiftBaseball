import Testing
import Foundation
@testable import SwiftBaseball

@Suite("Splits Tests")
struct SplitsTests {

    // MARK: - Batter home/away

    @Test("Decode batter home splits from fixture")
    func batterHomeSplits() throws {
        let data = try Fixtures.load("player_home_away_splits_660271.json")
        let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: data)
        let ref = PlayerReference(id: 660271, fullName: "Shohei Ohtani")
        let splits = MLBResponseConverters.playerHomeAwaySplits(from: response, playerRef: ref)

        let home = try #require(splits.home)
        #expect(home.gamesPlayed == 79)
        #expect(home.homeRuns == 29)
        #expect(abs((home.avg ?? 0) - 0.320) < 0.001)
        #expect(abs((home.ops ?? 0) - 1.061) < 0.001)
    }

    @Test("Decode batter away splits from fixture")
    func batterAwaySplits() throws {
        let data = try Fixtures.load("player_home_away_splits_660271.json")
        let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: data)
        let ref = PlayerReference(id: 660271, fullName: "Shohei Ohtani")
        let splits = MLBResponseConverters.playerHomeAwaySplits(from: response, playerRef: ref)

        let away = try #require(splits.away)
        #expect(away.gamesPlayed == 80)
        #expect(away.homeRuns == 25)
        #expect(abs((away.avg ?? 0) - 0.300) < 0.001)
        #expect(abs((away.ops ?? 0) - 1.010) < 0.001)
    }

    @Test("Batter home/away: missing split side returns nil")
    func batterHomeAwaySplitMissingSide() throws {
        // Response with only a home split — away should be nil
        let json = """
        {"stats":[{"type":{"displayName":"statSplits"},"group":{"displayName":"hitting"},
        "splits":[{"season":"2024","stat":{"gamesPlayed":79,"homeRuns":29,"avg":".320",
        "atBats":316,"hits":101,"ops":"1.061","obp":".400","slg":".661"},
        "player":{"id":660271,"fullName":"Ohtani"},"team":{"id":119,"name":"LAD"},
        "split":{"code":"h","description":"Home"}}]}]}
        """.data(using: .utf8)!
        let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: json)
        let ref = PlayerReference(id: 660271, fullName: "")
        let splits = MLBResponseConverters.playerHomeAwaySplits(from: response, playerRef: ref)

        #expect(splits.home != nil)
        #expect(splits.away == nil)
    }

    @Test("playerHomeAwaySplits endpoint uses sitCodes=h,a")
    func homeAwayEndpointParams() async throws {
        let mock = MockAPIClient()
        let data = try Fixtures.load("player_home_away_splits_660271.json")
        mock.stub(path: "people/660271/stats", data: data)
        _ = try await QueryBuilder<PlayerHomeAwaySplits>
            .playerHomeAwaySplits(id: 660271, client: mock)
            .season(2024)
            .fetch()
        let items = mock.lastEndpoint?.queryItems ?? []
        #expect(items.contains { $0.name == "stats" && $0.value == "statSplits" })
        #expect(items.contains { $0.name == "sitCodes" && $0.value == "h,a" })
        #expect(items.contains { $0.name == "group" && $0.value == "hitting" })
        #expect(items.contains { $0.name == "season" && $0.value == "2024" })
    }

    @Test("SwiftBaseball.playerHomeAwaySplits is accessible")
    func namespacedHomeAway() {
        _ = SwiftBaseball.playerHomeAwaySplits(id: 660271)
    }

    // MARK: - Batter day/night

    @Test("Decode batter day splits from fixture")
    func batterDaySplits() throws {
        let data = try Fixtures.load("player_day_night_splits_660271.json")
        let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: data)
        let ref = PlayerReference(id: 660271, fullName: "Shohei Ohtani")
        let splits = MLBResponseConverters.playerDayNightSplits(from: response, playerRef: ref)

        let day = try #require(splits.day)
        #expect(day.gamesPlayed == 42)
        #expect(day.homeRuns == 14)
        #expect(abs((day.avg ?? 0) - 0.323) < 0.001)
    }

    @Test("Decode batter night splits from fixture")
    func batterNightSplits() throws {
        let data = try Fixtures.load("player_day_night_splits_660271.json")
        let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: data)
        let ref = PlayerReference(id: 660271, fullName: "Shohei Ohtani")
        let splits = MLBResponseConverters.playerDayNightSplits(from: response, playerRef: ref)

        let night = try #require(splits.night)
        #expect(night.gamesPlayed == 117)
        #expect(night.homeRuns == 40)
        #expect(abs((night.ops ?? 0) - 1.026) < 0.001)
    }

    @Test("playerDayNightSplits endpoint uses sitCodes=d,n")
    func dayNightEndpointParams() async throws {
        let mock = MockAPIClient()
        let data = try Fixtures.load("player_day_night_splits_660271.json")
        mock.stub(path: "people/660271/stats", data: data)
        _ = try await QueryBuilder<PlayerDayNightSplits>
            .playerDayNightSplits(id: 660271, client: mock)
            .season(2024)
            .fetch()
        let items = mock.lastEndpoint?.queryItems ?? []
        #expect(items.contains { $0.name == "sitCodes" && $0.value == "d,n" })
        #expect(items.contains { $0.name == "group" && $0.value == "hitting" })
    }

    @Test("SwiftBaseball.playerDayNightSplits is accessible")
    func namespacedDayNight() {
        _ = SwiftBaseball.playerDayNightSplits(id: 660271)
    }

    // MARK: - Pitcher home/away

    @Test("Decode pitcher home splits from fixture")
    func pitcherHomeSplits() throws {
        let data = try Fixtures.load("pitcher_home_away_splits_543037.json")
        let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: data)
        let ref = PlayerReference(id: 543037, fullName: "Luis Castillo")
        let splits = MLBResponseConverters.pitcherHomeAwaySplits(from: response, playerRef: ref)

        let home = try #require(splits.home)
        #expect(home.gamesStarted == 17)
        #expect(home.strikeOuts == 112)
        #expect(abs((home.era ?? 0) - 2.75) < 0.01)
        #expect(abs((home.whip ?? 0) - 0.97) < 0.01)
    }

    @Test("Decode pitcher away splits from fixture")
    func pitcherAwaySplits() throws {
        let data = try Fixtures.load("pitcher_home_away_splits_543037.json")
        let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: data)
        let ref = PlayerReference(id: 543037, fullName: "Luis Castillo")
        let splits = MLBResponseConverters.pitcherHomeAwaySplits(from: response, playerRef: ref)

        let away = try #require(splits.away)
        #expect(away.gamesStarted == 16)
        #expect(away.strikeOuts == 94)
        #expect(abs((away.era ?? 0) - 4.10) < 0.01)
    }

    @Test("pitcherHomeAwaySplits endpoint uses pitching group and sitCodes=h,a")
    func pitcherHomeAwayEndpointParams() async throws {
        let mock = MockAPIClient()
        let data = try Fixtures.load("pitcher_home_away_splits_543037.json")
        mock.stub(path: "people/543037/stats", data: data)
        _ = try await QueryBuilder<PitcherHomeAwaySplits>
            .pitcherHomeAwaySplits(id: 543037, client: mock)
            .season(2024)
            .fetch()
        let items = mock.lastEndpoint?.queryItems ?? []
        #expect(items.contains { $0.name == "sitCodes" && $0.value == "h,a" })
        #expect(items.contains { $0.name == "group" && $0.value == "pitching" })
    }

    @Test("SwiftBaseball.pitcherHomeAwaySplits is accessible")
    func namespacedPitcherHomeAway() {
        _ = SwiftBaseball.pitcherHomeAwaySplits(id: 543037)
    }

    // MARK: - Pitcher day/night

    @Test("Decode pitcher day splits from fixture")
    func pitcherDaySplits() throws {
        let data = try Fixtures.load("pitcher_day_night_splits_543037.json")
        let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: data)
        let ref = PlayerReference(id: 543037, fullName: "Luis Castillo")
        let splits = MLBResponseConverters.pitcherDayNightSplits(from: response, playerRef: ref)

        let day = try #require(splits.day)
        #expect(day.gamesStarted == 8)
        #expect(day.strikeOuts == 55)
        #expect(abs((day.era ?? 0) - 3.27) < 0.01)
    }

    @Test("Decode pitcher night splits from fixture")
    func pitcherNightSplits() throws {
        let data = try Fixtures.load("pitcher_day_night_splits_543037.json")
        let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: data)
        let ref = PlayerReference(id: 543037, fullName: "Luis Castillo")
        let splits = MLBResponseConverters.pitcherDayNightSplits(from: response, playerRef: ref)

        let night = try #require(splits.night)
        #expect(night.gamesStarted == 25)
        #expect(night.strikeOuts == 151)
        #expect(abs((night.era ?? 0) - 3.72) < 0.01)
    }

    @Test("pitcherDayNightSplits endpoint uses pitching group and sitCodes=d,n")
    func pitcherDayNightEndpointParams() async throws {
        let mock = MockAPIClient()
        let data = try Fixtures.load("pitcher_day_night_splits_543037.json")
        mock.stub(path: "people/543037/stats", data: data)
        _ = try await QueryBuilder<PitcherDayNightSplits>
            .pitcherDayNightSplits(id: 543037, client: mock)
            .season(2024)
            .fetch()
        let items = mock.lastEndpoint?.queryItems ?? []
        #expect(items.contains { $0.name == "sitCodes" && $0.value == "d,n" })
        #expect(items.contains { $0.name == "group" && $0.value == "pitching" })
    }

    @Test("SwiftBaseball.pitcherDayNightSplits is accessible")
    func namespacedPitcherDayNight() {
        _ = SwiftBaseball.pitcherDayNightSplits(id: 543037)
    }

    // MARK: - Edge cases

    @Test("Empty home/away response returns both nil")
    func emptyHomeAwaySplits() throws {
        let json = """
        {"stats":[{"type":{"displayName":"statSplits"},"group":{"displayName":"hitting"},"splits":[]}]}
        """.data(using: .utf8)!
        let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: json)
        let ref = PlayerReference(id: 660271, fullName: "")
        let splits = MLBResponseConverters.playerHomeAwaySplits(from: response, playerRef: ref)
        #expect(splits.home == nil)
        #expect(splits.away == nil)
    }

    @Test("Empty day/night response returns both nil")
    func emptyDayNightSplits() throws {
        let json = """
        {"stats":[{"type":{"displayName":"statSplits"},"group":{"displayName":"hitting"},"splits":[]}]}
        """.data(using: .utf8)!
        let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: json)
        let ref = PlayerReference(id: 660271, fullName: "")
        let splits = MLBResponseConverters.playerDayNightSplits(from: response, playerRef: ref)
        #expect(splits.day == nil)
        #expect(splits.night == nil)
    }

    @Test("Empty pitcher home/away response returns both nil")
    func emptyPitcherHomeAway() throws {
        let json = """
        {"stats":[{"type":{"displayName":"statSplits"},"group":{"displayName":"pitching"},"splits":[]}]}
        """.data(using: .utf8)!
        let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: json)
        let ref = PlayerReference(id: 543037, fullName: "")
        let splits = MLBResponseConverters.pitcherHomeAwaySplits(from: response, playerRef: ref)
        #expect(splits.home == nil)
        #expect(splits.away == nil)
    }

    @Test("Empty pitcher day/night response returns both nil")
    func emptyPitcherDayNight() throws {
        let json = """
        {"stats":[{"type":{"displayName":"statSplits"},"group":{"displayName":"pitching"},"splits":[]}]}
        """.data(using: .utf8)!
        let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: json)
        let ref = PlayerReference(id: 543037, fullName: "")
        let splits = MLBResponseConverters.pitcherDayNightSplits(from: response, playerRef: ref)
        #expect(splits.day == nil)
        #expect(splits.night == nil)
    }
}
