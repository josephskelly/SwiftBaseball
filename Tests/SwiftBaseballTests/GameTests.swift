import Testing
import Foundation
@testable import SwiftBaseball

@Suite("Game Tests")
struct GameTests {

    // MARK: - Boxscore

    @Test("Decode boxscore from fixture")
    func decodeBoxscore() throws {
        let data = try Fixtures.load("game_boxscore_745612.json")
        let response = try JSONDecoder.mlb.decode(MLBBoxscoreResponse.self, from: data)
        let boxscore = MLBResponseConverters.boxscore(from: response)

        #expect(boxscore.teams.away.team.id == 136)
        #expect(boxscore.teams.away.team.name == "Seattle Mariners")
        #expect(boxscore.teams.home.team.id == 133)
        #expect(boxscore.teams.home.team.name == "Oakland Athletics")
    }

    @Test("Boxscore team stats decode correctly")
    func boxscoreTeamStats() throws {
        let data = try Fixtures.load("game_boxscore_745612.json")
        let response = try JSONDecoder.mlb.decode(MLBBoxscoreResponse.self, from: data)
        let boxscore = MLBResponseConverters.boxscore(from: response)

        let awayBatting = boxscore.teams.away.teamStats.batting
        #expect(awayBatting.runs == 6)
        #expect(awayBatting.hits == 11)
        #expect(awayBatting.homeRuns == 3)
        #expect(awayBatting.strikeOuts == 8)
        #expect(awayBatting.baseOnBalls == 3)

        let awayPitching = boxscore.teams.away.teamStats.pitching
        #expect(awayPitching.strikeOuts == 11)
        #expect(awayPitching.earnedRuns == 4)

        let awayFielding = boxscore.teams.away.teamStats.fielding
        #expect(awayFielding.putOuts == 27)
        #expect(awayFielding.errors == 0)
    }

    @Test("Boxscore players decode with correct position")
    func boxscorePlayers() throws {
        let data = try Fixtures.load("game_boxscore_745612.json")
        let response = try JSONDecoder.mlb.decode(MLBBoxscoreResponse.self, from: data)
        let boxscore = MLBResponseConverters.boxscore(from: response)

        let awayPlayers = try #require(boxscore.teams.away.players)
        #expect(!awayPlayers.isEmpty)

        let robles = try #require(awayPlayers["ID645302"])
        #expect(robles.person.id == 645302)
        #expect(robles.person.fullName == "Victor Robles")
        #expect(robles.position == .leftField)
        #expect(robles.jerseyNumber == "10")
    }

    @Test("Boxscore officials decode correctly")
    func boxscoreOfficials() throws {
        let data = try Fixtures.load("game_boxscore_745612.json")
        let response = try JSONDecoder.mlb.decode(MLBBoxscoreResponse.self, from: data)
        let boxscore = MLBResponseConverters.boxscore(from: response)

        let officials = try #require(boxscore.officials)
        #expect(!officials.isEmpty)

        let firstOfficial = try #require(officials.first)
        #expect(firstOfficial.official.id == 429805)
        #expect(firstOfficial.official.fullName == "Todd Tichenor")
        #expect(firstOfficial.officialType == "Home Plate")
    }

    @Test("boxscore() query builder constructs correct path")
    func boxscoreQueryBuilder() async throws {
        let mock = MockAPIClient()
        let data = try Fixtures.load("game_boxscore_745612.json")
        mock.stub(path: "game/745612/boxscore", data: data)

        let builder = QueryBuilder<Boxscore>.boxscore(gamePk: 745612, client: mock)
        let boxscore = try await builder.fetch()

        #expect(mock.lastEndpoint?.path == "game/745612/boxscore")
        #expect(boxscore.teams.away.team.id == 136)
    }

    // MARK: - Linescore

    @Test("Decode linescore from fixture")
    func decodeLinescore() throws {
        let data = try Fixtures.load("game_linescore_745612.json")
        let linescore = try JSONDecoder.mlb.decode(Linescore.self, from: data)

        #expect(linescore.currentInning == 9)
        #expect(linescore.currentInningOrdinal == "9th")
        #expect(linescore.inningHalf == "Bottom")
        #expect(linescore.isTopInning == false)
        #expect(linescore.scheduledInnings == 9)
    }

    @Test("Linescore innings decode correctly")
    func linescoreInnings() throws {
        let data = try Fixtures.load("game_linescore_745612.json")
        let linescore = try JSONDecoder.mlb.decode(Linescore.self, from: data)

        #expect(linescore.innings.count == 9)

        let firstInning = try #require(linescore.innings.first)
        #expect(firstInning.num == 1)
        #expect(firstInning.ordinalNum == "1st")
        #expect(firstInning.away.runs == 2)
        #expect(firstInning.away.hits == 2)
        #expect(firstInning.home.runs == 0)
        #expect(firstInning.home.errors == 1)
    }

    @Test("Linescore team totals decode correctly")
    func linescoreTeamTotals() throws {
        let data = try Fixtures.load("game_linescore_745612.json")
        let linescore = try JSONDecoder.mlb.decode(Linescore.self, from: data)

        #expect(linescore.teams.away.runs == 6)
        #expect(linescore.teams.away.hits == 11)
        #expect(linescore.teams.away.errors == 0)
        #expect(linescore.teams.home.runs == 4)
        #expect(linescore.teams.home.hits == 10)
        #expect(linescore.teams.home.errors == 2)
    }

    @Test("Linescore defense players decode correctly")
    func linescoreDefense() throws {
        let data = try Fixtures.load("game_linescore_745612.json")
        let linescore = try JSONDecoder.mlb.decode(Linescore.self, from: data)

        let defense = try #require(linescore.defense)
        let pitcher = try #require(defense.pitcher)
        #expect(pitcher.id == 662253)
        #expect(pitcher.fullName == "Andrés Muñoz")
    }

    @Test("linescore() query builder constructs correct path")
    func linescoreQueryBuilder() async throws {
        let mock = MockAPIClient()
        let data = try Fixtures.load("game_linescore_745612.json")
        mock.stub(path: "game/745612/linescore", data: data)

        let builder = QueryBuilder<Linescore>.linescore(gamePk: 745612, client: mock)
        let linescore = try await builder.fetch()

        #expect(mock.lastEndpoint?.path == "game/745612/linescore")
        #expect(linescore.currentInning == 9)
        #expect(linescore.teams.away.runs == 6)
    }

    @Test("Linescore inning runs sum to team totals")
    func linescoreInningsSumToTotals() throws {
        let data = try Fixtures.load("game_linescore_745612.json")
        let linescore = try JSONDecoder.mlb.decode(Linescore.self, from: data)

        let awayRuns = linescore.innings.compactMap(\.away.runs).reduce(0, +)
        let homeRuns = linescore.innings.compactMap(\.home.runs).reduce(0, +)

        #expect(awayRuns == linescore.teams.away.runs)
        #expect(homeRuns == linescore.teams.home.runs)
    }
}
