import Testing
import Foundation
@testable import SwiftBaseball

@Suite("Play-by-Play Tests")
struct PlayByPlayTests {

    @Test("Decode play-by-play from fixture")
    func decodeFromFixture() throws {
        let data = try Fixtures.load("play_by_play_745612.json")
        let response = try JSONDecoder.mlb.decode(MLBPlayByPlayResponse.self, from: data)
        let pbp = MLBResponseConverters.playByPlay(from: response)

        #expect(pbp.allPlays.count == 3)
        #expect(pbp.scoringPlays == [1])
    }

    @Test("First play result fields")
    func firstPlayResult() throws {
        let data = try Fixtures.load("play_by_play_745612.json")
        let response = try JSONDecoder.mlb.decode(MLBPlayByPlayResponse.self, from: data)
        let pbp = MLBResponseConverters.playByPlay(from: response)

        let first = try #require(pbp.allPlays.first)
        #expect(first.result.event == "Single")
        #expect(first.result.eventType == "single")
        #expect(first.result.rbi == 0)
        #expect(first.result.description?.contains("Mookie Betts") == true)
    }

    @Test("Play about fields")
    func playAbout() throws {
        let data = try Fixtures.load("play_by_play_745612.json")
        let response = try JSONDecoder.mlb.decode(MLBPlayByPlayResponse.self, from: data)
        let pbp = MLBResponseConverters.playByPlay(from: response)

        let first = try #require(pbp.allPlays.first)
        #expect(first.about.atBatIndex == 0)
        #expect(first.about.halfInning == "top")
        #expect(first.about.inning == 1)
        #expect(first.about.isComplete == true)
        #expect(first.about.isScoringPlay == false)
        #expect(first.about.hasOut == false)
    }

    @Test("Matchup batter and pitcher references")
    func matchup() throws {
        let data = try Fixtures.load("play_by_play_745612.json")
        let response = try JSONDecoder.mlb.decode(MLBPlayByPlayResponse.self, from: data)
        let pbp = MLBResponseConverters.playByPlay(from: response)

        let second = pbp.allPlays[1]
        #expect(second.matchup.batter.id == 660271)
        #expect(second.matchup.batter.fullName == "Shohei Ohtani")
        #expect(second.matchup.batSide == .left)
        #expect(second.matchup.pitcher.id == 543037)
        #expect(second.matchup.pitcher.fullName == "Gerrit Cole")
        #expect(second.matchup.pitchHand == .right)
    }

    @Test("Pitch data values")
    func pitchData() throws {
        let data = try Fixtures.load("play_by_play_745612.json")
        let response = try JSONDecoder.mlb.decode(MLBPlayByPlayResponse.self, from: data)
        let pbp = MLBResponseConverters.playByPlay(from: response)

        let firstEvent = try #require(pbp.allPlays.first?.playEvents?.first)
        let pitch = try #require(firstEvent.pitchData)
        #expect(abs((pitch.startSpeed ?? 0) - 96.3) < 0.1)
        #expect(abs((pitch.endSpeed ?? 0) - 88.1) < 0.1)
        #expect(pitch.zone == 14)
    }

    @Test("Runner movement")
    func runnerMovement() throws {
        let data = try Fixtures.load("play_by_play_745612.json")
        let response = try JSONDecoder.mlb.decode(MLBPlayByPlayResponse.self, from: data)
        let pbp = MLBResponseConverters.playByPlay(from: response)

        // Home run play — Betts scores from 1B
        let hrPlay = pbp.allPlays[1]
        let runners = try #require(hrPlay.runners)
        #expect(runners.count == 2)

        let bettsRunner = try #require(runners.first)
        #expect(bettsRunner.movement?.start == "1B")
        #expect(bettsRunner.movement?.end == "score")
        #expect(bettsRunner.movement?.isOut == false)
        #expect(bettsRunner.details?.runner?.id == 605141)
    }

    @Test("Empty plays produce PlayByPlay with empty array")
    func emptyPlays() throws {
        let json = """
        {"allPlays":[],"scoringPlays":[]}
        """.data(using: .utf8)!
        let response = try JSONDecoder.mlb.decode(MLBPlayByPlayResponse.self, from: json)
        let pbp = MLBResponseConverters.playByPlay(from: response)

        #expect(pbp.allPlays.isEmpty)
        #expect(pbp.scoringPlays?.isEmpty == true)
    }

    @Test("Query builder path is correct")
    func queryBuilderPath() throws {
        let baseURL = URL(string: "https://statsapi.mlb.com/api/v1/")!
        let mock = MockAPIClient()
        let builder = QueryBuilder<PlayByPlay>.playByPlay(gamePk: 745612, client: mock)

        #expect(builder.endpoint.path == "game/745612/playByPlay")
        let url = try #require(builder.endpoint.url(baseURL: baseURL))
        #expect(url.absoluteString.contains("game/745612/playByPlay"))
    }
}
