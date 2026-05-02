import Foundation
@testable import SwiftBaseball
import Testing

@Suite("Official Scorers Tests")
struct OfficialScorersTests {
    @Test("Decodes 15-row roster with key fields")
    func decodes() async throws {
        let mock = MockAPIClient()
        let data = try Fixtures.load("official_scorers_2024_07_01.json")
        mock.stub(path: "jobs/officialScorers", data: data)

        let roster = try await QueryBuilder<[OfficialScorer]>
            .officialScorers(date: "2024-07-01", client: mock)
            .fetch()

        #expect(roster.count == 15)
        let first = try #require(roster.first)
        #expect(first.person.fullName == "Fernando Alcala")
        #expect(first.person.id == 582413)
        #expect(first.jobId == "SCOR")
        #expect(first.job == "Official Scorer")
        #expect(first.jerseyNumber == nil)
    }

    @Test("Endpoint hits jobs/officialScorers with date param")
    func endpointParams() async throws {
        let mock = MockAPIClient()
        let data = try Fixtures.load("official_scorers_2024_07_01.json")
        mock.stub(path: "jobs/officialScorers", data: data)

        _ = try await QueryBuilder<[OfficialScorer]>
            .officialScorers(date: "2024-07-01", client: mock)
            .fetch()

        let endpoint = try #require(mock.lastEndpoint)
        #expect(endpoint.path == "jobs/officialScorers")
        let dateItem = endpoint.queryItems.first { $0.name == "date" }
        #expect(dateItem?.value == "2024-07-01")
    }
}
