import Foundation
@testable import SwiftBaseball
import Testing

@Suite("Team Leaders Tests")
struct TeamLeadersTests {
    private func loadCategories() throws -> [TeamLeaderCategory] {
        let data = try Fixtures.load("team_leaders_147_homeRuns_2024.json")
        let response = try JSONDecoder.mlb.decode(MLBTeamLeadersResponse.self, from: data)
        return MLBResponseConverters.teamLeaders(from: response)
    }

    @Test("One category per stat group is returned")
    func categoriesDecode() throws {
        let categories = try loadCategories()
        #expect(categories.count == 3)
    }

    @Test("Hitting leaders carry the .batting stat group")
    func hittingGroup() throws {
        let categories = try loadCategories()
        let hitting = try #require(categories.first { $0.statGroup == .batting })

        #expect(hitting.leaderCategory == "homeRuns")
        #expect(hitting.season == "2024")
        #expect(hitting.gameType == .regularSeason)
        #expect(hitting.team.id == 147)
        #expect(hitting.totalSplits == 18)
        #expect(hitting.leaders.count == 6)

        let top = try #require(hitting.leaders.first)
        #expect(top.rank == 1)
        #expect(top.value == "58")
        #expect(top.player.id == 592_450)
        #expect(top.player.fullName == "Aaron Judge")
    }

    @Test("Pitching leaders carry the .pitching stat group")
    func pitchingGroup() throws {
        let categories = try loadCategories()
        let pitching = try #require(categories.first { $0.statGroup == .pitching })

        #expect(pitching.totalSplits == 28)
        let top = try #require(pitching.leaders.first)
        #expect(top.player.fullName == "Carlos Rodón")
        #expect(top.value == "31")
    }

    @Test("Unknown stat groups fall through to nil")
    func unknownStatGroup() throws {
        let categories = try loadCategories()
        let catching = try #require(categories.first { $0.leaderCategory == "homeRuns" && $0.statGroup == nil })
        #expect(catching.totalSplits == 3)
        #expect(catching.leaders.count == 3)
    }

    @Test("Records without a team are skipped")
    func skipsMissingTeam() throws {
        let json = #"""
        {"teamLeaders":[{"leaderCategory":"homeRuns","leaders":[]}]}
        """#
        let data = Data(json.utf8)
        let response = try JSONDecoder.mlb.decode(MLBTeamLeadersResponse.self, from: data)
        let categories = MLBResponseConverters.teamLeaders(from: response)
        #expect(categories.isEmpty)
    }

    @Test("Unknown game type decodes to nil")
    func unknownGameType() throws {
        let json = #"""
        {"teamLeaders":[{
          "leaderCategory":"homeRuns",
          "statGroup":"hitting",
          "gameType":{"id":"ZZ","description":"Unknown"},
          "team":{"id":147,"name":"Yankees"},
          "leaders":[]
        }]}
        """#
        let data = Data(json.utf8)
        let response = try JSONDecoder.mlb.decode(MLBTeamLeadersResponse.self, from: data)
        let category = try #require(MLBResponseConverters.teamLeaders(from: response).first)
        #expect(category.gameType == nil)
        #expect(category.statGroup == .batting)
    }

    @Test("Endpoint URL targets /teams/{id}/leaders with category")
    func endpointURL() throws {
        let endpoint = Endpoint(path: "teams/147/leaders", queryItems: [
            URLQueryItem(name: "leaderCategories", value: "homeRuns")
        ])
        let baseURL = try #require(URL(string: "https://statsapi.mlb.com/api/v1/"))
        let built = try #require(endpoint.url(baseURL: baseURL))
        #expect(built.absoluteString == "https://statsapi.mlb.com/api/v1/teams/147/leaders?leaderCategories=homeRuns")
    }
}
