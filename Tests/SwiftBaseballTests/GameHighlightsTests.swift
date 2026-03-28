import Testing
import Foundation
@testable import SwiftBaseball

@Suite("Game Highlights Tests")
struct GameHighlightsTests {

    // MARK: - Decoding

    @Test("Decode game highlights from fixture")
    func decodeGameHighlights() throws {
        let data = try Fixtures.load("game_highlights_745612.json")
        let response = try JSONDecoder.mlb.decode(MLBGameContentResponse.self, from: data)
        let highlights = MLBResponseConverters.gameHighlights(from: response)

        #expect(highlights.highlights.count == 2)
        #expect(highlights.scoreboardHighlights.count == 1)
    }

    @Test("Highlight fields decoded correctly")
    func highlightFields() throws {
        let data = try Fixtures.load("game_highlights_745612.json")
        let response = try JSONDecoder.mlb.decode(MLBGameContentResponse.self, from: data)
        let highlight = try #require(MLBResponseConverters.gameHighlights(from: response).highlights.first)

        #expect(highlight.id == "2024-07-04-ohtani-hr")
        #expect(highlight.title == "Ohtani's 30th home run")
        #expect(highlight.headline == "Shohei Ohtani crushes his 30th home run of the season")
        #expect(highlight.blurb?.isEmpty == false)
        #expect(highlight.duration == "00:01:05")
    }

    @Test("Highlight date parsed to non-nil Date")
    func highlightDate() throws {
        let data = try Fixtures.load("game_highlights_745612.json")
        let response = try JSONDecoder.mlb.decode(MLBGameContentResponse.self, from: data)
        let highlight = try #require(MLBResponseConverters.gameHighlights(from: response).highlights.first)

        let date = try #require(highlight.date)
        // 2024-07-04T23:15:00Z → year 2024
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "UTC")!
        #expect(cal.component(.year, from: date) == 2024)
        #expect(cal.component(.month, from: date) == 7)
        #expect(cal.component(.day, from: date) == 4)
    }

    @Test("Video playback URL decoded correctly")
    func videoPlaybackURL() throws {
        let data = try Fixtures.load("game_highlights_745612.json")
        let response = try JSONDecoder.mlb.decode(MLBGameContentResponse.self, from: data)
        let highlight = try #require(MLBResponseConverters.gameHighlights(from: response).highlights.first)
        let playback = try #require(highlight.playbacks.first)

        #expect(playback.name == "mp4Avc")
        #expect(playback.url != nil)
        #expect(playback.url?.scheme == "https")
    }

    @Test("Video playback width and height converted from string to Int")
    func videoPlaybackDimensions() throws {
        let data = try Fixtures.load("game_highlights_745612.json")
        let response = try JSONDecoder.mlb.decode(MLBGameContentResponse.self, from: data)
        let highlight = try #require(MLBResponseConverters.gameHighlights(from: response).highlights.first)
        let playback = try #require(highlight.playbacks.first)

        #expect(playback.width == 1280)
        #expect(playback.height == 720)
    }

    @Test("Image cuts decoded with dimensions")
    func imageCuts() throws {
        let data = try Fixtures.load("game_highlights_745612.json")
        let response = try JSONDecoder.mlb.decode(MLBGameContentResponse.self, from: data)
        let highlight = try #require(MLBResponseConverters.gameHighlights(from: response).highlights.first)
        let image = try #require(highlight.image)

        #expect(image.cuts.count == 2)
        #expect(image.cuts[0].width == 1280)
        #expect(image.cuts[0].height == 720)
        #expect(image.cuts[0].aspectRatio == "16:9")
        #expect(image.cuts[0].src != nil)
        #expect(image.cuts[1].width == 640)
        #expect(image.cuts[1].height == 360)
    }

    @Test("Scoreboard highlight decoded correctly")
    func scoreboardHighlight() throws {
        let data = try Fixtures.load("game_highlights_745612.json")
        let response = try JSONDecoder.mlb.decode(MLBGameContentResponse.self, from: data)
        let scoreboard = try #require(MLBResponseConverters.gameHighlights(from: response).scoreboardHighlights.first)

        #expect(scoreboard.id == "2024-07-04-condensed")
        #expect(scoreboard.duration == "00:08:30")
        #expect(scoreboard.playbacks.count == 1)
    }

    // MARK: - Query Builder

    @Test("Query builder constructs correct path")
    func queryBuilderPath() async throws {
        let mock = MockAPIClient()
        let data = try Fixtures.load("game_highlights_745612.json")
        mock.stub(path: "game/745612/content", data: data)

        let builder = QueryBuilder<GameHighlights>.gameHighlights(gamePk: 745612, client: mock)
        _ = try await builder.fetch()

        let endpoint = try #require(mock.lastEndpoint)
        #expect(endpoint.path == "game/745612/content")
    }

    @Test("Query builder uses correct gamePk in path")
    func queryBuilderGamePk() async throws {
        let mock = MockAPIClient()
        let data = try Fixtures.load("game_highlights_745612.json")
        mock.stub(path: "game/99999/content", data: data)

        let builder = QueryBuilder<GameHighlights>.gameHighlights(gamePk: 99999, client: mock)
        _ = try await builder.fetch()

        let endpoint = try #require(mock.lastEndpoint)
        #expect(endpoint.path == "game/99999/content")
    }

    // MARK: - Edge Cases

    @Test("Empty items arrays produce empty highlights")
    func emptyHighlights() throws {
        let json = """
        {
          "highlights": {
            "gameCenter": { "items": [] },
            "scoreboard": { "items": [] }
          }
        }
        """.data(using: .utf8)!
        let response = try JSONDecoder.mlb.decode(MLBGameContentResponse.self, from: json)
        let highlights = MLBResponseConverters.gameHighlights(from: response)

        #expect(highlights.highlights.isEmpty)
        #expect(highlights.scoreboardHighlights.isEmpty)
    }

    @Test("Missing highlights section produces empty arrays")
    func missingHighlightsSection() throws {
        let json = "{}".data(using: .utf8)!
        let response = try JSONDecoder.mlb.decode(MLBGameContentResponse.self, from: json)
        let highlights = MLBResponseConverters.gameHighlights(from: response)

        #expect(highlights.highlights.isEmpty)
        #expect(highlights.scoreboardHighlights.isEmpty)
    }

    @Test("Highlight with missing id is dropped")
    func highlightMissingIdDropped() throws {
        let json = """
        {
          "highlights": {
            "gameCenter": {
              "items": [
                { "title": "No id clip" }
              ]
            },
            "scoreboard": { "items": [] }
          }
        }
        """.data(using: .utf8)!
        let response = try JSONDecoder.mlb.decode(MLBGameContentResponse.self, from: json)
        let highlights = MLBResponseConverters.gameHighlights(from: response)

        #expect(highlights.highlights.isEmpty)
    }
}
