import Foundation
@testable import SwiftBaseball
import Testing

@Suite("Team Personnel Tests")
struct TeamPersonnelTests {
    private func loadPersonnel() throws -> [TeamStaff] {
        let data = try Fixtures.load("team_personnel_147.json")
        let response = try JSONDecoder.mlb.decode(MLBCoachesResponse.self, from: data)
        return response.roster.map(MLBResponseConverters.teamStaff)
    }

    @Test("Roster decodes into TeamStaff entries")
    func rosterDecodes() throws {
        let personnel = try loadPersonnel()
        #expect(personnel.count == 15)
    }

    @Test("First entry carries person, job, jobId, and title")
    func firstEntry() throws {
        let personnel = try loadPersonnel()
        let first = try #require(personnel.first)

        #expect(first.person.id == 693_113)
        #expect(first.person.fullName == "Eric Cressey")
        #expect(first.job == "Director of Player Health")
        #expect(first.jobId == "DRPH")
        #expect(first.title == "Director of Player Health and Performance")
    }

    @Test("Empty jerseyNumber decodes to empty string (not nil)")
    func emptyJerseyNumber() throws {
        let personnel = try loadPersonnel()
        // Every personnel entry from the fixture has "" for jerseyNumber
        #expect(personnel.allSatisfy { $0.jerseyNumber == "" })
    }

    @Test("Head athletic trainer is filterable by stable jobId")
    func filterByJobId() throws {
        let personnel = try loadPersonnel()
        let hatr = try #require(personnel.first { $0.jobId == "HATR" })
        #expect(hatr.person.fullName == "Tim Lentych")
    }

    @Test("Title differs from job when upstream provides both")
    func titleVsJob() throws {
        let personnel = try loadPersonnel()
        let physicalTherapist = try #require(personnel.first { $0.jobId == "PTHR" })
        #expect(physicalTherapist.job == "Physical Therapist")
        #expect(physicalTherapist.title == "Major League Physical Therapist & Rehab Coordinator")
        #expect(physicalTherapist.title != physicalTherapist.job)
    }

    @Test("Endpoint URL targets /teams/{id}/personnel")
    func endpointURL() throws {
        let endpoint = Endpoint(path: "teams/147/personnel")
        let baseURL = try #require(URL(string: "https://statsapi.mlb.com/api/v1/"))
        let built = try #require(endpoint.url(baseURL: baseURL))
        #expect(built.absoluteString == "https://statsapi.mlb.com/api/v1/teams/147/personnel")
    }
}
