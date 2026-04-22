import Foundation
@testable import SwiftBaseball
import Testing

@Suite("Game Pace Tests")
struct GamePaceTests {
    private func loadTeam() throws -> GamePace {
        let data = try Fixtures.load("game_pace_147_2024.json")
        let response = try JSONDecoder.mlb.decode(MLBGamePaceResponse.self, from: data)
        return try #require(MLBResponseConverters.teamGamePace(from: response))
    }

    private func loadLeague() throws -> GamePace {
        let data = try Fixtures.load("game_pace_league_2024.json")
        let response = try JSONDecoder.mlb.decode(MLBGamePaceResponse.self, from: data)
        return try #require(MLBResponseConverters.leagueGamePace(from: response))
    }

    @Test("Team record carries team, league, and sport references")
    func teamRefs() throws {
        let pace = try loadTeam()
        #expect(pace.season == "2024")
        #expect(pace.team?.id == 147)
        #expect(pace.team?.name == "NY Yankees")
        #expect(pace.league?.id == 103)
        #expect(pace.league?.name == "American League")
        #expect(pace.sportId == 1)
    }

    @Test("Per-game rates decode as doubles")
    func perGameRates() throws {
        let pace = try loadTeam()
        #expect(pace.pitchesPerGame == 307.67)
        #expect(pace.pitchersPerGame == 8.8)
        #expect(pace.runsPerGame == 9.21)
        #expect(pace.hitsPerRun == 1.725)
    }

    @Test("Game counts decode as ints")
    func gameCounts() throws {
        let pace = try loadTeam()
        #expect(pace.totalGames == 81)
        #expect(pace.total9InnGames == 72)
        #expect(pace.totalExtraInnGames == 8)
        #expect(pace.total7InnGames == 1)
    }

    @Test("Time-per-game parses H:MM:SS to seconds")
    func timePerGame() throws {
        let pace = try loadTeam()
        // "02:49:33" -> 2h 49m 33s = 10173s
        #expect(pace.timePerGame == 10_173)
        // "00:00:33" -> 33s
        #expect(pace.timePerPitch == 33)
    }

    @Test("Durations over 24 hours parse correctly")
    func longDuration() throws {
        let pace = try loadTeam()
        // "228:54:00" -> 228h 54m = 824040s
        #expect(pace.totalGameTime == 824_040)
    }

    @Test("Portal calculated fields surface on the public model")
    func portalFields() throws {
        let pace = try loadTeam()
        // "02:46:45" -> 10005s
        #expect(pace.timePer9InnGame == 10_005)
        #expect(pace.timePer7InnGame != nil)
        #expect(pace.timePerExtraInnGame != nil)
    }

    @Test("League-wide record has no team or league ref but carries sport")
    func leagueRecord() throws {
        let pace = try loadLeague()
        #expect(pace.team == nil)
        #expect(pace.league == nil)
        #expect(pace.sportId == 1)
        #expect(pace.totalGames == 2429)
    }

    @Test("Team converter returns nil when teams[] is empty")
    func emptyTeams() throws {
        let json = #"{"teams":[],"leagues":[],"sports":[]}"#
        let data = Data(json.utf8)
        let response = try JSONDecoder.mlb.decode(MLBGamePaceResponse.self, from: data)
        #expect(MLBResponseConverters.teamGamePace(from: response) == nil)
        #expect(MLBResponseConverters.leagueGamePace(from: response) == nil)
    }

    @Test("Malformed duration strings decode to nil")
    func malformedDuration() throws {
        let json = #"""
        {"teams":[{"season":"2024","team":{"id":1,"name":"X"},"timePerGame":"nonsense"}],"leagues":[],"sports":[]}
        """#
        let data = Data(json.utf8)
        let response = try JSONDecoder.mlb.decode(MLBGamePaceResponse.self, from: data)
        let pace = try #require(MLBResponseConverters.teamGamePace(from: response))
        #expect(pace.timePerGame == nil)
    }

    @Test("Team endpoint URL carries teamIds and season")
    func teamEndpointURL() throws {
        let endpoint = Endpoint(path: "gamePace", queryItems: [
            URLQueryItem(name: "teamIds", value: "147"),
            URLQueryItem(name: "season", value: "2024")
        ])
        let baseURL = try #require(URL(string: "https://statsapi.mlb.com/api/v1/"))
        let built = try #require(endpoint.url(baseURL: baseURL))
        #expect(built.absoluteString == "https://statsapi.mlb.com/api/v1/gamePace?teamIds=147&season=2024")
    }

    @Test("League endpoint URL carries sportId and season")
    func leagueEndpointURL() throws {
        let endpoint = Endpoint(path: "gamePace", queryItems: [
            URLQueryItem(name: "sportId", value: "1"),
            URLQueryItem(name: "season", value: "2024")
        ])
        let baseURL = try #require(URL(string: "https://statsapi.mlb.com/api/v1/"))
        let built = try #require(endpoint.url(baseURL: baseURL))
        #expect(built.absoluteString == "https://statsapi.mlb.com/api/v1/gamePace?sportId=1&season=2024")
    }
}
