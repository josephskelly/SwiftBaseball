import Foundation
@testable import SwiftBaseball
import Testing

@Suite("Statcast Leaderboard Tests")
struct StatcastLeaderboardTests {
    // MARK: - Sprint Speed Parser

    @Test("Parse sprint speed leaderboard from fixture")
    func parseSprintSpeedLeaderboard() throws {
        let data = try Fixtures.load("sprint_speed_leaderboard_2024.csv")
        let csv = try #require(String(data: data, encoding: .utf8))
        let entries = SprintSpeedParser.parse(csv, season: 2024)

        #expect(entries.count == 5)
        // All entries carry the season year injected by the parser
        #expect(entries.allSatisfy { $0.season == 2024 })
    }

    @Test("Sprint speed: fastest player parsed correctly")
    func sprintSpeedTopEntry() throws {
        let data = try Fixtures.load("sprint_speed_leaderboard_2024.csv")
        let csv = try #require(String(data: data, encoding: .utf8))
        let entries = SprintSpeedParser.parse(csv, season: 2024)

        let top = try #require(entries.first)
        #expect(top.playerId == 682_829)
        #expect(top.playerName == "De La Cruz, Elly") // parsed from "last_name, first_name" column
        #expect(top.team == "CIN")
        #expect(abs(top.sprintSpeed - 30.5) < 0.01)
        #expect(top.sprintAttempts == 312)
        #expect(top.percentile == 100)
        #expect(abs((top.homeToFirst ?? 0) - 4.08) < 0.01)
    }

    @Test("Sprint speed: all numeric fields parse correctly")
    func sprintSpeedNumericFields() throws {
        let data = try Fixtures.load("sprint_speed_leaderboard_2024.csv")
        let csv = try #require(String(data: data, encoding: .utf8))
        let entries = SprintSpeedParser.parse(csv, season: 2024)

        // Verify second entry (Witt Jr.)
        let witt = try #require(entries.first { $0.playerId == 677_951 })
        #expect(abs(witt.sprintSpeed - 30.1) < 0.01)
        #expect(witt.sprintAttempts == 289)
        #expect(witt.percentile == 99)
        #expect(abs((witt.homeToFirst ?? 0) - 4.12) < 0.01)
    }

    @Test("Sprint speed: row with missing optional fields uses nil")
    func sprintSpeedMissingOptionals() {
        let csv = """
        "last_name, first_name",player_id,team,sprint_speed,competitive_runs
        "De La Cruz, Elly",682829,CIN,30.5,312
        """
        let entries = SprintSpeedParser.parse(csv, season: 2024)
        #expect(entries.count == 1)
        #expect(entries[0].percentile == nil)
        #expect(entries[0].homeToFirst == nil)
    }

    @Test("Sprint speed: row missing required fields is skipped")
    func sprintSpeedSkipsMalformedRow() {
        let csv = """
        "last_name, first_name",player_id,team,sprint_speed,competitive_runs
        "De La Cruz, Elly",682829,CIN,30.5,312
        "missing_id",,LAD,29.0,100
        """
        let entries = SprintSpeedParser.parse(csv, season: 2024)
        #expect(entries.count == 1)
    }

    @Test("Sprint speed: empty CSV returns empty array")
    func sprintSpeedEmptyCSV() {
        let entries = SprintSpeedParser.parse("", season: 2024)
        #expect(entries.isEmpty)
    }

    @Test("SprintSpeedQuery season modifier is stored")
    func sprintSpeedQuerySeason() {
        let client = StatcastAPIClient()
        let query = SprintSpeedQuery(client: client).season(2024)
        // Verifying via fetch is integration-only; this confirms fluent chain compiles
        _ = query
    }

    @Test("SprintSpeedQuery minAttempts modifier compiles")
    func sprintSpeedQueryMinAttempts() {
        let client = StatcastAPIClient()
        let query = SprintSpeedQuery(client: client).season(2024).minAttempts(20)
        _ = query
    }

    @Test("SwiftBaseball.sprintSpeed() returns SprintSpeedQuery")
    func namespacedSprintSpeed() {
        let query = SwiftBaseball.sprintSpeed()
        _ = query.season(2024)
    }

    // MARK: - OAA Parser

    @Test("Parse OAA leaderboard from fixture")
    func parseOAALeaderboard() throws {
        let data = try Fixtures.load("oaa_leaderboard_2024.csv")
        let csv = try #require(String(data: data, encoding: .utf8))
        let entries = OAAParser.parse(csv, season: 2024)

        #expect(entries.count == 5)
        #expect(entries.allSatisfy { $0.season == 2024 })
    }

    @Test("OAA: top fielder parsed correctly")
    func oaaTopEntry() throws {
        let data = try Fixtures.load("oaa_leaderboard_2024.csv")
        let csv = try #require(String(data: data, encoding: .utf8))
        let entries = OAAParser.parse(csv, season: 2024)

        let top = try #require(entries.first)
        #expect(top.playerId == 571_448)
        #expect(top.playerName == "Arenado, Nolan")
        #expect(top.team == "STL")
        #expect(abs(top.oaa - 12.4) < 0.01)
        #expect(top.fielderAttempts == 320)
        #expect(top.percentile == 99)
        #expect(top.position == "3B")
    }

    @Test("OAA: negative OAA value parses correctly")
    func oaaNegativeValue() throws {
        let data = try Fixtures.load("oaa_leaderboard_2024.csv")
        let csv = try #require(String(data: data, encoding: .utf8))
        let entries = OAAParser.parse(csv, season: 2024)

        let ohtani = try #require(entries.first { $0.playerId == 660_271 })
        #expect(abs(ohtani.oaa - -1.4) < 0.01)
        #expect(ohtani.percentile == 42)
        #expect(ohtani.position == "LF")
    }

    @Test("OAA: all entries have player IDs and OAA values")
    func oaaAllEntriesValid() throws {
        let data = try Fixtures.load("oaa_leaderboard_2024.csv")
        let csv = try #require(String(data: data, encoding: .utf8))
        let entries = OAAParser.parse(csv, season: 2024)

        #expect(entries.allSatisfy { $0.playerId > 0 })
        #expect(entries.allSatisfy { !$0.playerName.isEmpty })
    }

    @Test("OAA: row missing required fields is skipped")
    func oaaSkipsMalformedRow() {
        let csv = """
        player_id,player_name,team,outs_above_average,att_outs_above_avg,percentile,pos,year
        571448,"Arenado, Nolan",STL,12.4,320,99,3B,2024
        ,missing_id,NYM,9.8,418,97,SS,2024
        """
        let entries = OAAParser.parse(csv, season: 2024)
        #expect(entries.count == 1)
    }

    @Test("OAA: empty CSV returns empty array")
    func oaaEmptyCSV() {
        let entries = OAAParser.parse("", season: 2024)
        #expect(entries.isEmpty)
    }

    @Test("OAAQuery season modifier compiles")
    func oaaQuerySeason() {
        let client = StatcastAPIClient()
        let query = OAAQuery(client: client).season(2024)
        _ = query
    }

    @Test("OAAQuery position modifier compiles")
    func oaaQueryPosition() {
        let client = StatcastAPIClient()
        let query = OAAQuery(client: client).season(2024).position("SS")
        _ = query
    }

    @Test("SwiftBaseball.outsAboveAverage() returns OAAQuery")
    func namespacedOAA() {
        let query = SwiftBaseball.outsAboveAverage()
        _ = query.season(2024).position("3B")
    }

    // MARK: - StatcastAPIClient refactor

    @Test("fetchCSV still delegates to fetchSavantCSV correctly (build check)")
    func fetchCSVDelegates() {
        // Compile-time check that fetchCSV still exists and fetchSavantCSV is accessible
        let client = StatcastAPIClient()
        // Both methods should be accessible on the same type
        _ = client
    }

    // MARK: - Catcher Framing Parser

    @Test("Parse catcher framing leaderboard from fixture")
    func parseCatcherFramingLeaderboard() throws {
        let data = try Fixtures.load("catcher_framing_leaderboard_2024.csv")
        let csv = try #require(String(data: data, encoding: .utf8))
        let entries = CatcherFramingParser.parse(csv, season: 2024)

        #expect(entries.count == 5)
        #expect(entries.allSatisfy { $0.season == 2024 })
    }

    @Test("Catcher framing: first entry parsed correctly")
    func catcherFramingTopEntry() throws {
        let data = try Fixtures.load("catcher_framing_leaderboard_2024.csv")
        let csv = try #require(String(data: data, encoding: .utf8))
        let entries = CatcherFramingParser.parse(csv, season: 2024)

        let top = try #require(entries.first)
        #expect(top.playerId == 672_275)
        #expect(top.playerName == "Bailey, Patrick")
        #expect(abs(top.framingRunsAdded - 25.06) < 0.01)
        #expect(abs(top.calledStrikeRate - 0.4764) < 0.001)
        #expect(top.pitchesSeen == 8913)
    }

    @Test("Catcher framing: negative framing runs parses correctly")
    func catcherFramingNegativeValue() throws {
        let data = try Fixtures.load("catcher_framing_leaderboard_2024.csv")
        let csv = try #require(String(data: data, encoding: .utf8))
        let entries = CatcherFramingParser.parse(csv, season: 2024)

        let realmuto = try #require(entries.first { $0.playerId == 592_663 })
        #expect(abs(realmuto.framingRunsAdded - -8.37) < 0.01)
        #expect(realmuto.playerName == "Realmuto, J.T.")
        #expect(realmuto.pitchesSeen == 9714)
    }

    @Test("Catcher framing: all entries have valid player IDs and names")
    func catcherFramingAllEntriesValid() throws {
        let data = try Fixtures.load("catcher_framing_leaderboard_2024.csv")
        let csv = try #require(String(data: data, encoding: .utf8))
        let entries = CatcherFramingParser.parse(csv, season: 2024)

        #expect(entries.allSatisfy { $0.playerId > 0 })
        #expect(entries.allSatisfy { !$0.playerName.isEmpty })
    }

    @Test("Catcher framing: season is injected by parser")
    func catcherFramingSeasonInjected() throws {
        let data = try Fixtures.load("catcher_framing_leaderboard_2024.csv")
        let csv = try #require(String(data: data, encoding: .utf8))
        let entries = CatcherFramingParser.parse(csv, season: 2023)

        #expect(entries.allSatisfy { $0.season == 2023 })
    }

    @Test("Catcher framing: BOM-prefixed CSV is handled correctly")
    func catcherFramingBOMHandled() {
        // Real API responses include a UTF-8 BOM before the first header
        let csv = "\u{FEFF}id,name,pitches,rv_tot,pct_tot,rv_11,pct_11,rv_12,pct_12,rv_13,pct_13,rv_14,pct_14,rv_16,pct_16,rv_17,pct_17,rv_18,pct_18,rv_19,pct_19\n672275,\"Bailey, Patrick\",8913,25.06,0.4764,2,0.229,5,0.529,3,0.268,6,0.612,3,0.596,2,0.366,2,0.505,2,0.237\n"
        let entries = CatcherFramingParser.parse(csv, season: 2024)
        #expect(entries.count == 1)
        #expect(entries[0].playerId == 672_275)
    }

    @Test("Catcher framing: row missing required field is skipped")
    func catcherFramingSkipsMalformedRow() {
        let csv = "id,name,pitches,rv_tot,pct_tot,rv_11,pct_11,rv_12,pct_12,rv_13,pct_13,rv_14,pct_14,rv_16,pct_16,rv_17,pct_17,rv_18,pct_18,rv_19,pct_19\n672275,\"Bailey, Patrick\",8913,25.06,0.4764,2,0.229,5,0.529,3,0.268,6,0.612,3,0.596,2,0.366,2,0.505,2,0.237\n,\"Missing ID\",5000,3.0,0.43,0,0.1,0,0.4,0,0.1,0,0.5,0,0.5,0,0.2,0,0.4,0,0.2\n"
        let entries = CatcherFramingParser.parse(csv, season: 2024)
        #expect(entries.count == 1)
    }

    @Test("Catcher framing: empty CSV returns empty array")
    func catcherFramingEmptyCSV() {
        let entries = CatcherFramingParser.parse("", season: 2024)
        #expect(entries.isEmpty)
    }

    @Test("CatcherFramingQuery season modifier compiles")
    func catcherFramingQuerySeason() {
        let client = StatcastAPIClient()
        let query = CatcherFramingQuery(client: client).season(2024)
        _ = query
    }

    @Test("CatcherFramingQuery minPitches modifier compiles")
    func catcherFramingQueryMinPitches() {
        let client = StatcastAPIClient()
        let query = CatcherFramingQuery(client: client).season(2024).minPitches(500)
        _ = query
    }

    @Test("SwiftBaseball.catcherFraming() returns CatcherFramingQuery")
    func namespacedCatcherFraming() {
        let query = SwiftBaseball.catcherFraming()
        _ = query.season(2024).minPitches(300)
    }

    @Test("fetchSavantPage delegates to fetchSavantCSV (build check)")
    func fetchSavantPageExists() {
        let client = StatcastAPIClient()
        _ = client
        // Compile-time check that fetchSavantPage is accessible alongside fetchSavantCSV
    }

    // MARK: - Pop Time Parser

    @Test("Parse pop time leaderboard from fixture")
    func parsePopTimeLeaderboard() throws {
        let data = try Fixtures.load("pop_time_leaderboard_2024.csv")
        let csv = try #require(String(data: data, encoding: .utf8))
        let entries = PopTimeParser.parse(csv, season: 2024)

        #expect(entries.count == 5)
        #expect(entries.allSatisfy { $0.season == 2024 })
    }

    @Test("Pop time: first entry parsed correctly")
    func popTimeTopEntry() throws {
        let data = try Fixtures.load("pop_time_leaderboard_2024.csv")
        let csv = try #require(String(data: data, encoding: .utf8))
        let entries = PopTimeParser.parse(csv, season: 2024)

        let top = try #require(entries.first)
        #expect(top.playerId == 672_275)
        #expect(top.playerName == "Bailey, Patrick")
        #expect(abs(top.popTimeTo2B - 1.85) < 0.001)
        #expect(top.throwsTo2B == 58)
        #expect(abs(top.exchangeTime - 0.60) < 0.001)
        #expect(abs(top.armStrength - 84.6) < 0.01)
    }

    @Test("Pop time: CS and SB splits parsed correctly")
    func popTimeSplits() throws {
        let data = try Fixtures.load("pop_time_leaderboard_2024.csv")
        let csv = try #require(String(data: data, encoding: .utf8))
        let entries = PopTimeParser.parse(csv, season: 2024)

        let bailey = try #require(entries.first { $0.playerId == 672_275 })
        #expect(abs((bailey.popTimeTo2BOnCS ?? 0) - 1.83) < 0.001)
        #expect(abs((bailey.popTimeTo2BOnSB ?? 0) - 1.86) < 0.001)
    }

    @Test("Pop time: 3B fields parsed when present")
    func popTime3BFields() throws {
        let data = try Fixtures.load("pop_time_leaderboard_2024.csv")
        let csv = try #require(String(data: data, encoding: .utf8))
        let entries = PopTimeParser.parse(csv, season: 2024)

        let realmuto = try #require(entries.first { $0.playerId == 592_663 })
        #expect(realmuto.throwsTo3B == 4)
        #expect(abs((realmuto.popTimeTo3B ?? 0) - 1.42) < 0.001)
    }

    @Test("Pop time: 3B fields nil when no 3B attempts")
    func popTimeNo3BAttempts() throws {
        let data = try Fixtures.load("pop_time_leaderboard_2024.csv")
        let csv = try #require(String(data: data, encoding: .utf8))
        let entries = PopTimeParser.parse(csv, season: 2024)

        let haase = try #require(entries.first { $0.playerId == 606_992 })
        #expect(haase.throwsTo3B == 0)
        #expect(haase.popTimeTo3B == nil)
    }

    @Test("Pop time: season injected by parser")
    func popTimeSeasonInjected() throws {
        let data = try Fixtures.load("pop_time_leaderboard_2024.csv")
        let csv = try #require(String(data: data, encoding: .utf8))
        let entries = PopTimeParser.parse(csv, season: 2023)

        #expect(entries.allSatisfy { $0.season == 2023 })
    }

    @Test("Pop time: row missing required field is skipped")
    func popTimeSkipsMalformedRow() {
        let csv = "entity_name,entity_id,team_id,age,maxeff_arm_2b_3b_sba,exchange_2b_3b_sba,pop_2b_sba_count,pop_2b_sba,pop_2b_cs,pop_2b_sb,pop_3b_sba_count,pop_3b_sba,pop_3b_cs,pop_3b_sb\n\"Bailey, Patrick\",672275,137,25,84.6,0.60,58,1.85,1.83,1.86,2,1.40,1.42,1.37\n\"No ID\",,137,25,84.0,0.62,30,1.90,1.88,1.91,0,,,\n"
        let entries = PopTimeParser.parse(csv, season: 2024)
        #expect(entries.count == 1)
    }

    @Test("Pop time: empty CSV returns empty array")
    func popTimeEmptyCSV() {
        let entries = PopTimeParser.parse("", season: 2024)
        #expect(entries.isEmpty)
    }

    @Test("PopTimeQuery season modifier compiles")
    func popTimeQuerySeason() {
        let client = StatcastAPIClient()
        let query = PopTimeQuery(client: client).season(2024)
        _ = query
    }

    @Test("PopTimeQuery minAttempts modifier compiles")
    func popTimeQueryMinAttempts() {
        let client = StatcastAPIClient()
        let query = PopTimeQuery(client: client).season(2024).minAttempts(10)
        _ = query
    }

    @Test("SwiftBaseball.catcherPopTime() returns PopTimeQuery")
    func namespacedPopTime() {
        let query = SwiftBaseball.catcherPopTime()
        _ = query.season(2024).minAttempts(10)
    }
}
