import Foundation
@testable import SwiftBaseball
import Testing

@Suite("Awards Tests")
struct AwardsTests {
    // MARK: - Recipients parsing

    @Test("Parse recipients fixture returns correct count")
    func parseAwardRecipients() async throws {
        let data = try Fixtures.load("awards_recipients_ALMVP_2024.json")
        let mock = MockAPIClient()
        mock.stub(path: "awards/ALMVP/recipients", data: data)

        let recipients = try await QueryBuilder<[AwardRecipient]>.awardRecipients(awardId: "ALMVP", client: mock).fetch()

        #expect(recipients.count == 1)
    }

    @Test("Recipients fixture parsed correctly")
    func awardRecipientFields() async throws {
        let data = try Fixtures.load("awards_recipients_ALMVP_2024.json")
        let mock = MockAPIClient()
        mock.stub(path: "awards/ALMVP/recipients", data: data)

        let recipients = try await QueryBuilder<[AwardRecipient]>.awardRecipients(awardId: "ALMVP", client: mock).fetch()

        let recipient = try #require(recipients.first)
        #expect(recipient.awardId == "ALMVP")
        #expect(recipient.awardName == "AL MVP")
        #expect(recipient.season == "2024")
        #expect(recipient.player?.id == 592_450)
        #expect(recipient.player?.fullName == "Aaron Judge")
        #expect(recipient.teamId == 147)
    }

    @Test("Recipient date parsed from YYYY-MM-DD string")
    func awardRecipientDate() async throws {
        let data = try Fixtures.load("awards_recipients_ALMVP_2024.json")
        let mock = MockAPIClient()
        mock.stub(path: "awards/ALMVP/recipients", data: data)

        let recipients = try await QueryBuilder<[AwardRecipient]>.awardRecipients(awardId: "ALMVP", client: mock).fetch()

        let date = try #require(recipients.first?.date)
        let calendar = Calendar(identifier: .gregorian)
        let components = try calendar.dateComponents(in: #require(TimeZone(identifier: "UTC")), from: date)
        #expect(components.year == 2024)
        #expect(components.month == 11)
        #expect(components.day == 21)
    }

    // MARK: - Awards list parsing

    @Test("Parse awards list fixture returns correct count")
    func parseAwardsList() async throws {
        let data = try Fixtures.load("awards_list.json")
        let mock = MockAPIClient()
        mock.stub(path: "awards", data: data)

        let awards = try await QueryBuilder<[Award]>.allAwards(client: mock).fetch()

        #expect(awards.count == 3)
    }

    @Test("Awards list fixture fields parsed correctly")
    func awardsListFields() async throws {
        let data = try Fixtures.load("awards_list.json")
        let mock = MockAPIClient()
        mock.stub(path: "awards", data: data)

        let awards = try await QueryBuilder<[Award]>.allAwards(client: mock).fetch()

        let hof = try #require(awards.first { $0.id == "MLBHOF" })
        #expect(hof.name == "Hall Of Fame")
        #expect(hof.description == "Member of Hall of Fame")
        #expect(hof.active == true)
        #expect(hof.sportId == 1)
        #expect(hof.leagueId == nil)

        let almvp = try #require(awards.first { $0.id == "ALMVP" })
        #expect(almvp.name == "AL MVP")
        #expect(almvp.active == true)
        #expect(almvp.leagueId == 103)
        #expect(almvp.sportId == nil)
    }

    // MARK: - Query builder modifier

    @Test("season modifier adds query param to recipients query")
    func recipientsSeasonModifier() async throws {
        let data = try Fixtures.load("awards_recipients_ALMVP_2024.json")
        let mock = MockAPIClient()
        mock.stub(path: "awards/ALMVP/recipients", data: data)

        let query = QueryBuilder<[AwardRecipient]>.awardRecipients(awardId: "ALMVP", client: mock).season(2024)
        _ = try await query.fetch()

        #expect(mock.lastEndpoint?.queryItems.contains { $0.name == "season" && $0.value == "2024" } == true)
    }

    // MARK: - Namespace

    @Test("SwiftBaseball.awardRecipients returns correct type")
    func namespacedAwardRecipients() {
        let query = SwiftBaseball.awardRecipients(awardId: "ALMVP")
        _ = query.season(2024)
    }

    @Test("SwiftBaseball.awards returns correct type")
    func namespacedAwards() {
        _ = SwiftBaseball.awards()
    }
}
