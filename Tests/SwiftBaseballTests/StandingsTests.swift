import Testing
import Foundation
@testable import SwiftBaseball

@Suite("Standings Tests")
struct StandingsTests {

    @Test("Decode standings from real API fixture")
    func decodeStandings() throws {
        let data = try Fixtures.load("standings_2024_al.json")
        let response = try JSONDecoder.mlb.decode(MLBStandingsResponse.self, from: data)
        let divisions = MLBResponseConverters.divisionStandings(from: response)

        #expect(divisions.count == 1)

        let alEast = try #require(divisions.first)
        #expect(alEast.division.name == "American League East")
        #expect(alEast.division.id == 201)
        #expect(alEast.teamRecords.count == 1)

        let yankees = try #require(alEast.teamRecords.first)
        #expect(yankees.team.id == 147)
        #expect(yankees.team.name == "Yankees")
        #expect(yankees.wins == 94)
        #expect(yankees.losses == 68)
        #expect(yankees.gamesPlayed == 162)
        #expect(abs(yankees.winningPercentage - 0.580) < 0.001)
        #expect(yankees.divisionRank == 1)
        #expect(yankees.divisionChamp == true)
        #expect(yankees.divisionLeader == true)
        #expect(yankees.clinched == true)
        #expect(yankees.runsScored == 815)
        #expect(yankees.runsAllowed == 668)
        #expect(yankees.runDifferential == 147)
    }

    @Test("Division leader has nil gamesBack")
    func divisionLeaderGamesBack() throws {
        let data = try Fixtures.load("standings_2024_al.json")
        let response = try JSONDecoder.mlb.decode(MLBStandingsResponse.self, from: data)
        let divisions = MLBResponseConverters.divisionStandings(from: response)
        let record = try #require(divisions.first?.teamRecords.first)

        // "-" in the API parses to nil — correct for a division leader
        #expect(record.gamesBack == nil)
    }

    @Test("Standings streak decodes correctly")
    func standingsStreak() throws {
        let data = try Fixtures.load("standings_2024_al.json")
        let response = try JSONDecoder.mlb.decode(MLBStandingsResponse.self, from: data)
        let divisions = MLBResponseConverters.divisionStandings(from: response)
        let record = try #require(divisions.first?.teamRecords.first)

        #expect(record.streak.streakType == "wins")
        #expect(record.streak.streakNumber == 1)
        #expect(record.streak.streakCode == "W1")
    }

    @Test("Last 10 record decodes from splitRecords")
    func lastTenDecodes() throws {
        let data = try Fixtures.load("standings_2024_al.json")
        let response = try JSONDecoder.mlb.decode(MLBStandingsResponse.self, from: data)
        let divisions = MLBResponseConverters.divisionStandings(from: response)
        let record = try #require(divisions.first?.teamRecords.first)

        #expect(record.lastTen.wins == 5)
        #expect(record.lastTen.losses == 5)
        #expect(record.lastTen.pct == ".500")
    }

    @Test("standings() query builder includes hydrate=division")
    func standingsQueryBuilder() async throws {
        let mock = MockAPIClient()
        let data = try Fixtures.load("standings_2024_al.json")
        mock.stub(path: "standings", data: data)

        let builder = QueryBuilder<[DivisionStandings]>.standings(.season(2024), client: mock)
        _ = try await builder.fetch()

        let items = mock.lastEndpoint?.queryItems ?? []
        #expect(items.contains { $0.name == "leagueId" && $0.value == "103,104" })
        #expect(items.contains { $0.name == "season" && $0.value == "2024" })
        #expect(items.contains { $0.name == "hydrate" && $0.value == "division" })
    }

    @Test(".league() replaces default leagueId")
    func leagueReplacesDefault() async throws {
        let mock = MockAPIClient()
        let data = try Fixtures.load("standings_2024_al.json")
        mock.stub(path: "standings", data: data)

        let builder = QueryBuilder<[DivisionStandings]>.standings(.season(2024), client: mock)
            .league(.american)
        _ = try await builder.fetch()

        let items = mock.lastEndpoint?.queryItems ?? []
        let leagueItems = items.filter { $0.name == "leagueId" }

        // Should have exactly one leagueId param (replaced, not duplicated)
        #expect(leagueItems.count == 1)
        #expect(leagueItems.first?.value == "103")
    }
}
