import Foundation
@testable import SwiftBaseball
import Testing

@Suite("TeamStaff Tests")
struct TeamStaffTests {
    private func loadCoaches() throws -> [TeamStaff] {
        let data = try Fixtures.load("team_coaches_147.json")
        let response = try JSONDecoder.mlb.decode(MLBCoachesResponse.self, from: data)
        return response.roster.map(MLBResponseConverters.teamStaff)
    }

    @Test("Decodes all coaches from fixture")
    func coachesCount() throws {
        let staff = try loadCoaches()
        #expect(staff.count == 11)
    }

    @Test("Manager is identified by MNGR jobId")
    func managerLookup() throws {
        let staff = try loadCoaches()
        let manager = try #require(staff.first { $0.jobId == "MNGR" })
        #expect(manager.person.fullName == "Aaron Boone")
        #expect(manager.jerseyNumber == "17")
        #expect(manager.job == "Manager")
        #expect(manager.title == "Manager")
    }

    @Test("Pitching coach is identified by COAP jobId")
    func pitchingCoachLookup() throws {
        let staff = try loadCoaches()
        let pitching = try #require(staff.first { $0.jobId == "COAP" })
        #expect(pitching.person.fullName == "Matt Blake")
        #expect(pitching.job == "Pitching Coach")
    }

    @Test("TeamStaff.id is the person's MLB ID")
    func identifiableConformance() throws {
        let staff = try loadCoaches()
        let first = try #require(staff.first)
        #expect(first.id == first.person.id)
    }

    @Test("Multiple coaches can share the same jobId")
    func multipleAssistantHittingCoaches() throws {
        let staff = try loadCoaches()
        let assistants = staff.filter { $0.jobId == "COAA" }
        #expect(assistants.count == 2)
        #expect(assistants.allSatisfy { $0.job == "Assistant Hitting Coach" })
    }

    @Test("Endpoint URL targets /teams/{id}/coaches")
    func endpointURL() throws {
        let endpoint = Endpoint(path: "teams/147/coaches")
        let baseURL = try #require(URL(string: "https://statsapi.mlb.com/api/v1/"))
        let built = try #require(endpoint.url(baseURL: baseURL))
        #expect(built.absoluteString == "https://statsapi.mlb.com/api/v1/teams/147/coaches")
    }
}
