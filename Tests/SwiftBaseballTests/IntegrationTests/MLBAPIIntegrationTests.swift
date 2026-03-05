import Testing
import Foundation
@testable import SwiftBaseball

/// Integration tests that hit the real MLB Stats API.
/// Only run when `SWIFTBASEBALL_INTEGRATION=1` environment variable is set.
///
/// ```
/// SWIFTBASEBALL_INTEGRATION=1 swift test --filter MLBAPIIntegrationTests
/// ```
@Suite("MLB API Integration Tests", .enabled(if: ProcessInfo.processInfo.environment["SWIFTBASEBALL_INTEGRATION"] == "1"))
struct MLBAPIIntegrationTests {

    let client: any APIClient = URLSessionAPIClient()

    // MARK: - Players

    @Test("Fetch player by ID (Ohtani)")
    func fetchPlayerById() async throws {
        let builder = QueryBuilder<Player>.singlePlayer(id: 660271, client: client)
        let player = try await builder.fetch()

        #expect(player.id == 660271)
        #expect(player.fullName == "Shohei Ohtani")
        #expect(player.primaryPosition == .twoWayPlayer)
        #expect(player.currentTeam != nil)
    }

    @Test("Fetch player by ID (Judge)")
    func fetchJudgeById() async throws {
        let builder = QueryBuilder<Player>.singlePlayer(id: 592450, client: client)
        let player = try await builder.fetch()

        #expect(player.id == 592450)
        #expect(player.fullName == "Aaron Judge")
        #expect(player.primaryPosition == .rightField)
        #expect(player.currentTeam?.id == 147)
    }

    @Test("Search players by name")
    func searchPlayers() async throws {
        let builder = QueryBuilder<[Player]>.players(.search("Ohtani"), client: client)
        let players = try await builder.fetch()

        #expect(!players.isEmpty)
        let ohtani = players.first { $0.id == 660271 }
        #expect(ohtani != nil)
        #expect(ohtani?.fullName == "Shohei Ohtani")
    }

    @Test("Search returns empty for nonsense query")
    func searchEmptyResults() async throws {
        let builder = QueryBuilder<[Player]>.players(.search("xyznonexistent99"), client: client)
        let players = try await builder.fetch()

        #expect(players.isEmpty)
    }

    // MARK: - Teams

    @Test("Fetch all teams for a season")
    func fetchAllTeams() async throws {
        let builder = QueryBuilder<[Team]>.teams(.all(season: 2024), client: client)
        let teams = try await builder.fetch()

        // MLB has 30 teams
        #expect(teams.count == 30)

        let yankees = teams.first { $0.abbreviation == "NYY" }
        #expect(yankees != nil)
        #expect(yankees?.name == "New York Yankees")
        #expect(yankees?.league.id == 103)
    }

    @Test("Fetch single team by ID")
    func fetchSingleTeam() async throws {
        let builder = QueryBuilder<Team>.singleTeam(id: 147, client: client)
        let team = try await builder.fetch()

        #expect(team.id == 147)
        #expect(team.abbreviation == "NYY")
        #expect(team.name == "New York Yankees")
    }

    @Test("Fetch team roster")
    func fetchRoster() async throws {
        let builder = QueryBuilder<[RosterEntry]>.roster(teamId: 147, season: 2024, client: client)
        let roster = try await builder.fetch()

        #expect(!roster.isEmpty)
        #expect(roster.count > 20) // Typical roster is 40+ entries

        // Every entry should have valid person info
        for entry in roster {
            #expect(entry.person.id > 0)
            #expect(!entry.person.fullName.isEmpty)
        }

        // At least some pitchers
        let pitchers = roster.filter { $0.position == .pitcher }
        #expect(!pitchers.isEmpty)
    }

    // MARK: - Schedule

    @Test("Fetch schedule by date")
    func fetchScheduleByDate() async throws {
        let builder = QueryBuilder<[ScheduleEntry]>.schedule(.date("2024-07-04"), client: client)
        let games = try await builder.fetch()

        #expect(!games.isEmpty)

        let first = try #require(games.first)
        #expect(first.season == "2024")
        #expect(first.teams.home.team.id > 0)
        #expect(first.teams.away.team.id > 0)
    }

    @Test("Fetch schedule with team filter")
    func fetchScheduleByTeam() async throws {
        let builder = QueryBuilder<[ScheduleEntry]>.schedule(.date("2024-07-04"), client: client)
            .teamId(147)
        let games = try await builder.fetch()

        // Yankees should have a game on July 4th (or possibly not)
        // Just verify decoding works — don't assert specific game existence
        for game in games {
            let isYankees = game.teams.home.team.id == 147 || game.teams.away.team.id == 147
            #expect(isYankees)
        }
    }

    // MARK: - Standings

    @Test("Fetch standings for season")
    func fetchStandings() async throws {
        let builder = QueryBuilder<[DivisionStandings]>.standings(.season(2024), client: client)
        let standings = try await builder.fetch()

        // 6 divisions (3 AL + 3 NL)
        #expect(standings.count == 6)

        for division in standings {
            #expect(division.division.id > 0)
            #expect(!division.division.name.isEmpty)
            #expect(division.teamRecords.count == 5) // 5 teams per division
        }
    }

    @Test("Standings filtered by league")
    func fetchStandingsByLeague() async throws {
        let builder = QueryBuilder<[DivisionStandings]>.standings(.season(2024), client: client)
            .league(.american)
        let standings = try await builder.fetch()

        // 3 AL divisions
        #expect(standings.count == 3)
    }
}
