import Testing
import Foundation
@testable import SwiftBaseball

@Suite("Schedule Tests")
struct ScheduleTests {

    @Test("Decode schedule from fixture")
    func decodeSchedule() throws {
        let data = try Fixtures.load("schedule_2024_07_04.json")
        let response = try JSONDecoder.mlb.decode(MLBScheduleResponse.self, from: data)
        let entries = MLBResponseConverters.scheduleEntries(from: response)

        #expect(entries.count == 1)

        let game = try #require(entries.first)
        #expect(game.id == 745612)
        #expect(game.status == .final)
        #expect(game.gameType == .regularSeason)
        #expect(game.season == "2024")
        #expect(game.gamesInSeries == 3)
        #expect(game.seriesGameNumber == 1)

        #expect(game.teams.home.team.id == 119)
        #expect(game.teams.home.team.name == "Los Angeles Dodgers")
        #expect(game.teams.home.score == 7)
        #expect(game.teams.home.isWinner == true)

        #expect(game.teams.away.team.id == 147)
        #expect(game.teams.away.team.name == "New York Yankees")
        #expect(game.teams.away.score == 3)
        #expect(game.teams.away.isWinner == false)

        #expect(game.venue.id == 22)
        #expect(game.venue.name == "Dodger Stadium")
    }

    @Test("Schedule game date parses correctly")
    func scheduleGameDate() throws {
        let data = try Fixtures.load("schedule_2024_07_04.json")
        let response = try JSONDecoder.mlb.decode(MLBScheduleResponse.self, from: data)
        let entries = MLBResponseConverters.scheduleEntries(from: response)

        let game = try #require(entries.first)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let components = calendar.dateComponents([.year, .month, .day], from: game.gameDate)

        #expect(components.year == 2024)
        #expect(components.month == 7)
        #expect(components.day == 4)
    }

    @Test("schedule() query builder uses date parameter")
    func scheduleQueryBuilderDate() async throws {
        let mock = MockAPIClient()
        let data = try Fixtures.load("schedule_2024_07_04.json")
        mock.stub(path: "schedule", data: data)

        let builder = QueryBuilder<[ScheduleEntry]>.schedule(.date("2024-07-04"), client: mock)
        let games = try await builder.fetch()

        #expect(games.count == 1)
        let dateItem = mock.lastEndpoint?.queryItems.first { $0.name == "date" }
        #expect(dateItem?.value == "2024-07-04")
    }

    @Test("league record decodes correctly")
    func leagueRecordDecodes() throws {
        let data = try Fixtures.load("schedule_2024_07_04.json")
        let response = try JSONDecoder.mlb.decode(MLBScheduleResponse.self, from: data)
        let entries = MLBResponseConverters.scheduleEntries(from: response)

        let game = try #require(entries.first)
        let homeRecord = try #require(game.teams.home.leagueRecord)
        #expect(homeRecord.wins == 50)
        #expect(homeRecord.losses == 33)
        #expect(homeRecord.pct == ".602")
    }
}
