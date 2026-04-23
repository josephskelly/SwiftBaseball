import Foundation
@testable import SwiftBaseball
import Testing

@Suite("Division Catalog Tests")
struct DivisionCatalogTests {
    private func loadDivisions() throws -> [DivisionCatalog] {
        let data = try Fixtures.load("divisions_sport_1.json")
        let response = try JSONDecoder.mlb.decode(MLBDivisionsResponse.self, from: data)
        return MLBResponseConverters.divisions(from: response)
    }

    @Test("Catalog decodes into six MLB divisions")
    func decodesAllEntries() throws {
        let divisions = try loadDivisions()
        #expect(divisions.count == 6)
    }

    @Test("AL West carries core fields and league ID")
    func alWestCoreFields() throws {
        let divisions = try loadDivisions()
        let alWest = try #require(divisions.first { $0.id == 200 })

        #expect(alWest.name == "American League West")
        #expect(alWest.nameShort == "AL West")
        #expect(alWest.abbreviation == "ALW")
        #expect(alWest.leagueId == 103)
        #expect(alWest.sportId == 1)
        #expect(alWest.active == true)
        #expect(alWest.numPlayoffTeams == 1)
        #expect(alWest.hasWildcard == false)
    }

    @Test("All six MLB divisions resolve to a league ID")
    func allDivisionsHaveLeague() throws {
        let divisions = try loadDivisions()
        #expect(divisions.allSatisfy { $0.leagueId == 103 || $0.leagueId == 104 })
    }

    @Test("Missing optional fields stay nil and active defaults to false")
    func missingFieldsStayNil() throws {
        let json = #"""
        {"divisions":[{"id":999,"name":"Experimental Division"}]}
        """#
        let data = Data(json.utf8)
        let response = try JSONDecoder.mlb.decode(MLBDivisionsResponse.self, from: data)
        let division = try #require(MLBResponseConverters.divisions(from: response).first)

        #expect(division.leagueId == nil)
        #expect(division.sportId == nil)
        #expect(division.nameShort == nil)
        #expect(division.numPlayoffTeams == nil)
        #expect(division.active == false)
    }

    @Test("Endpoint URL targets /divisions with sportId")
    func endpointURL() throws {
        let endpoint = Endpoint(path: "divisions", queryItems: [
            URLQueryItem(name: "sportId", value: "1")
        ])
        let baseURL = try #require(URL(string: "https://statsapi.mlb.com/api/v1/"))
        let built = try #require(endpoint.url(baseURL: baseURL))
        #expect(built.absoluteString == "https://statsapi.mlb.com/api/v1/divisions?sportId=1")
    }

    @Test("Endpoint URL omits sportId when unset")
    func endpointURLUnscoped() throws {
        let endpoint = Endpoint(path: "divisions")
        let baseURL = try #require(URL(string: "https://statsapi.mlb.com/api/v1/"))
        let built = try #require(endpoint.url(baseURL: baseURL))
        #expect(built.absoluteString == "https://statsapi.mlb.com/api/v1/divisions")
    }
}
