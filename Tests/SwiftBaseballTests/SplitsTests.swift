import Foundation
@testable import SwiftBaseball
import Testing

@Suite("Splits Tests")
struct SplitsTests {
    // MARK: - Batter home/away

    @Test("Decode batter home splits from fixture")
    func batterHomeSplits() throws {
        let data = try Fixtures.load("player_home_away_splits_660271.json")
        let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: data)
        let ref = PlayerReference(id: 660_271, fullName: "Shohei Ohtani")
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
        let ref = PlayerReference(id: 660_271, fullName: "Shohei Ohtani")
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
        let json = Data("""
        {"stats":[{"type":{"displayName":"statSplits"},"group":{"displayName":"hitting"},
        "splits":[{"season":"2024","stat":{"gamesPlayed":79,"homeRuns":29,"avg":".320",
        "atBats":316,"hits":101,"ops":"1.061","obp":".400","slg":".661"},
        "player":{"id":660271,"fullName":"Ohtani"},"team":{"id":119,"name":"LAD"},
        "split":{"code":"h","description":"Home"}}]}]}
        """.utf8)
        let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: json)
        let ref = PlayerReference(id: 660_271, fullName: "")
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
            .playerHomeAwaySplits(id: 660_271, client: mock)
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
        _ = SwiftBaseball.playerHomeAwaySplits(id: 660_271)
    }

    // MARK: - Batter day/night

    @Test("Decode batter day splits from fixture")
    func batterDaySplits() throws {
        let data = try Fixtures.load("player_day_night_splits_660271.json")
        let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: data)
        let ref = PlayerReference(id: 660_271, fullName: "Shohei Ohtani")
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
        let ref = PlayerReference(id: 660_271, fullName: "Shohei Ohtani")
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
            .playerDayNightSplits(id: 660_271, client: mock)
            .season(2024)
            .fetch()
        let items = mock.lastEndpoint?.queryItems ?? []
        #expect(items.contains { $0.name == "sitCodes" && $0.value == "d,n" })
        #expect(items.contains { $0.name == "group" && $0.value == "hitting" })
    }

    @Test("SwiftBaseball.playerDayNightSplits is accessible")
    func namespacedDayNight() {
        _ = SwiftBaseball.playerDayNightSplits(id: 660_271)
    }

    // MARK: - Pitcher home/away

    @Test("Decode pitcher home splits from fixture")
    func pitcherHomeSplits() throws {
        let data = try Fixtures.load("pitcher_home_away_splits_543037.json")
        let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: data)
        let ref = PlayerReference(id: 543_037, fullName: "Luis Castillo")
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
        let ref = PlayerReference(id: 543_037, fullName: "Luis Castillo")
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
            .pitcherHomeAwaySplits(id: 543_037, client: mock)
            .season(2024)
            .fetch()
        let items = mock.lastEndpoint?.queryItems ?? []
        #expect(items.contains { $0.name == "sitCodes" && $0.value == "h,a" })
        #expect(items.contains { $0.name == "group" && $0.value == "pitching" })
    }

    @Test("SwiftBaseball.pitcherHomeAwaySplits is accessible")
    func namespacedPitcherHomeAway() {
        _ = SwiftBaseball.pitcherHomeAwaySplits(id: 543_037)
    }

    // MARK: - Pitcher day/night

    @Test("Decode pitcher day splits from fixture")
    func pitcherDaySplits() throws {
        let data = try Fixtures.load("pitcher_day_night_splits_543037.json")
        let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: data)
        let ref = PlayerReference(id: 543_037, fullName: "Luis Castillo")
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
        let ref = PlayerReference(id: 543_037, fullName: "Luis Castillo")
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
            .pitcherDayNightSplits(id: 543_037, client: mock)
            .season(2024)
            .fetch()
        let items = mock.lastEndpoint?.queryItems ?? []
        #expect(items.contains { $0.name == "sitCodes" && $0.value == "d,n" })
        #expect(items.contains { $0.name == "group" && $0.value == "pitching" })
    }

    @Test("SwiftBaseball.pitcherDayNightSplits is accessible")
    func namespacedPitcherDayNight() {
        _ = SwiftBaseball.pitcherDayNightSplits(id: 543_037)
    }

    // MARK: - Batter monthly

    @Test("Decode batter April monthly split from fixture")
    func batterAprilSplit() throws {
        let data = try Fixtures.load("player_monthly_splits_660271.json")
        let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: data)
        let ref = PlayerReference(id: 660_271, fullName: "Shohei Ohtani")
        let splits = MLBResponseConverters.playerMonthlySplits(from: response, playerRef: ref)

        let april = try #require(splits.april)
        #expect(april.gamesPlayed == 26)
        #expect(april.homeRuns == 11)
        #expect(abs((april.avg ?? 0) - 0.320) < 0.001)
        #expect(abs((april.ops ?? 0) - 1.087) < 0.001)
    }

    @Test("Decode batter March monthly split from fixture")
    func batterMarchSplit() throws {
        let data = try Fixtures.load("player_monthly_splits_660271.json")
        let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: data)
        let ref = PlayerReference(id: 660_271, fullName: "Shohei Ohtani")
        let splits = MLBResponseConverters.playerMonthlySplits(from: response, playerRef: ref)

        let march = try #require(splits.march)
        #expect(march.gamesPlayed == 12)
        #expect(march.homeRuns == 4)
    }

    @Test("Decode batter October monthly split from fixture")
    func batterOctoberSplit() throws {
        let data = try Fixtures.load("player_monthly_splits_660271.json")
        let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: data)
        let ref = PlayerReference(id: 660_271, fullName: "Shohei Ohtani")
        let splits = MLBResponseConverters.playerMonthlySplits(from: response, playerRef: ref)

        let october = try #require(splits.october)
        #expect(october.gamesPlayed == 8)
        #expect(october.homeRuns == 3)
        #expect(abs((october.avg ?? 0) - 0.324) < 0.001)
    }

    @Test("Absent month returns nil")
    func absentMonthIsNil() throws {
        // Fixture has no October entry for pitcher — confirm nil
        let data = try Fixtures.load("pitcher_monthly_splits_543037.json")
        let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: data)
        let ref = PlayerReference(id: 543_037, fullName: "Luis Castillo")
        let splits = MLBResponseConverters.pitcherMonthlySplits(from: response, playerRef: ref)

        #expect(splits.october == nil)
        #expect(splits.march != nil)
    }

    @Test("playerMonthlySplits endpoint uses sitCodes=m3,m4,m5,m6,m7,m8,m9,m10")
    func playerMonthlyEndpointParams() async throws {
        let mock = MockAPIClient()
        let data = try Fixtures.load("player_monthly_splits_660271.json")
        mock.stub(path: "people/660271/stats", data: data)
        _ = try await QueryBuilder<PlayerMonthlySplits>
            .playerMonthlySplits(id: 660_271, client: mock)
            .season(2024)
            .fetch()
        let items = mock.lastEndpoint?.queryItems ?? []
        #expect(items.contains { $0.name == "stats" && $0.value == "statSplits" })
        #expect(items.contains { $0.name == "sitCodes" && $0.value == "m3,m4,m5,m6,m7,m8,m9,m10" })
        #expect(items.contains { $0.name == "group" && $0.value == "hitting" })
    }

    @Test("pitcherMonthlySplits endpoint uses pitching group")
    func pitcherMonthlyEndpointParams() async throws {
        let mock = MockAPIClient()
        let data = try Fixtures.load("pitcher_monthly_splits_543037.json")
        mock.stub(path: "people/543037/stats", data: data)
        _ = try await QueryBuilder<PitcherMonthlySplits>
            .pitcherMonthlySplits(id: 543_037, client: mock)
            .season(2024)
            .fetch()
        let items = mock.lastEndpoint?.queryItems ?? []
        #expect(items.contains { $0.name == "sitCodes" && $0.value == "m3,m4,m5,m6,m7,m8,m9,m10" })
        #expect(items.contains { $0.name == "group" && $0.value == "pitching" })
    }

    @Test("SwiftBaseball.playerMonthlySplits is accessible")
    func namespacedPlayerMonthly() {
        _ = SwiftBaseball.playerMonthlySplits(id: 660_271)
    }

    @Test("SwiftBaseball.pitcherMonthlySplits is accessible")
    func namespacedPitcherMonthly() {
        _ = SwiftBaseball.pitcherMonthlySplits(id: 543_037)
    }

    // MARK: - Batter runners on base / RISP

    @Test("Decode batter bases-empty split from fixture")
    func batterBasesEmptySplit() throws {
        let data = try Fixtures.load("player_runners_on_splits_660271.json")
        let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: data)
        let ref = PlayerReference(id: 660_271, fullName: "Shohei Ohtani")
        let splits = MLBResponseConverters.playerRunnersOnSplits(from: response, playerRef: ref)

        let ne = try #require(splits.basesEmpty)
        #expect(ne.plateAppearances == 349)
        #expect(ne.homeRuns == 32)
        #expect(abs((ne.avg ?? 0) - 0.311) < 0.001)
    }

    @Test("Decode batter RISP split from fixture")
    func batterRISPSplit() throws {
        let data = try Fixtures.load("player_runners_on_splits_660271.json")
        let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: data)
        let ref = PlayerReference(id: 660_271, fullName: "Shohei Ohtani")
        let splits = MLBResponseConverters.playerRunnersOnSplits(from: response, playerRef: ref)

        let risp = try #require(splits.risp)
        #expect(risp.plateAppearances == 213)
        #expect(risp.homeRuns == 11)
        #expect(abs((risp.avg ?? 0) - 0.307) < 0.001)
    }

    @Test("Decode batter RISP+2out split from fixture")
    func batterRISPTwoOutSplit() throws {
        let data = try Fixtures.load("player_runners_on_splits_660271.json")
        let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: data)
        let ref = PlayerReference(id: 660_271, fullName: "Shohei Ohtani")
        let splits = MLBResponseConverters.playerRunnersOnSplits(from: response, playerRef: ref)

        let twoOut = try #require(splits.rispTwoOut)
        #expect(twoOut.plateAppearances == 98)
        #expect(twoOut.homeRuns == 4)
    }

    @Test("playerRunnersOnSplits endpoint uses sitCodes=ne,ro,ri,sf")
    func playerRunnersOnEndpointParams() async throws {
        let mock = MockAPIClient()
        let data = try Fixtures.load("player_runners_on_splits_660271.json")
        mock.stub(path: "people/660271/stats", data: data)
        _ = try await QueryBuilder<PlayerRunnersOnSplits>
            .playerRunnersOnSplits(id: 660_271, client: mock)
            .season(2024)
            .fetch()
        let items = mock.lastEndpoint?.queryItems ?? []
        #expect(items.contains { $0.name == "sitCodes" && $0.value == "ne,ro,ri,sf" })
        #expect(items.contains { $0.name == "group" && $0.value == "hitting" })
    }

    @Test("pitcherRunnersOnSplits endpoint uses pitching group")
    func pitcherRunnersOnEndpointParams() async throws {
        let mock = MockAPIClient()
        let data = try Fixtures.load("pitcher_runners_on_splits_543037.json")
        mock.stub(path: "people/543037/stats", data: data)
        _ = try await QueryBuilder<PitcherRunnersOnSplits>
            .pitcherRunnersOnSplits(id: 543_037, client: mock)
            .season(2024)
            .fetch()
        let items = mock.lastEndpoint?.queryItems ?? []
        #expect(items.contains { $0.name == "sitCodes" && $0.value == "ne,ro,ri,sf" })
        #expect(items.contains { $0.name == "group" && $0.value == "pitching" })
    }

    @Test("Decode pitcher RISP split from fixture")
    func pitcherRISPSplit() throws {
        let data = try Fixtures.load("pitcher_runners_on_splits_543037.json")
        let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: data)
        let ref = PlayerReference(id: 543_037, fullName: "Luis Castillo")
        let splits = MLBResponseConverters.pitcherRunnersOnSplits(from: response, playerRef: ref)

        let risp = try #require(splits.risp)
        #expect(risp.battersFaced == 152)
        #expect(risp.strikeOuts == 40)
        #expect(abs((risp.era ?? 0) - 6.43) < 0.01)
    }

    @Test("SwiftBaseball.playerRunnersOnSplits is accessible")
    func namespacedPlayerRunnersOn() {
        _ = SwiftBaseball.playerRunnersOnSplits(id: 660_271)
    }

    @Test("SwiftBaseball.pitcherRunnersOnSplits is accessible")
    func namespacedPitcherRunnersOn() {
        _ = SwiftBaseball.pitcherRunnersOnSplits(id: 543_037)
    }

    // MARK: - Batter leverage

    @Test("Decode batter low-leverage split from fixture")
    func batterLowLeverageSplit() throws {
        let data = try Fixtures.load("player_leverage_splits_660271.json")
        let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: data)
        let ref = PlayerReference(id: 660_271, fullName: "Shohei Ohtani")
        let splits = MLBResponseConverters.playerLeverageSplits(from: response, playerRef: ref)

        let low = try #require(splits.low)
        #expect(low.plateAppearances == 267)
        #expect(low.homeRuns == 21)
        #expect(abs((low.avg ?? 0) - 0.321) < 0.001)
    }

    @Test("Decode batter high-leverage split from fixture")
    func batterHighLeverageSplit() throws {
        let data = try Fixtures.load("player_leverage_splits_660271.json")
        let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: data)
        let ref = PlayerReference(id: 660_271, fullName: "Shohei Ohtani")
        let splits = MLBResponseConverters.playerLeverageSplits(from: response, playerRef: ref)

        let high = try #require(splits.high)
        #expect(high.plateAppearances == 251)
        #expect(high.homeRuns == 18)
        #expect(abs((high.ops ?? 0) - 1.031) < 0.001)
    }

    @Test("playerLeverageSplits endpoint uses sitCodes=le,lm,lh")
    func playerLeverageEndpointParams() async throws {
        let mock = MockAPIClient()
        let data = try Fixtures.load("player_leverage_splits_660271.json")
        mock.stub(path: "people/660271/stats", data: data)
        _ = try await QueryBuilder<PlayerLeverageSplits>
            .playerLeverageSplits(id: 660_271, client: mock)
            .season(2024)
            .fetch()
        let items = mock.lastEndpoint?.queryItems ?? []
        #expect(items.contains { $0.name == "sitCodes" && $0.value == "le,lm,lh" })
        #expect(items.contains { $0.name == "group" && $0.value == "hitting" })
    }

    @Test("pitcherLeverageSplits endpoint uses pitching group")
    func pitcherLeverageEndpointParams() async throws {
        let mock = MockAPIClient()
        let data = try Fixtures.load("pitcher_leverage_splits_543037.json")
        mock.stub(path: "people/543037/stats", data: data)
        _ = try await QueryBuilder<PitcherLeverageSplits>
            .pitcherLeverageSplits(id: 543_037, client: mock)
            .season(2024)
            .fetch()
        let items = mock.lastEndpoint?.queryItems ?? []
        #expect(items.contains { $0.name == "sitCodes" && $0.value == "le,lm,lh" })
        #expect(items.contains { $0.name == "group" && $0.value == "pitching" })
    }

    @Test("Decode pitcher high-leverage split from fixture")
    func pitcherHighLeverageSplit() throws {
        let data = try Fixtures.load("pitcher_leverage_splits_543037.json")
        let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: data)
        let ref = PlayerReference(id: 543_037, fullName: "Luis Castillo")
        let splits = MLBResponseConverters.pitcherLeverageSplits(from: response, playerRef: ref)

        let high = try #require(splits.high)
        #expect(high.battersFaced == 150)
        #expect(high.strikeOuts == 60)
        #expect(abs((high.era ?? 0) - 5.40) < 0.01)
    }

    @Test("SwiftBaseball.playerLeverageSplits is accessible")
    func namespacedPlayerLeverage() {
        _ = SwiftBaseball.playerLeverageSplits(id: 660_271)
    }

    @Test("SwiftBaseball.pitcherLeverageSplits is accessible")
    func namespacedPitcherLeverage() {
        _ = SwiftBaseball.pitcherLeverageSplits(id: 543_037)
    }

    // MARK: - Edge cases

    @Test("Empty monthly response returns all months nil")
    func emptyMonthlySplits() throws {
        let json = Data("""
        {"stats":[{"type":{"displayName":"statSplits"},"group":{"displayName":"hitting"},"splits":[]}]}
        """.utf8)
        let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: json)
        let ref = PlayerReference(id: 660_271, fullName: "")
        let splits = MLBResponseConverters.playerMonthlySplits(from: response, playerRef: ref)
        #expect(splits.march == nil)
        #expect(splits.april == nil)
        #expect(splits.september == nil)
        #expect(splits.october == nil)
    }

    @Test("Empty runners-on response returns all buckets nil")
    func emptyRunnersOnSplits() throws {
        let json = Data("""
        {"stats":[{"type":{"displayName":"statSplits"},"group":{"displayName":"hitting"},"splits":[]}]}
        """.utf8)
        let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: json)
        let ref = PlayerReference(id: 660_271, fullName: "")
        let splits = MLBResponseConverters.playerRunnersOnSplits(from: response, playerRef: ref)
        #expect(splits.basesEmpty == nil)
        #expect(splits.runnersOn == nil)
        #expect(splits.risp == nil)
        #expect(splits.rispTwoOut == nil)
    }

    @Test("Empty leverage response returns all buckets nil")
    func emptyLeverageSplits() throws {
        let json = Data("""
        {"stats":[{"type":{"displayName":"statSplits"},"group":{"displayName":"hitting"},"splits":[]}]}
        """.utf8)
        let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: json)
        let ref = PlayerReference(id: 660_271, fullName: "")
        let splits = MLBResponseConverters.playerLeverageSplits(from: response, playerRef: ref)
        #expect(splits.low == nil)
        #expect(splits.medium == nil)
        #expect(splits.high == nil)
    }

    @Test("Empty home/away response returns both nil")
    func emptyHomeAwaySplits() throws {
        let json = Data("""
        {"stats":[{"type":{"displayName":"statSplits"},"group":{"displayName":"hitting"},"splits":[]}]}
        """.utf8)
        let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: json)
        let ref = PlayerReference(id: 660_271, fullName: "")
        let splits = MLBResponseConverters.playerHomeAwaySplits(from: response, playerRef: ref)
        #expect(splits.home == nil)
        #expect(splits.away == nil)
    }

    @Test("Empty day/night response returns both nil")
    func emptyDayNightSplits() throws {
        let json = Data("""
        {"stats":[{"type":{"displayName":"statSplits"},"group":{"displayName":"hitting"},"splits":[]}]}
        """.utf8)
        let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: json)
        let ref = PlayerReference(id: 660_271, fullName: "")
        let splits = MLBResponseConverters.playerDayNightSplits(from: response, playerRef: ref)
        #expect(splits.day == nil)
        #expect(splits.night == nil)
    }

    @Test("Empty pitcher home/away response returns both nil")
    func emptyPitcherHomeAway() throws {
        let json = Data("""
        {"stats":[{"type":{"displayName":"statSplits"},"group":{"displayName":"pitching"},"splits":[]}]}
        """.utf8)
        let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: json)
        let ref = PlayerReference(id: 543_037, fullName: "")
        let splits = MLBResponseConverters.pitcherHomeAwaySplits(from: response, playerRef: ref)
        #expect(splits.home == nil)
        #expect(splits.away == nil)
    }

    @Test("Empty pitcher day/night response returns both nil")
    func emptyPitcherDayNight() throws {
        let json = Data("""
        {"stats":[{"type":{"displayName":"statSplits"},"group":{"displayName":"pitching"},"splits":[]}]}
        """.utf8)
        let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: json)
        let ref = PlayerReference(id: 543_037, fullName: "")
        let splits = MLBResponseConverters.pitcherDayNightSplits(from: response, playerRef: ref)
        #expect(splits.day == nil)
        #expect(splits.night == nil)
    }
}
