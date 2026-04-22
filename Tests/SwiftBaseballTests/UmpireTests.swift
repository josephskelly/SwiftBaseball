import Foundation
@testable import SwiftBaseball
import Testing

@Suite("Umpire Tests")
struct UmpireTests {
    private func loadUmpires() throws -> [Umpire] {
        let data = try Fixtures.load("umpires_2024_07_04.json")
        let response = try JSONDecoder.mlb.decode(MLBUmpiresResponse.self, from: data)
        return response.roster.map(MLBResponseConverters.umpire)
    }

    @Test("Roster decodes into Umpire entries")
    func rosterDecodes() throws {
        let umpires = try loadUmpires()
        #expect(umpires.count == 12)
    }

    @Test("First entry carries person, job, and jersey")
    func firstUmpire() throws {
        let umpires = try loadUmpires()
        let first = try #require(umpires.first)

        #expect(first.person.id == 596_809)
        #expect(first.person.fullName == "Ryan Additon")
        #expect(first.jerseyNumber == "67")
        #expect(first.job == "Umpire")
        #expect(first.jobId == "UMPR")
    }

    @Test("Identifiable id reflects the underlying person id")
    func identifiable() throws {
        let umpires = try loadUmpires()
        for umpire in umpires {
            #expect(umpire.id == umpire.person.id)
        }
    }

    @Test("Standard pool entries carry the UMPR job code")
    func defaultJobIdIsUMPR() throws {
        let umpires = try loadUmpires()
        #expect(umpires.allSatisfy { $0.jobId == "UMPR" })
    }

    @Test("Missing optional fields fall through to defaults")
    func missingFieldsDefault() throws {
        let json = #"""
        {"roster":[{"person":{"id":1,"fullName":"Test Ump"}}]}
        """#
        let data = Data(json.utf8)
        let response = try JSONDecoder.mlb.decode(MLBUmpiresResponse.self, from: data)
        let umpire = try #require(response.roster.map(MLBResponseConverters.umpire).first)

        #expect(umpire.id == 1)
        #expect(umpire.jerseyNumber == nil)
        #expect(umpire.job == "")
        #expect(umpire.jobId == "")
        #expect(umpire.title == nil)
    }

    @Test("Endpoint URL targets /jobs/umpires with date query")
    func endpointURL() throws {
        let endpoint = Endpoint(path: "jobs/umpires", queryItems: [
            URLQueryItem(name: "date", value: "2024-07-04")
        ])
        let baseURL = try #require(URL(string: "https://statsapi.mlb.com/api/v1/"))
        let built = try #require(endpoint.url(baseURL: baseURL))
        #expect(built.absoluteString == "https://statsapi.mlb.com/api/v1/jobs/umpires?date=2024-07-04")
    }
}
