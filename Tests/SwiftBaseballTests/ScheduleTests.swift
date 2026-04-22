import Foundation
@testable import SwiftBaseball
import Testing

@Suite("Schedule Tests")
struct ScheduleTests {
    @Test("Decode schedule from fixture")
    func decodeSchedule() throws {
        let data = try Fixtures.load("schedule_2024_07_04.json")
        let response = try JSONDecoder.mlb.decode(MLBScheduleResponse.self, from: data)
        let entries = MLBResponseConverters.scheduleEntries(from: response)

        #expect(entries.count == 1)

        let game = try #require(entries.first)
        #expect(game.id == 745_612)
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
        calendar.timeZone = try #require(TimeZone(identifier: "UTC"))
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
        let json = Data("""
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
        """.utf8)
        let response = try JSONDecoder.mlb.decode(MLBScheduleResponse.self, from: json)
        let entries = MLBResponseConverters.scheduleEntries(from: response)

        let game = try #require(entries.first)
        #expect(game.gameType == .unknown)
    }

    @Test("Missing gameType falls back to .unknown")
    func missingGameTypeFallback() throws {
        let json = Data("""
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
        """.utf8)
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
        #expect(game.id == 745_001)
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

    // MARK: - Completed Early (weather-shortened)

    @Test("Completed Early (Rain) game decodes status as .final via abstractGameState fallback")
    func completedEarlyRainFallback() throws {
        let data = try Fixtures.load("schedule_completed_early.json")
        let response = try JSONDecoder.mlb.decode(MLBScheduleResponse.self, from: data)
        let entries = MLBResponseConverters.scheduleEntries(from: response)

        let game = try #require(entries.first)
        #expect(game.id == 746_100)
        // detailedState "Completed Early (Rain)" is unrecognized; abstractGameState
        // "Final" should cause the converter to return .final.
        #expect(game.status == .final)
    }

    @Test("Completed Early game has correct scores and teams")
    func completedEarlyScoresAndTeams() throws {
        let data = try Fixtures.load("schedule_completed_early.json")
        let response = try JSONDecoder.mlb.decode(MLBScheduleResponse.self, from: data)
        let entries = MLBResponseConverters.scheduleEntries(from: response)

        let game = try #require(entries.first)
        #expect(game.teams.away.team.id == 121)
        #expect(game.teams.away.team.name == "New York Mets")
        #expect(game.teams.away.score == 5)
        #expect(game.teams.home.team.id == 146)
        #expect(game.teams.home.team.name == "Miami Marlins")
        #expect(game.teams.home.score == 5)
    }

    @Test("nil detailedState with abstractGameState Final decodes as .final")
    func nilDetailedStateAbstractFinal() throws {
        let json = Data("""
        {"dates":[{"date":"2024-06-12","games":[{
            "gamePk": 746200,
            "gameDate": "2024-06-12T23:10:00Z",
            "gameType": "R",
            "season": "2024",
            "status": {"abstractGameState": "Final", "codedGameState": "F"},
            "teams": {
                "away": {"team": {"id": 1, "name": "Team A"}, "isWinner": false},
                "home": {"team": {"id": 2, "name": "Team B"}, "isWinner": true, "score": 4}
            }
        }]}]}
        """.utf8)
        let response = try JSONDecoder.mlb.decode(MLBScheduleResponse.self, from: json)
        let entries = MLBResponseConverters.scheduleEntries(from: response)

        let game = try #require(entries.first)
        #expect(game.status == .final)
    }

    @Test("Unrecognized detailedState with abstractGameState Live decodes as .inProgress")
    func unrecognizedDetailedStateLive() throws {
        let json = Data("""
        {"dates":[{"date":"2024-06-12","games":[{
            "gamePk": 746201,
            "gameDate": "2024-06-12T23:10:00Z",
            "gameType": "R",
            "season": "2024",
            "status": {"abstractGameState": "Live", "detailedState": "Rain Delay: Top 5th", "codedGameState": "I"},
            "teams": {
                "away": {"team": {"id": 1, "name": "Team A"}, "isWinner": false},
                "home": {"team": {"id": 2, "name": "Team B"}, "isWinner": false}
            }
        }]}]}
        """.utf8)
        let response = try JSONDecoder.mlb.decode(MLBScheduleResponse.self, from: json)
        let entries = MLBResponseConverters.scheduleEntries(from: response)

        let game = try #require(entries.first)
        #expect(game.status == .inProgress)
    }

    // MARK: - Edge cases

    @Test("Empty dates array returns empty schedule")
    func emptyDatesReturnsEmpty() throws {
        let json = Data(#"{"dates":[]}"#.utf8)
        let response = try JSONDecoder.mlb.decode(MLBScheduleResponse.self, from: json)
        let entries = MLBResponseConverters.scheduleEntries(from: response)

        #expect(entries.isEmpty)
    }

    @Test("Date with no games returns empty schedule")
    func dateWithNoGames() throws {
        let json = Data(#"{"dates":[{"date":"2024-07-04","games":[]}]}"#.utf8)
        let response = try JSONDecoder.mlb.decode(MLBScheduleResponse.self, from: json)
        let entries = MLBResponseConverters.scheduleEntries(from: response)

        #expect(entries.isEmpty)
    }

    @Test("Game with missing venue gets placeholder venue")
    func missingVenueGetsPlaceholder() throws {
        let json = Data("""
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
        """.utf8)
        let response = try JSONDecoder.mlb.decode(MLBScheduleResponse.self, from: json)
        let entries = MLBResponseConverters.scheduleEntries(from: response)

        let game = try #require(entries.first)
        #expect(game.venue == nil)
    }

    // MARK: - Probable pitcher

    @Test("Probable pitchers decode when hydrate=probablePitcher is present")
    func probablePitcherDecodes() throws {
        let data = try Fixtures.load("schedule_probable_pitcher.json")
        let response = try JSONDecoder.mlb.decode(MLBScheduleResponse.self, from: data)
        let entries = MLBResponseConverters.scheduleEntries(from: response)

        let game = try #require(entries.first)

        let awayPitcher = try #require(game.teams.away.probablePitcher)
        #expect(awayPitcher.id == 605_483)
        #expect(awayPitcher.fullName == "Zack Wheeler")

        let homePitcher = try #require(game.teams.home.probablePitcher)
        #expect(homePitcher.id == 656_945)
        #expect(homePitcher.fullName == "Kodai Senga")
    }

    @Test("Probable pitcher is nil when not included in response")
    func probablePitcherNilWhenAbsent() throws {
        let data = try Fixtures.load("schedule_2024_07_04.json")
        let response = try JSONDecoder.mlb.decode(MLBScheduleResponse.self, from: data)
        let entries = MLBResponseConverters.scheduleEntries(from: response)

        let game = try #require(entries.first)
        #expect(game.teams.away.probablePitcher == nil)
        #expect(game.teams.home.probablePitcher == nil)
    }

    @Test("schedule() query builder appends hydrate=probablePitcher query item")
    func scheduleQueryBuilderHydrateProbablePitcher() async throws {
        let mock = MockAPIClient()
        let data = try Fixtures.load("schedule_probable_pitcher.json")
        mock.stub(path: "schedule", data: data)

        let builder = QueryBuilder<[ScheduleEntry]>.schedule(
            .date("2026-04-01"),
            hydrate: [.probablePitcher],
            client: mock
        )
        _ = try await builder.fetch()

        let items = mock.lastEndpoint?.queryItems ?? []
        #expect(items.contains { $0.name == "hydrate" && $0.value == "probablePitcher" })
    }

    @Test("schedule() query builder without hydrate omits hydrate query item")
    func scheduleQueryBuilderNoHydrate() async throws {
        let mock = MockAPIClient()
        let data = try Fixtures.load("schedule_2024_07_04.json")
        mock.stub(path: "schedule", data: data)

        let builder = QueryBuilder<[ScheduleEntry]>.schedule(.date("2024-07-04"), client: mock)
        _ = try await builder.fetch()

        let items = mock.lastEndpoint?.queryItems ?? []
        #expect(!items.contains { $0.name == "hydrate" })
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
