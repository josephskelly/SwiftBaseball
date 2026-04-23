import Foundation
@testable import SwiftBaseball
import Testing

@Suite("Sport Catalog Tests")
struct SportCatalogTests {
    private func loadSports() throws -> [SportCatalog] {
        let data = try Fixtures.load("sports.json")
        let response = try JSONDecoder.mlb.decode(MLBSportsResponse.self, from: data)
        return MLBResponseConverters.sports(from: response)
    }

    @Test("Catalog decodes into SportCatalog entries")
    func decodesAllEntries() throws {
        let sports = try loadSports()
        #expect(sports.count == 20)
    }

    @Test("MLB entry carries the expected fields")
    func mlbEntry() throws {
        let sports = try loadSports()
        let mlb = try #require(sports.first { $0.id == 1 })

        #expect(mlb.code == "mlb")
        #expect(mlb.name == "Major League Baseball")
        #expect(mlb.abbreviation == "MLB")
        #expect(mlb.active == true)
    }

    @Test("Minor league IDs align with the Sport query enum")
    func alignsWithSportEnum() throws {
        let sports = try loadSports()
        let tripleA = try #require(sports.first { $0.id == Sport.tripleA.rawValue })
        #expect(tripleA.abbreviation == "AAA")
    }

    @Test("Missing activeStatus defaults to false")
    func missingActiveDefaultsToFalse() throws {
        let json = #"""
        {"sports":[{"id":999,"name":"Experimental League","sortOrder":99}]}
        """#
        let data = Data(json.utf8)
        let response = try JSONDecoder.mlb.decode(MLBSportsResponse.self, from: data)
        let sport = try #require(MLBResponseConverters.sports(from: response).first)
        #expect(sport.active == false)
        #expect(sport.code == nil)
        #expect(sport.abbreviation == nil)
    }

    @Test("Endpoint URL targets /sports")
    func endpointURL() throws {
        let endpoint = Endpoint(path: "sports")
        let baseURL = try #require(URL(string: "https://statsapi.mlb.com/api/v1/"))
        let built = try #require(endpoint.url(baseURL: baseURL))
        #expect(built.absoluteString == "https://statsapi.mlb.com/api/v1/sports")
    }
}
