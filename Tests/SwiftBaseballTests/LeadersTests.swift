import Testing
import Foundation
@testable import SwiftBaseball

@Suite("Leaders Tests")
struct LeadersTests {

    @Test("Decode leaders from fixture")
    func decodeLeaders() throws {
        let data = try Fixtures.load("leaders_homeRuns_2024.json")
        let response = try JSONDecoder.mlb.decode(MLBLeadersResponse.self, from: data)
        let categories = MLBResponseConverters.leaderEntries(from: response)

        #expect(categories.count == 1)

        let category = try #require(categories.first)
        #expect(category.leaderCategory == "homeRuns")
        #expect(category.leaders.count == 3)
    }

    @Test("Leader entries ranked correctly")
    func leaderRanking() throws {
        let data = try Fixtures.load("leaders_homeRuns_2024.json")
        let response = try JSONDecoder.mlb.decode(MLBLeadersResponse.self, from: data)
        let categories = MLBResponseConverters.leaderEntries(from: response)
        let leaders = try #require(categories.first?.leaders)

        #expect(leaders[0].rank == 1)
        #expect(leaders[1].rank == 2)
        #expect(leaders[2].rank == 3)
    }

    @Test("Leader value is a string")
    func leaderValue() throws {
        let data = try Fixtures.load("leaders_homeRuns_2024.json")
        let response = try JSONDecoder.mlb.decode(MLBLeadersResponse.self, from: data)
        let categories = MLBResponseConverters.leaderEntries(from: response)
        let leader = try #require(categories.first?.leaders.first)

        #expect(leader.value == "54")
    }

    @Test("Leader player reference decoded")
    func leaderPlayerRef() throws {
        let data = try Fixtures.load("leaders_homeRuns_2024.json")
        let response = try JSONDecoder.mlb.decode(MLBLeadersResponse.self, from: data)
        let categories = MLBResponseConverters.leaderEntries(from: response)
        let leader = try #require(categories.first?.leaders.first)

        #expect(leader.player.id == 660271)
        #expect(leader.player.fullName == "Shohei Ohtani")
    }

    @Test("Leader team reference decoded")
    func leaderTeamRef() throws {
        let data = try Fixtures.load("leaders_homeRuns_2024.json")
        let response = try JSONDecoder.mlb.decode(MLBLeadersResponse.self, from: data)
        let categories = MLBResponseConverters.leaderEntries(from: response)
        let leader = try #require(categories.first?.leaders.first)

        #expect(leader.team?.id == 119)
        #expect(leader.team?.name == "Los Angeles Dodgers")
    }

    @Test("Leader season and leagueRank decoded")
    func leaderSeasonAndRank() throws {
        let data = try Fixtures.load("leaders_homeRuns_2024.json")
        let response = try JSONDecoder.mlb.decode(MLBLeadersResponse.self, from: data)
        let categories = MLBResponseConverters.leaderEntries(from: response)
        let leader = try #require(categories.first?.leaders.first)

        #expect(leader.season == "2024")
        #expect(leader.leagueRank == 1)
    }

    @Test("leaders() query builder constructs correct path")
    func leadersQueryBuilder() async throws {
        let mock = MockAPIClient()
        let data = try Fixtures.load("leaders_homeRuns_2024.json")
        mock.stub(path: "stats/leaders", data: data)

        let builder = QueryBuilder<[LeaderCategory]>.leaders(.homeRuns, client: mock)
        _ = try await builder.fetch()

        let endpoint = try #require(mock.lastEndpoint)
        #expect(endpoint.path == "stats/leaders")
        #expect(endpoint.queryItems.contains { $0.name == "leaderCategories" && $0.value == "homeRuns" })
        #expect(endpoint.queryItems.contains { $0.name == "sportId" && $0.value == "1" })
    }

    // MARK: - Pitching Leaders

    @Test("Decode pitching leaders from fixture")
    func decodePitchingLeaders() throws {
        let data = try Fixtures.load("leaders_earnedRunAverage_2024.json")
        let response = try JSONDecoder.mlb.decode(MLBLeadersResponse.self, from: data)
        let categories = MLBResponseConverters.leaderEntries(from: response)

        #expect(categories.count == 1)

        let category = try #require(categories.first)
        #expect(category.leaderCategory == "earnedRunAverage")
        #expect(category.leaders.count == 3)
    }

    @Test("Pitching leader value is a decimal string")
    func pitchingLeaderValue() throws {
        let data = try Fixtures.load("leaders_earnedRunAverage_2024.json")
        let response = try JSONDecoder.mlb.decode(MLBLeadersResponse.self, from: data)
        let categories = MLBResponseConverters.leaderEntries(from: response)
        let leader = try #require(categories.first?.leaders.first)

        #expect(leader.value == "2.38")
    }

    @Test("Pitching leader player reference decoded")
    func pitchingLeaderPlayerRef() throws {
        let data = try Fixtures.load("leaders_earnedRunAverage_2024.json")
        let response = try JSONDecoder.mlb.decode(MLBLeadersResponse.self, from: data)
        let categories = MLBResponseConverters.leaderEntries(from: response)
        let leader = try #require(categories.first?.leaders.first)

        #expect(leader.player.id == 518516)
        #expect(leader.player.fullName == "Chris Sale")
    }

    @Test("Pitching leaders query builder constructs correct path")
    func pitchingLeadersQueryBuilder() async throws {
        let mock = MockAPIClient()
        let data = try Fixtures.load("leaders_earnedRunAverage_2024.json")
        mock.stub(path: "stats/leaders", data: data)

        let builder = QueryBuilder<[LeaderCategory]>.leaders(.earnedRunAverage, client: mock)
        _ = try await builder.fetch()

        let endpoint = try #require(mock.lastEndpoint)
        #expect(endpoint.path == "stats/leaders")
        #expect(endpoint.queryItems.contains { $0.name == "leaderCategories" && $0.value == "earnedRunAverage" })
        #expect(endpoint.queryItems.contains { $0.name == "sportId" && $0.value == "1" })
    }

    @Test("All pitching categories round-trip through rawValue")
    func allPitchingCategoriesRoundTrip() {
        let pitchingCases: [(String, LeaderStatCategory)] = [
            ("earnedRunAverage", .earnedRunAverage),
            ("wins", .wins),
            ("strikeouts", .strikeouts),
            ("saves", .saves),
            ("whip", .whip),
            ("inningsPitched", .inningsPitched),
            ("walksAndHitsPerInningPitched", .walksAndHitsPerInningPitched),
            ("strikeoutsPer9Inn", .strikeoutsPer9Inn)
        ]
        for (raw, expected) in pitchingCases {
            #expect(LeaderStatCategory(rawValue: raw) == expected)
        }
    }

    @Test("Empty leaders response")
    func emptyLeaders() throws {
        let json = """
        { "leagueLeaders": [{ "leaderCategory": "homeRuns", "leaders": [] }] }
        """.data(using: .utf8)!
        let response = try JSONDecoder.mlb.decode(MLBLeadersResponse.self, from: json)
        let categories = MLBResponseConverters.leaderEntries(from: response)

        let category = try #require(categories.first)
        #expect(category.leaderCategory == "homeRuns")
        #expect(category.leaders.isEmpty)
    }
}
