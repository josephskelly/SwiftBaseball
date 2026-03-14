import Testing
import Foundation
@testable import SwiftBaseball

@Suite("Game Log Tests")
struct GameLogTests {

    // MARK: - Fixture decoding

    @Test("Decode game log entries from fixture")
    func decodeFromFixture() throws {
        let data = try Fixtures.load("game_log_batting_660271.json")
        let response = try JSONDecoder.mlb.decode(MLBGameLogResponse.self, from: data)
        let entries = MLBResponseConverters.gameLogEntries(from: response)

        #expect(entries.count == 3)

        let first = try #require(entries.first)
        #expect(first.player.id == 660271)
        #expect(first.player.fullName == "Shohei Ohtani")
        #expect(first.season == "2024")
        #expect(first.team.id == 119)
        #expect(first.team.name == "Los Angeles Dodgers")
        #expect(first.opponent.id == 135)
        #expect(first.opponent.name == "San Diego Padres")
        #expect(first.isHome == false)
        #expect(first.isWin == true)
        #expect(first.gameType == .regularSeason)
        #expect(first.gamePk == 745444)
    }

    @Test("Batting stats populated from game log fixture")
    func battingStatsFromFixture() throws {
        let data = try Fixtures.load("game_log_batting_660271.json")
        let response = try JSONDecoder.mlb.decode(MLBGameLogResponse.self, from: data)
        let entries = MLBResponseConverters.gameLogEntries(from: response)

        let first = try #require(entries.first)
        #expect(first.group == .batting)
        #expect(first.pitching == nil)
        #expect(first.fielding == nil)

        let batting = try #require(first.batting)
        #expect(batting.gamesPlayed == 1)
        #expect(batting.atBats == 5)
        #expect(batting.hits == 2)
        #expect(batting.homeRuns == 0)
        #expect(batting.rbi == 1)
        #expect(batting.stolenBases == 1)
        #expect(batting.strikeOuts == 0)
        #expect(batting.baseOnBalls == 0)
    }

    @Test("Date parsing produces correct Date value")
    func dateParsing() throws {
        let data = try Fixtures.load("game_log_batting_660271.json")
        let response = try JSONDecoder.mlb.decode(MLBGameLogResponse.self, from: data)
        let entries = MLBResponseConverters.gameLogEntries(from: response)

        let first = try #require(entries.first)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let components = calendar.dateComponents([.year, .month, .day], from: first.date)
        #expect(components.year == 2024)
        #expect(components.month == 3)
        #expect(components.day == 20)
    }

    @Test("All entries have valid gamePk")
    func allEntriesHaveGamePk() throws {
        let data = try Fixtures.load("game_log_batting_660271.json")
        let response = try JSONDecoder.mlb.decode(MLBGameLogResponse.self, from: data)
        let entries = MLBResponseConverters.gameLogEntries(from: response)

        let gamePks = entries.map(\.gamePk)
        #expect(gamePks == [745444, 746175, 746165])
    }

    @Test("Empty splits produce empty array")
    func emptySplits() throws {
        let json = """
        {"stats":[{"type":{"displayName":"gameLog"},"group":{"displayName":"hitting"},"splits":[]}]}
        """.data(using: .utf8)!
        let response = try JSONDecoder.mlb.decode(MLBGameLogResponse.self, from: json)
        let entries = MLBResponseConverters.gameLogEntries(from: response)

        #expect(entries.isEmpty)
    }

    // MARK: - QueryBuilder

    private let baseURL = URL(string: "https://statsapi.mlb.com/api/v1/")!

    @Test("Query builder path is correct")
    func queryBuilderPath() throws {
        let mock = MockAPIClient()
        let builder = QueryBuilder<[GameLogEntry]>.gameLog(playerId: 660271, client: mock)

        #expect(builder.endpoint.path == "people/660271/stats")
        let url = try #require(builder.endpoint.url(baseURL: baseURL))
        #expect(url.absoluteString.contains("stats=gameLog"))
    }

    @Test("Query builder with season and group modifiers")
    func queryBuilderModifiers() throws {
        let mock = MockAPIClient()
        let builder = QueryBuilder<[GameLogEntry]>.gameLog(playerId: 660271, client: mock)
            .season(2024)
            .group(.batting)

        let url = try #require(builder.endpoint.url(baseURL: baseURL))
        let urlString = url.absoluteString
        #expect(urlString.contains("season=2024"))
        #expect(urlString.contains("group=hitting"))
        #expect(urlString.contains("stats=gameLog"))
    }

    @Test("Pitching group routes to pitching stats")
    func pitchingGroupRouting() throws {
        let json = """
        {"stats":[{"type":{"displayName":"gameLog"},"group":{"displayName":"pitching"},"splits":[
            {"season":"2024","stat":{"gamesPlayed":1,"wins":1,"losses":0,"era":"2.50","inningsPitched":"6.0",
             "strikeOuts":8,"baseOnBalls":2,"hits":4,"runs":2,"earnedRuns":2,"homeRunsAllowed":1},
             "player":{"id":660271,"fullName":"Shohei Ohtani"},
             "team":{"id":119,"name":"Los Angeles Dodgers"},
             "opponent":{"id":135,"name":"San Diego Padres"},
             "date":"2024-03-20","gameType":"R","isHome":true,"isWin":true,
             "game":{"gamePk":745444}}
        ]}]}
        """.data(using: .utf8)!
        let response = try JSONDecoder.mlb.decode(MLBGameLogResponse.self, from: json)
        let entries = MLBResponseConverters.gameLogEntries(from: response)

        let entry = try #require(entries.first)
        #expect(entry.group == .pitching)
        #expect(entry.batting == nil)
        #expect(entry.fielding == nil)
        #expect(entry.pitching != nil)
        #expect(entry.pitching?.wins == 1)
        #expect(entry.pitching?.strikeOuts == 8)
    }
}
