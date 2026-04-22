import Foundation
@testable import SwiftBaseball
import Testing

@Suite("Draft Tests")
struct DraftTests {
    // MARK: - Parser

    @Test("Parse draft fixture returns all picks")
    func parseDraftPicks() async throws {
        let data = try Fixtures.load("draft_2024.json")
        let mock = MockAPIClient()
        mock.stub(path: "draft/2024", data: data)

        let picks = try await QueryBuilder<[DraftPick]>.draft(year: 2024, client: mock).fetch()

        #expect(picks.count == 3)
        #expect(picks.allSatisfy { $0.year == 2024 })
    }

    @Test("First overall pick parsed correctly")
    func draftFirstPick() async throws {
        let data = try Fixtures.load("draft_2024.json")
        let mock = MockAPIClient()
        mock.stub(path: "draft/2024", data: data)

        let picks = try await QueryBuilder<[DraftPick]>.draft(year: 2024, client: mock).fetch()

        let first = try #require(picks.first)
        #expect(first.id == 1)
        #expect(first.round == "1")
        #expect(first.roundPickNumber == 1)
        #expect(first.person?.fullName == "Dylan Crews")
        #expect(first.person?.id == 697_912)
        #expect(first.team?.name == "Washington Nationals")
        #expect(first.team?.id == 120)
        #expect(first.signingBonus == "$9,500,000")
        #expect(first.isDrafted == true)
        #expect(first.isPass == false)
    }

    @Test("First pick school fields parsed correctly")
    func draftFirstPickSchool() async throws {
        let data = try Fixtures.load("draft_2024.json")
        let mock = MockAPIClient()
        mock.stub(path: "draft/2024", data: data)

        let picks = try await QueryBuilder<[DraftPick]>.draft(year: 2024, client: mock).fetch()

        let school = try #require(picks.first?.school)
        #expect(school.name == "LSU")
        #expect(school.schoolClass == "College")
        #expect(school.city == "Baton Rouge")
        #expect(school.state == "LA")
        #expect(school.country == "USA")
    }

    @Test("Second overall pick parsed correctly")
    func draftSecondPick() async throws {
        let data = try Fixtures.load("draft_2024.json")
        let mock = MockAPIClient()
        mock.stub(path: "draft/2024", data: data)

        let picks = try await QueryBuilder<[DraftPick]>.draft(year: 2024, client: mock).fetch()

        let dollander = try #require(picks.first { $0.id == 2 })
        #expect(dollander.person?.fullName == "Chase Dollander")
        #expect(dollander.team?.name == "Colorado Rockies")
        #expect(dollander.school?.schoolClass == "College")
        #expect(dollander.school?.name == "Tennessee")
    }

    @Test("Second round pick has correct round and pick numbers")
    func draftSecondRoundPick() async throws {
        let data = try Fixtures.load("draft_2024.json")
        let mock = MockAPIClient()
        mock.stub(path: "draft/2024", data: data)

        let picks = try await QueryBuilder<[DraftPick]>.draft(year: 2024, client: mock).fetch()

        let secondRound = try #require(picks.first { $0.id == 38 })
        #expect(secondRound.round == "2")
        #expect(secondRound.roundPickNumber == 7)
        #expect(secondRound.school?.schoolClass == "HS")
        #expect(secondRound.person?.fullName == "Marco Testa")
    }

    @Test("Pick missing pickNumber is skipped")
    func draftSkipsMissingPickNumber() async throws {
        let json = """
        {
          "drafts": {
            "draftYear": 2024,
            "rounds": [
              {
                "round": "1",
                "picks": [
                  {
                    "bisPlayerId": 697912,
                    "pickRound": "1",
                    "pickNumber": 1,
                    "team": {"id": 120, "name": "Washington Nationals", "link": ""},
                    "person": {"id": 697912, "fullName": "Dylan Crews", "link": ""},
                    "isDrafted": true,
                    "isPass": false
                  },
                  {
                    "bisPlayerId": null,
                    "pickRound": "1",
                    "team": {"id": 115, "name": "Colorado Rockies", "link": ""},
                    "isDrafted": false,
                    "isPass": false
                  }
                ]
              }
            ]
          }
        }
        """
        let data = Data(json.utf8)
        let mock = MockAPIClient()
        mock.stub(path: "draft/2024", data: data)

        let picks = try await QueryBuilder<[DraftPick]>.draft(year: 2024, client: mock).fetch()

        #expect(picks.count == 1)
        #expect(picks[0].id == 1)
    }

    @Test("Empty rounds returns empty array")
    func draftEmptyRounds() async throws {
        let json = """
        {
          "drafts": {
            "draftYear": 2023,
            "rounds": []
          }
        }
        """
        let data = Data(json.utf8)
        let mock = MockAPIClient()
        mock.stub(path: "draft/2023", data: data)

        let picks = try await QueryBuilder<[DraftPick]>.draft(year: 2023, client: mock).fetch()

        #expect(picks.isEmpty)
    }

    // MARK: - Query builder

    @Test("draft(year:) round modifier adds query param")
    func draftQueryRoundModifier() async throws {
        let data = try Fixtures.load("draft_2024.json")
        let mock = MockAPIClient()
        mock.stub(path: "draft/2024", data: data)

        let query = QueryBuilder<[DraftPick]>.draft(year: 2024, client: mock).round(1)
        _ = try await query.fetch()

        #expect(mock.lastEndpoint?.queryItems.contains { $0.name == "round" && $0.value == "1" } == true)
    }

    @Test("draft(year:) teamId modifier adds query param")
    func draftQueryTeamIdModifier() async throws {
        let data = try Fixtures.load("draft_2024.json")
        let mock = MockAPIClient()
        mock.stub(path: "draft/2024", data: data)

        let query = QueryBuilder<[DraftPick]>.draft(year: 2024, client: mock).teamId(120)
        _ = try await query.fetch()

        #expect(mock.lastEndpoint?.queryItems.contains { $0.name == "teamId" && $0.value == "120" } == true)
    }

    @Test("SwiftBaseball.draft(year:) returns DraftPick array")
    func namespacedDraft() {
        let query = SwiftBaseball.draft(year: 2024)
        _ = query.round(1)
        _ = query.teamId(147)
    }

    @Test("DraftPick conforms to Identifiable using pickNumber")
    func draftPickIdentifiable() {
        let pick = DraftPick(
            id: 5,
            year: 2024,
            round: "1",
            roundPickNumber: 5,
            team: nil,
            person: nil,
            school: nil,
            signingBonus: nil,
            blurb: nil,
            scoutingReport: nil,
            isDrafted: false,
            isPass: false
        )
        #expect(pick.id == 5)
    }
}
