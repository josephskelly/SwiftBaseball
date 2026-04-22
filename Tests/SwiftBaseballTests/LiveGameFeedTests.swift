import Foundation
@testable import SwiftBaseball
import Testing

@Suite("LiveGameFeed Tests")
struct LiveGameFeedTests {
    private func loadFeed() throws -> LiveGameFeed {
        let data = try Fixtures.load("live_game_feed_745612.json")
        let response = try JSONDecoder.mlb.decode(MLBLiveGameFeedResponse.self, from: data)
        return MLBResponseConverters.liveGameFeed(from: response)
    }

    // MARK: - Root + meta

    @Test("Game primary key decodes")
    func gamePkDecodes() throws {
        let feed = try loadFeed()
        #expect(feed.gamePk == 745_612)
    }

    @Test("Meta polling interval decodes")
    func metaWaitInterval() throws {
        let feed = try loadFeed()
        #expect(feed.meta.wait == 10)
        #expect(feed.meta.timeStamp == "20240905_222835")
    }

    @Test("Meta event lists decode")
    func metaEventLists() throws {
        let feed = try loadFeed()
        #expect(feed.meta.gameEvents.contains("strikeout"))
        #expect(feed.meta.logicalEvents.contains("midInning"))
    }

    // MARK: - Status + game info

    @Test("Abstract game state is final")
    func abstractGameStateIsFinal() throws {
        let feed = try loadFeed()
        #expect(feed.gameData.status.abstractGameState == .final)
        #expect(feed.gameData.status.detailedState == "Final")
        #expect(feed.gameData.status.codedGameState == "F")
    }

    @Test("Game info decodes type, season, doubleHeader")
    func gameInfoDecodes() throws {
        let feed = try loadFeed()
        #expect(feed.gameData.game.pk == 745_612)
        #expect(feed.gameData.game.type == .regularSeason)
        #expect(feed.gameData.game.season == "2024")
        #expect(feed.gameData.game.doubleHeader == "N")
    }

    @Test("Datetime decodes day/night, time, dates")
    func datetimeDecodes() throws {
        let feed = try loadFeed()
        #expect(feed.gameData.datetime.dayNight == .day)
        #expect(feed.gameData.datetime.time == "12:37")
        #expect(feed.gameData.datetime.ampm == "PM")
        #expect(feed.gameData.datetime.originalDate != nil)
        #expect(feed.gameData.datetime.dateTime != nil)
    }

    // MARK: - Teams + score lifted from linescore

    @Test("Teams decode with references and records")
    func teamsDecode() throws {
        let feed = try loadFeed()
        #expect(feed.gameData.teams.away.team.id == 136)
        #expect(feed.gameData.teams.away.team.name == "Seattle Mariners")
        #expect(feed.gameData.teams.home.team.id == 133)
        #expect(feed.gameData.teams.away.leagueRecord.wins == 71)
        #expect(feed.gameData.teams.away.leagueRecord.losses == 70)
        #expect(feed.gameData.teams.away.leagueRecord.pct == ".504")
    }

    @Test("Per-team score is lifted from linescore")
    func scoreLiftedFromLinescore() throws {
        let feed = try loadFeed()
        #expect(feed.gameData.teams.away.score == 6)
        #expect(feed.gameData.teams.home.score == 4)
    }

    // MARK: - Players

    @Test("Player dictionary strips ID prefix from keys")
    func playerDictionaryKeyStripping() throws {
        let feed = try loadFeed()
        #expect(feed.gameData.players[671_732] != nil)
        let butler = try #require(feed.gameData.players[671_732])
        #expect(butler.fullName == "Lawrence Butler")
        #expect(butler.primaryPosition == .rightField)
        #expect(butler.batSide == .left)
        #expect(butler.pitchHand == .right)
    }

    // MARK: - Weather / flags / probables / venue

    @Test("Weather decodes")
    func weatherDecodes() throws {
        let feed = try loadFeed()
        let weather = try #require(feed.gameData.weather)
        #expect(weather.condition == "Sunny")
        #expect(weather.temp == "76")
        #expect(weather.wind.contains("mph"))
    }

    @Test("Flags default to false for a non-no-hitter")
    func flagsNoHitterFalse() throws {
        let feed = try loadFeed()
        #expect(feed.gameData.flags.noHitter == false)
        #expect(feed.gameData.flags.perfectGame == false)
    }

    @Test("Probable pitchers decode")
    func probablePitchersDecode() throws {
        let feed = try loadFeed()
        #expect(feed.gameData.probablePitchers.away?.fullName == "Bryan Woo")
        #expect(feed.gameData.probablePitchers.home?.fullName == "Joey Estes")
    }

    @Test("Venue reference decodes")
    func venueDecodes() throws {
        let feed = try loadFeed()
        #expect(feed.gameData.venue.id > 0)
        #expect(feed.gameData.venue.name.isEmpty == false)
    }

    // MARK: - Plays

    @Test("All plays count matches fixture")
    func allPlaysCount() throws {
        let feed = try loadFeed()
        #expect(feed.liveData.plays.allPlays.count == 2)
    }

    @Test("Current play decodes with result")
    func currentPlayDecodes() throws {
        let feed = try loadFeed()
        let current = try #require(feed.liveData.plays.currentPlay)
        #expect(current.result.event != nil)
    }

    @Test("Scoring play indices decode")
    func scoringPlaysIndices() throws {
        let feed = try loadFeed()
        #expect(feed.liveData.plays.scoringPlays == [2, 18, 26])
    }

    @Test("Plays-by-inning carry inning number and half splits")
    func playsByInningDecodes() throws {
        let feed = try loadFeed()
        let firstInning = try #require(feed.liveData.plays.playsByInning.first)
        #expect(firstInning.inning == 1)
        #expect(firstInning.top.isEmpty == false)
        #expect(firstInning.bottom.isEmpty == false)
    }

    // MARK: - Linescore + boxscore reuse

    @Test("Linescore reuses existing model")
    func linescoreReusedModel() throws {
        let feed = try loadFeed()
        #expect(feed.liveData.linescore.teams.home.runs == 4)
        #expect(feed.liveData.linescore.teams.away.runs == 6)
    }

    @Test("Boxscore reuses existing model")
    func boxscoreReusedModel() throws {
        let feed = try loadFeed()
        #expect(feed.liveData.boxscore.teams.home.team.id == 133)
        #expect(feed.liveData.boxscore.teams.away.team.id == 136)
    }

    // MARK: - Decisions

    @Test("Decisions decode winner and loser")
    func decisionsDecode() throws {
        let feed = try loadFeed()
        let decisions = try #require(feed.liveData.decisions)
        #expect(decisions.winner?.fullName == "Bryan Woo")
        #expect(decisions.loser?.fullName == "Joey Estes")
    }

    // MARK: - Endpoint URL wiring

    @Test("Query builder uses v1.1 version path")
    func queryBuilderUsesV1_1Path() throws {
        let endpoint = Endpoint(path: "game/745612/feed/live", version: "v1.1")
        let baseURL = try #require(URL(string: "https://statsapi.mlb.com/api/v1/"))
        let built = try #require(endpoint.url(baseURL: baseURL))
        #expect(built.absoluteString.contains("/api/v1.1/"))
        #expect(built.absoluteString.contains("game/745612/feed/live"))
    }

    @Test("Default v1 endpoints leave base URL untouched")
    func defaultVersionLeavesBaseURLUntouched() throws {
        let endpoint = Endpoint(path: "people/660271")
        let baseURL = try #require(URL(string: "https://statsapi.mlb.com/api/v1/"))
        let built = try #require(endpoint.url(baseURL: baseURL))
        #expect(built.absoluteString == "https://statsapi.mlb.com/api/v1/people/660271")
    }
}
