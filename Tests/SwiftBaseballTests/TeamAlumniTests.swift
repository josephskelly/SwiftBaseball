import Foundation
@testable import SwiftBaseball
import Testing

@Suite("TeamAlumni Tests")
struct TeamAlumniTests {
    private func loadAlumni() throws -> [Player] {
        let data = try Fixtures.load("team_alumni_147_2024.json")
        let response = try JSONDecoder.mlb.decode(MLBPeopleResponse.self, from: data)
        return response.people.map(MLBResponseConverters.player)
    }

    @Test("Decodes all alumni from fixture")
    func alumniCount() throws {
        let alumni = try loadAlumni()
        #expect(alumni.count == 5)
    }

    @Test("alumniLastSeason is populated on every alumnus")
    func alumniLastSeasonPresent() throws {
        let alumni = try loadAlumni()
        for player in alumni {
            #expect(player.alumniLastSeason != nil)
        }
    }

    @Test("alumniLastSeason is a four-character year string")
    func alumniLastSeasonFormat() throws {
        let alumni = try loadAlumni()
        for player in alumni {
            let season = try #require(player.alumniLastSeason)
            #expect(season.count == 4)
            #expect(Int(season) != nil)
        }
    }

    @Test("Player fields carry over from standard Player payload")
    func playerFieldsReused() throws {
        let alumni = try loadAlumni()
        let andujar = try #require(alumni.first { $0.id == 609_280 })

        #expect(andujar.fullName == "Miguel Andujar")
        #expect(andujar.primaryNumber == "41")
        #expect(andujar.birthCountry == "Dominican Republic")
        #expect(andujar.alumniLastSeason == "2022")
    }

    @Test("alumniLastSeason is nil for non-alumni Player queries")
    func alumniLastSeasonNilForStandardPlayer() throws {
        // Decode a standard people response (no alumni field) and verify nil.
        let json = #"""
        {
          "people": [
            {
              "id": 1,
              "fullName": "Test Player",
              "firstName": "Test",
              "lastName": "Player"
            }
          ]
        }
        """#
        let data = Data(json.utf8)
        let response = try JSONDecoder.mlb.decode(MLBPeopleResponse.self, from: data)
        let player = try #require(response.people.first.map(MLBResponseConverters.player))
        #expect(player.alumniLastSeason == nil)
    }

    @Test("Endpoint URL targets /teams/{id}/alumni with required season")
    func endpointURL() throws {
        let endpoint = Endpoint(path: "teams/147/alumni", queryItems: [
            URLQueryItem(name: "season", value: "2024")
        ])
        let baseURL = try #require(URL(string: "https://statsapi.mlb.com/api/v1/"))
        let built = try #require(endpoint.url(baseURL: baseURL))
        #expect(built.absoluteString.contains("/teams/147/alumni"))
        #expect(built.absoluteString.contains("season=2024"))
    }
}
