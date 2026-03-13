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

        let venue = try #require(game.venue)
        #expect(venue.id == 22)
        #expect(venue.name == "Dodger Stadium")
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

    // MARK: - Unknown game type

    @Test("Unknown gameType code falls back to .unknown not .regularSeason")
    func unknownGameTypeFallback() throws {
        let json = """
        {"dates":[{"date":"2024-07-04","games":[{
            "gamePk": 123,
            "gameDate": "2024-07-04T17:10:00Z",
            "gameType": "X",
            "season": "2024",
            "status": {"detailedState": "Final"},
            "teams": {
                "away": {"team": {"id": 1, "name": "Team A"}, "isWinner": false},
                "home": {"team": {"id": 2, "name": "Team B"}, "isWinner": true, "score": 5}
            },
            "venue": {"id": 1, "name": "Some Park"}
        }]}]}
        """.data(using: .utf8)!
        let response = try JSONDecoder.mlb.decode(MLBScheduleResponse.self, from: json)
        let entries = MLBResponseConverters.scheduleEntries(from: response)

        let game = try #require(entries.first)
        #expect(game.gameType == .unknown)
    }

    @Test("Missing gameType falls back to .unknown")
    func missingGameTypeFallback() throws {
        let json = """
        {"dates":[{"date":"2024-07-04","games":[{
            "gamePk": 124,
            "gameDate": "2024-07-04T17:10:00Z",
            "season": "2024",
            "status": {"detailedState": "Scheduled"},
            "teams": {
                "away": {"team": {"id": 1, "name": "Team A"}},
                "home": {"team": {"id": 2, "name": "Team B"}}
            }
        }]}]}
        """.data(using: .utf8)!
        let response = try JSONDecoder.mlb.decode(MLBScheduleResponse.self, from: json)
        let entries = MLBResponseConverters.scheduleEntries(from: response)

        let game = try #require(entries.first)
        #expect(game.gameType == .unknown)
    }

    // MARK: - Postponed game

    @Test("Postponed game decodes status correctly")
    func postponedGameStatus() throws {
        let data = try Fixtures.load("schedule_postponed.json")
        let response = try JSONDecoder.mlb.decode(MLBScheduleResponse.self, from: data)
        let entries = MLBResponseConverters.scheduleEntries(from: response)

        let game = try #require(entries.first)
        #expect(game.id == 745001)
        #expect(game.status == .postponed)
        #expect(game.gameType == .regularSeason)
        #expect(game.venue?.name == "Fenway Park")
    }

    @Test("Postponed game has nil score and isWinner false")
    func postponedGameNoScore() throws {
        let data = try Fixtures.load("schedule_postponed.json")
        let response = try JSONDecoder.mlb.decode(MLBScheduleResponse.self, from: data)
        let entries = MLBResponseConverters.scheduleEntries(from: response)

        let game = try #require(entries.first)
        #expect(game.teams.away.score == nil)
        #expect(game.teams.home.score == nil)
        #expect(game.teams.away.isWinner == false)
        #expect(game.teams.home.isWinner == false)
    }

    @Test("Postponed game teams decode correctly")
    func postponedGameTeams() throws {
        let data = try Fixtures.load("schedule_postponed.json")
        let response = try JSONDecoder.mlb.decode(MLBScheduleResponse.self, from: data)
        let entries = MLBResponseConverters.scheduleEntries(from: response)

        let game = try #require(entries.first)
        #expect(game.teams.away.team.id == 147)
        #expect(game.teams.away.team.name == "New York Yankees")
        #expect(game.teams.home.team.id == 111)
        #expect(game.teams.home.team.name == "Boston Red Sox")
    }

    // MARK: - Edge cases

    @Test("Empty dates array returns empty schedule")
    func emptyDatesReturnsEmpty() throws {
        let json = #"{"dates":[]}"#.data(using: .utf8)!
        let response = try JSONDecoder.mlb.decode(MLBScheduleResponse.self, from: json)
        let entries = MLBResponseConverters.scheduleEntries(from: response)

        #expect(entries.isEmpty)
    }

    @Test("Date with no games returns empty schedule")
    func dateWithNoGames() throws {
        let json = #"{"dates":[{"date":"2024-07-04","games":[]}]}"#.data(using: .utf8)!
        let response = try JSONDecoder.mlb.decode(MLBScheduleResponse.self, from: json)
        let entries = MLBResponseConverters.scheduleEntries(from: response)

        #expect(entries.isEmpty)
    }

    @Test("Game with missing venue gets placeholder venue")
    func missingVenueGetsPlaceholder() throws {
        let json = """
        {"dates":[{"date":"2024-07-04","games":[{
            "gamePk": 999,
            "gameDate": "2024-07-04T17:10:00Z",
            "gameType": "R",
            "season": "2024",
            "status": {"detailedState": "Final"},
            "teams": {
                "away": {"team": {"id": 1, "name": "Team A"}, "isWinner": false},
                "home": {"team": {"id": 2, "name": "Team B"}, "isWinner": true, "score": 3}
            }
        }]}]}
        """.data(using: .utf8)!
        let response = try JSONDecoder.mlb.decode(MLBScheduleResponse.self, from: json)
        let entries = MLBResponseConverters.scheduleEntries(from: response)

        let game = try #require(entries.first)
        #expect(game.venue == nil)
    }

    @Test("schedule() query builder uses dateRange parameter")
    func scheduleQueryBuilderDateRange() async throws {
        let mock = MockAPIClient()
        let data = try Fixtures.load("schedule_2024_07_04.json")
        mock.stub(path: "schedule", data: data)

        let builder = QueryBuilder<[ScheduleEntry]>.schedule(.dateRange("2024-07-01", "2024-07-07"), client: mock)
        _ = try await builder.fetch()

        let items = mock.lastEndpoint?.queryItems ?? []
        #expect(items.contains { $0.name == "startDate" && $0.value == "2024-07-01" })
        #expect(items.contains { $0.name == "endDate" && $0.value == "2024-07-07" })
    }
}
