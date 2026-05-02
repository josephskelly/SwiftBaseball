import Foundation
@testable import SwiftBaseball
import Testing

@Suite("Draft Prospects Tests")
struct DraftProspectsTests {
    @Test("Draft prospects decodes 20-row pool with key fields")
    func prospectsDecodes() async throws {
        let mock = MockAPIClient()
        let data = try Fixtures.load("draft_prospects_2023.json")
        mock.stub(path: "draft/prospects/2023", data: data)

        let pool = try await QueryBuilder<[DraftProspect]>
            .draftProspects(year: 2023, client: mock)
            .fetch()

        #expect(pool.count == 20)
        let first = try #require(pool.first)
        #expect(first.year == 2023)
        #expect(first.pickRound == "14")
        #expect(first.pickNumber == 412)
        #expect(first.person?.fullName == "Hunter Mann")
        #expect(first.school?.name == "Tennessee Tech")
        #expect(first.draftType?.code == "JR")
    }

    @Test("Draft prospects endpoint hits draft/prospects/{year}")
    func prospectsEndpointPath() async throws {
        let mock = MockAPIClient()
        let data = try Fixtures.load("draft_prospects_2023.json")
        mock.stub(path: "draft/prospects/2023", data: data)

        _ = try await QueryBuilder<[DraftProspect]>
            .draftProspects(year: 2023, client: mock)
            .fetch()

        let endpoint = try #require(mock.lastEndpoint)
        #expect(endpoint.path == "draft/prospects/2023")
    }

    @Test("Draft latest decodes most-recent pick + nextUp queue")
    func latestDecodes() async throws {
        let mock = MockAPIClient()
        let data = try Fixtures.load("draft_latest_2024.json")
        mock.stub(path: "draft/2024/latest", data: data)

        let snapshot = try await QueryBuilder<DraftLatest>
            .draftLatest(year: 2024, client: mock)
            .fetch()

        #expect(snapshot.number == 615)
        let pick = try #require(snapshot.pick)
        #expect(pick.pickNumber == 615)
        #expect(pick.pickRound == "20")
        #expect(pick.person?.fullName == "Mac Rose")
        #expect(snapshot.nextUp.isEmpty)
    }

    @Test("Draft latest endpoint hits draft/{year}/latest")
    func latestEndpointPath() async throws {
        let mock = MockAPIClient()
        let data = try Fixtures.load("draft_latest_2024.json")
        mock.stub(path: "draft/2024/latest", data: data)

        _ = try await QueryBuilder<DraftLatest>
            .draftLatest(year: 2024, client: mock)
            .fetch()

        let endpoint = try #require(mock.lastEndpoint)
        #expect(endpoint.path == "draft/2024/latest")
    }
}
