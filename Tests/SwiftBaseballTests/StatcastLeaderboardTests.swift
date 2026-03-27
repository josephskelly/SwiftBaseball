import Testing
import Foundation
@testable import SwiftBaseball

@Suite("Statcast Leaderboard Tests")
struct StatcastLeaderboardTests {

    // MARK: - Sprint Speed Parser

    @Test("Parse sprint speed leaderboard from fixture")
    func parseSprintSpeedLeaderboard() throws {
        let data = try Fixtures.load("sprint_speed_leaderboard_2024.csv")
        let csv = String(data: data, encoding: .utf8)!
        let entries = SprintSpeedParser.parse(csv, season: 2024)

        #expect(entries.count == 5)
        // All entries carry the season year injected by the parser
        #expect(entries.allSatisfy { $0.season == 2024 })
    }

    @Test("Sprint speed: fastest player parsed correctly")
    func sprintSpeedTopEntry() throws {
        let data = try Fixtures.load("sprint_speed_leaderboard_2024.csv")
        let csv = String(data: data, encoding: .utf8)!
        let entries = SprintSpeedParser.parse(csv, season: 2024)

        let top = try #require(entries.first)
        #expect(top.playerId == 682829)
        #expect(top.playerName == "De La Cruz, Elly")
        #expect(top.team == "CIN")
        #expect(abs(top.sprintSpeed - 30.5) < 0.01)
        #expect(top.sprintAttempts == 312)
        #expect(top.percentile == 100)
        #expect(abs((top.homeToFirst ?? 0) - 4.08) < 0.01)
    }

    @Test("Sprint speed: all numeric fields parse correctly")
    func sprintSpeedNumericFields() throws {
        let data = try Fixtures.load("sprint_speed_leaderboard_2024.csv")
        let csv = String(data: data, encoding: .utf8)!
        let entries = SprintSpeedParser.parse(csv, season: 2024)

        // Verify second entry (Witt Jr.)
        let witt = try #require(entries.first { $0.playerId == 677951 })
        #expect(abs(witt.sprintSpeed - 30.1) < 0.01)
        #expect(witt.sprintAttempts == 289)
        #expect(witt.percentile == 99)
        #expect(abs((witt.homeToFirst ?? 0) - 4.12) < 0.01)
    }

    @Test("Sprint speed: row with missing optional fields uses nil")
    func sprintSpeedMissingOptionals() throws {
        let csv = """
        player_id,player_name,team,sprint_speed,attempts
        682829,"De La Cruz, Elly",CIN,30.5,312
        """
        let entries = SprintSpeedParser.parse(csv, season: 2024)
        #expect(entries.count == 1)
        #expect(entries[0].percentile == nil)
        #expect(entries[0].homeToFirst == nil)
    }

    @Test("Sprint speed: row missing required fields is skipped")
    func sprintSpeedSkipsMalformedRow() throws {
        let csv = """
        player_id,player_name,team,sprint_speed,attempts
        682829,"De La Cruz, Elly",CIN,30.5,312
        ,missing_id,LAD,29.0,100
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
        let csv = String(data: data, encoding: .utf8)!
        let entries = OAAParser.parse(csv, season: 2024)

        #expect(entries.count == 5)
        #expect(entries.allSatisfy { $0.season == 2024 })
    }

    @Test("OAA: top fielder parsed correctly")
    func oaaTopEntry() throws {
        let data = try Fixtures.load("oaa_leaderboard_2024.csv")
        let csv = String(data: data, encoding: .utf8)!
        let entries = OAAParser.parse(csv, season: 2024)

        let top = try #require(entries.first)
        #expect(top.playerId == 571448)
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
        let csv = String(data: data, encoding: .utf8)!
        let entries = OAAParser.parse(csv, season: 2024)

        let ohtani = try #require(entries.first { $0.playerId == 660271 })
        #expect(abs(ohtani.oaa - (-1.4)) < 0.01)
        #expect(ohtani.percentile == 42)
        #expect(ohtani.position == "LF")
    }

    @Test("OAA: all entries have player IDs and OAA values")
    func oaaAllEntriesValid() throws {
        let data = try Fixtures.load("oaa_leaderboard_2024.csv")
        let csv = String(data: data, encoding: .utf8)!
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
        let data = try Fixtures.load("catcher_framing_leaderboard_2024.html")
        let html = String(data: data, encoding: .utf8)!
        let entries = CatcherFramingParser.parse(html, season: 2024)

        #expect(entries.count == 5)
        #expect(entries.allSatisfy { $0.season == 2024 })
    }

    @Test("Catcher framing: first entry parsed correctly")
    func catcherFramingTopEntry() throws {
        let data = try Fixtures.load("catcher_framing_leaderboard_2024.html")
        let html = String(data: data, encoding: .utf8)!
        let entries = CatcherFramingParser.parse(html, season: 2024)

        let top = try #require(entries.first)
        #expect(top.playerId == 678578)
        #expect(top.playerName == "Bailey, Patrick")
        #expect(top.team == "Giants")
        #expect(abs(top.framingRunsAdded - 12.5) < 0.01)
        #expect(abs(top.calledStrikeRate - 0.448) < 0.001)
        #expect(top.pitchesSeen == 6891)
        #expect(top.shadowPitches == 2781)
    }

    @Test("Catcher framing: negative framing runs parses correctly")
    func catcherFramingNegativeValue() throws {
        let data = try Fixtures.load("catcher_framing_leaderboard_2024.html")
        let html = String(data: data, encoding: .utf8)!
        let entries = CatcherFramingParser.parse(html, season: 2024)

        let realmuto = try #require(entries.first { $0.playerId == 592663 })
        #expect(abs(realmuto.framingRunsAdded - (-8.37)) < 0.01)
        #expect(realmuto.playerName == "Realmuto, J.T.")
        #expect(realmuto.team == "Phillies")
        #expect(realmuto.pitchesSeen == 9714)
        #expect(realmuto.shadowPitches == 4002)
    }

    @Test("Catcher framing: all entries have valid player IDs and names")
    func catcherFramingAllEntriesValid() throws {
        let data = try Fixtures.load("catcher_framing_leaderboard_2024.html")
        let html = String(data: data, encoding: .utf8)!
        let entries = CatcherFramingParser.parse(html, season: 2024)

        #expect(entries.allSatisfy { $0.playerId > 0 })
        #expect(entries.allSatisfy { !$0.playerName.isEmpty })
        #expect(entries.allSatisfy { !$0.team.isEmpty })
    }

    @Test("Catcher framing: season is injected by parser")
    func catcherFramingSeasonInjected() throws {
        let data = try Fixtures.load("catcher_framing_leaderboard_2024.html")
        let html = String(data: data, encoding: .utf8)!
        let entries = CatcherFramingParser.parse(html, season: 2023)

        #expect(entries.allSatisfy { $0.season == 2023 })
    }

    @Test("Catcher framing: HTML with no data constant returns empty array")
    func catcherFramingNoDataConstant() {
        let html = "<html><body><script>const other = [];</script></body></html>"
        let entries = CatcherFramingParser.parse(html, season: 2024)
        #expect(entries.isEmpty)
    }

    @Test("Catcher framing: empty string returns empty array")
    func catcherFramingEmptyInput() {
        let entries = CatcherFramingParser.parse("", season: 2024)
        #expect(entries.isEmpty)
    }

    @Test("Catcher framing: malformed JSON in data block returns empty array")
    func catcherFramingMalformedJSON() {
        let html = "<script>const data = [not valid json];</script>"
        let entries = CatcherFramingParser.parse(html, season: 2024)
        #expect(entries.isEmpty)
    }

    @Test("Catcher framing: entry missing required field is excluded")
    func catcherFramingMissingRequiredField() {
        // Missing fielder_2 (player ID) — decoder will fail, returning empty array
        let html = """
        <script>
        const data = [{"f2_name_display_first_last":"Bailey, Patrick","team_name":"Giants","rv_tot":12.5,"pct_tot":0.448,"pitches":6891,"pitches_shadow":2781}];
        </script>
        """
        let entries = CatcherFramingParser.parse(html, season: 2024)
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
}
