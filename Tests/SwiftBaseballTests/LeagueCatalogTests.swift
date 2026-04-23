import Foundation
@testable import SwiftBaseball
import Testing

@Suite("League Catalog Tests")
struct LeagueCatalogTests {
    private func loadLeagues() throws -> [LeagueCatalog] {
        let data = try Fixtures.load("leagues_sport_1.json")
        let response = try JSONDecoder.mlb.decode(MLBLeaguesResponse.self, from: data)
        return MLBResponseConverters.leagues(from: response)
    }

    @Test("Catalog decodes into LeagueCatalog entries")
    func decodesAllEntries() throws {
        let leagues = try loadLeagues()
        #expect(leagues.count == 15)
    }

    @Test("American League carries core fields")
    func americanLeagueCoreFields() throws {
        let leagues = try loadLeagues()
        let al = try #require(leagues.first { $0.id == 103 })

        #expect(al.name == "American League")
        #expect(al.nameShort == "American")
        #expect(al.abbreviation == "AL")
        #expect(al.orgCode == "AL")
        #expect(al.numTeams == 15)
        #expect(al.numGames == 162)
        #expect(al.numWildcardTeams == 3)
        #expect(al.hasWildCard == true)
        #expect(al.hasSplitSeason == false)
        #expect(al.divisionsInUse == true)
        #expect(al.active == true)
        #expect(al.sportId == 1)
    }

    @Test("Season boundary dates parse to UTC midnight")
    func seasonDatesParse() throws {
        let leagues = try loadLeagues()
        let al = try #require(leagues.first { $0.id == 103 })
        let dates = try #require(al.seasonDates)

        #expect(dates.seasonId == "2026")

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .current

        let regStart = try #require(dates.regularSeasonStart)
        let regStartComponents = calendar.dateComponents([.year, .month, .day], from: regStart)
        #expect(regStartComponents.year == 2026)
        #expect(regStartComponents.month == 3)
        #expect(regStartComponents.day == 25)

        let allStar = try #require(dates.allStarDate)
        let allStarComponents = calendar.dateComponents([.year, .month, .day], from: allStar)
        #expect(allStarComponents.year == 2026)
        #expect(allStarComponents.month == 7)
        #expect(allStarComponents.day == 14)
    }

    @Test("offseasonEnd reads the camel-cased source key")
    func offseasonEndDecodes() throws {
        let leagues = try loadLeagues()
        let al = try #require(leagues.first { $0.id == 103 })
        let dates = try #require(al.seasonDates)
        #expect(dates.offseasonEnd != nil)
    }

    @Test("Missing sport ref leaves sportId nil")
    func missingSportId() throws {
        let json = #"""
        {"leagues":[{"id":1,"name":"X"}]}
        """#
        let data = Data(json.utf8)
        let response = try JSONDecoder.mlb.decode(MLBLeaguesResponse.self, from: data)
        let league = try #require(MLBResponseConverters.leagues(from: response).first)
        #expect(league.sportId == nil)
        #expect(league.seasonDates == nil)
        #expect(league.active == false)
    }

    @Test("Endpoint URL targets /leagues with sportId")
    func endpointURL() throws {
        let endpoint = Endpoint(path: "leagues", queryItems: [
            URLQueryItem(name: "sportId", value: "1")
        ])
        let baseURL = try #require(URL(string: "https://statsapi.mlb.com/api/v1/"))
        let built = try #require(endpoint.url(baseURL: baseURL))
        #expect(built.absoluteString == "https://statsapi.mlb.com/api/v1/leagues?sportId=1")
    }

    @Test("Endpoint URL omits sportId when unset")
    func endpointURLUnscoped() throws {
        let endpoint = Endpoint(path: "leagues")
        let baseURL = try #require(URL(string: "https://statsapi.mlb.com/api/v1/"))
        let built = try #require(endpoint.url(baseURL: baseURL))
        #expect(built.absoluteString == "https://statsapi.mlb.com/api/v1/leagues")
    }
}
