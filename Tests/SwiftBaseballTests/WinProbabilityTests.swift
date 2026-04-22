import Foundation
@testable import SwiftBaseball
import Testing

@Suite("WinProbability Tests")
struct WinProbabilityTests {
    private func loadPlays() throws -> [PlayWinProbability] {
        let data = try Fixtures.load("win_probability_745612.json")
        let response = try JSONDecoder.mlb.decode([MLBWinProbabilityPlay].self, from: data)
        return MLBResponseConverters.winProbability(from: response)
    }

    @Test("Decodes all plays in the fixture")
    func decodesPlayCount() throws {
        let plays = try loadPlays()
        #expect(plays.count == 11)
    }

    @Test("First play carries WP and WPA values")
    func firstPlayProbabilityValues() throws {
        let plays = try loadPlays()
        let first = try #require(plays.first)

        #expect(first.atBatIndex == 0)
        #expect(abs(first.homeTeamWinProbability - 46.4) < 0.0001)
        #expect(abs(first.awayTeamWinProbability - 53.6) < 0.0001)
        #expect(abs(first.homeTeamWinProbabilityAdded - -3.6) < 0.0001)
    }

    @Test("Home and away win probabilities sum to ~100")
    func winProbabilitiesSumToOneHundred() throws {
        let plays = try loadPlays()
        for play in plays {
            let total = play.homeTeamWinProbability + play.awayTeamWinProbability
            #expect(abs(total - 100.0) < 0.001)
        }
    }

    @Test("Final play reflects final-state win probability")
    func finalPlayWinProbability() throws {
        let plays = try loadPlays()
        let last = try #require(plays.last)

        #expect(last.atBatIndex == 81)
        #expect(last.homeTeamWinProbability == 0.0)
        #expect(last.awayTeamWinProbability == 100.0)
        #expect(last.result.event == "Strikeout")
        #expect(last.about.inning == 9)
        #expect(last.about.halfInning == "bottom")
    }

    @Test("Play result and about carry reused Play fields")
    func reusesPlayShape() throws {
        let plays = try loadPlays()
        let first = try #require(plays.first)

        #expect(first.result.event == "Hit By Pitch")
        #expect(first.result.eventType == "hit_by_pitch")
        #expect(first.result.rbi == 0)
        #expect(first.about.inning == 1)
        #expect(first.about.halfInning == "top")
        #expect(first.about.isComplete)
    }

    @Test("Matchup carries batter, pitcher, and hand sides")
    func matchupDecodes() throws {
        let plays = try loadPlays()
        let first = try #require(plays.first)

        #expect(first.matchup.batter.id == 645_302)
        #expect(first.matchup.batter.fullName == "Victor Robles")
        #expect(first.matchup.pitcher.id == 683_155)
        #expect(first.matchup.pitcher.fullName == "Joey Estes")
        #expect(first.matchup.batSide == .right)
        #expect(first.matchup.pitchHand == .right)
    }

    @Test("atBatIndex comes from top-level when present")
    func atBatIndexTopLevel() throws {
        let plays = try loadPlays()
        // atBatIndex should be monotonically non-decreasing for a sequence of at-bats
        for (lhs, rhs) in zip(plays, plays.dropFirst()) {
            #expect(rhs.atBatIndex >= lhs.atBatIndex)
        }
    }

    @Test("Empty array decodes to empty plays")
    func emptyArrayDecodes() throws {
        let empty = Data("[]".utf8)
        let response = try JSONDecoder.mlb.decode([MLBWinProbabilityPlay].self, from: empty)
        let plays = MLBResponseConverters.winProbability(from: response)
        #expect(plays.isEmpty)
    }

    @Test("Endpoint URL targets /game/{pk}/winProbability")
    func endpointURL() throws {
        let endpoint = Endpoint(path: "game/745612/winProbability")
        let baseURL = try #require(URL(string: "https://statsapi.mlb.com/api/v1/"))
        let built = try #require(endpoint.url(baseURL: baseURL))
        #expect(built.absoluteString == "https://statsapi.mlb.com/api/v1/game/745612/winProbability")
    }
}
