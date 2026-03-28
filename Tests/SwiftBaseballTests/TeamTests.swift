import Testing
import Foundation
@testable import SwiftBaseball

@Suite("Team Tests")
struct TeamTests {

    // MARK: - Decode teams

    @Test("Decode teams from real API fixture")
    func decodeTeams() throws {
        let data = try Fixtures.load("teams_2024.json")
        let response = try JSONDecoder.mlb.decode(MLBTeamsResponse.self, from: data)
        let teams = response.teams.map(MLBResponseConverters.team)

        #expect(teams.count == 2)

        let yankees = try #require(teams.first { $0.id == 147 })
        #expect(yankees.name == "New York Yankees")
        #expect(yankees.abbreviation == "NYY")
        #expect(yankees.teamName == "Yankees")
        #expect(yankees.locationName == "Bronx")
        #expect(yankees.active == true)
        #expect(yankees.season == 2024)
        #expect(yankees.league.id == 103)
        #expect(yankees.league.name == "American League")
        #expect(yankees.division.id == 201)
        #expect(yankees.division.name == "American League East")
        #expect(yankees.venue.id == 3313)
        #expect(yankees.venue.name == "Yankee Stadium")
        #expect(yankees.shortName == "NY Yankees")
        #expect(yankees.franchiseName == "New York")
        #expect(yankees.clubName == "Yankees")

        let dodgers = try #require(teams.first { $0.id == 119 })
        #expect(dodgers.abbreviation == "LAD")
        #expect(dodgers.teamName == "Dodgers")
        #expect(dodgers.league.id == 104)
        #expect(dodgers.league.name == "National League")
        #expect(dodgers.division.name == "National League West")
        #expect(dodgers.venue.name == "Dodger Stadium")
    }

    // MARK: - QueryBuilder for teams

    @Test("teams(.all) query builder includes sportId and season")
    func teamsAllQueryBuilder() async throws {
        let mock = MockAPIClient()
        let data = try Fixtures.load("teams_2024.json")
        mock.stub(path: "teams", data: data)

        let builder = QueryBuilder<[Team]>.teams(.all(season: 2024), client: mock)
        let teams = try await builder.fetch()

        #expect(teams.count == 2)
        #expect(mock.lastEndpoint?.path == "teams")

        let items = mock.lastEndpoint?.queryItems ?? []
        #expect(items.contains { $0.name == "sportId" && $0.value == "1" })
        #expect(items.contains { $0.name == "season" && $0.value == "2024" })
    }

    @Test("team(id:) query builder uses correct path")
    func singleTeamQueryBuilder() async throws {
        let mock = MockAPIClient()
        let data = try Fixtures.load("teams_2024.json")
        mock.stub(path: "teams/147", data: data)

        let builder = QueryBuilder<Team>.singleTeam(id: 147, client: mock)
        let team = try await builder.fetch()

        #expect(team.id == 147)
        #expect(team.name == "New York Yankees")
        #expect(mock.lastEndpoint?.path == "teams/147")
    }

    // MARK: - Roster

    @Test("Decode roster from real API fixture")
    func decodeRoster() throws {
        let data = try Fixtures.load("roster_147_2024.json")
        let response = try JSONDecoder.mlb.decode(MLBRosterResponse.self, from: data)
        let entries = response.roster.map(MLBResponseConverters.rosterEntry)

        #expect(entries.count == 5)

        // All entries should have valid person references
        for entry in entries {
            #expect(entry.person.id > 0)
            #expect(!entry.person.fullName.isEmpty)
        }

        // Verify first entry details
        let first = entries[0]
        #expect(first.jerseyNumber != nil)
        #expect(first.status != nil)
    }

    @Test("Roster entry positions decode to known Position values")
    func rosterEntryPositions() throws {
        let data = try Fixtures.load("roster_147_2024.json")
        let response = try JSONDecoder.mlb.decode(MLBRosterResponse.self, from: data)
        let entries = response.roster.map(MLBResponseConverters.rosterEntry)

        // At least one pitcher expected in first 5 entries
        let hasPitcher = entries.contains { $0.position == .pitcher }
        #expect(hasPitcher)
    }

    @Test("Roster entry id comes from person.id")
    func rosterEntryIdFromPerson() throws {
        let data = try Fixtures.load("roster_147_2024.json")
        let response = try JSONDecoder.mlb.decode(MLBRosterResponse.self, from: data)
        let entries = response.roster.map(MLBResponseConverters.rosterEntry)

        let first = try #require(entries.first)
        #expect(first.id == first.person.id)
    }

    @Test("roster() query builder uses correct path and season")
    func rosterQueryBuilder() async throws {
        let mock = MockAPIClient()
        let data = try Fixtures.load("roster_147_2024.json")
        mock.stub(path: "teams/147/roster", data: data)

        let builder = QueryBuilder<[RosterEntry]>.roster(teamId: 147, season: 2024, client: mock)
        let roster = try await builder.fetch()

        #expect(roster.count == 5)
        #expect(mock.lastEndpoint?.path == "teams/147/roster")

        let seasonItem = mock.lastEndpoint?.queryItems.first { $0.name == "season" }
        #expect(seasonItem?.value == "2024")
    }

    @Test("roster() omits rosterType param for default active")
    func rosterQueryBuilderActiveOmitsParam() async throws {
        let mock = MockAPIClient()
        let data = try Fixtures.load("roster_147_2024.json")
        mock.stub(path: "teams/147/roster", data: data)

        _ = try await QueryBuilder<[RosterEntry]>.roster(
            teamId: 147, season: 2024, rosterType: .active, client: mock
        ).fetch()

        let rosterTypeItem = mock.lastEndpoint?.queryItems.first { $0.name == "rosterType" }
        #expect(rosterTypeItem == nil)
    }

    @Test("roster() sends rosterType=40Man for fortyMan")
    func rosterQueryBuilderFortyMan() async throws {
        let mock = MockAPIClient()
        let data = try Fixtures.load("roster_147_2024.json")
        mock.stub(path: "teams/147/roster", data: data)

        _ = try await QueryBuilder<[RosterEntry]>.roster(
            teamId: 147, season: 2024, rosterType: .fortyMan, client: mock
        ).fetch()

        let rosterTypeItem = mock.lastEndpoint?.queryItems.first { $0.name == "rosterType" }
        #expect(rosterTypeItem?.value == "40Man")
    }

    @Test("roster() sends rosterType=nonRosterInvitees for NRI")
    func rosterQueryBuilderNRI() async throws {
        let mock = MockAPIClient()
        let data = try Fixtures.load("roster_147_2024.json")
        mock.stub(path: "teams/147/roster", data: data)

        _ = try await QueryBuilder<[RosterEntry]>.roster(
            teamId: 147, season: 2024, rosterType: .nonRosterInvitees, client: mock
        ).fetch()

        let rosterTypeItem = mock.lastEndpoint?.queryItems.first { $0.name == "rosterType" }
        #expect(rosterTypeItem?.value == "nonRosterInvitees")
    }

    // MARK: - Team model equality

    @Test("Team models with same data are equal")
    func teamEquality() throws {
        let data = try Fixtures.load("teams_2024.json")
        let response = try JSONDecoder.mlb.decode(MLBTeamsResponse.self, from: data)
        let raw = try #require(response.teams.first)
        let team1 = MLBResponseConverters.team(from: raw)
        let team2 = MLBResponseConverters.team(from: raw)

        #expect(team1 == team2)
    }

    // MARK: - Minor league teams (sport modifier)

    @Test("teams(.all) with sport modifier replaces sportId param")
    func teamsAllSportModifier() async throws {
        let mock = MockAPIClient()
        let data = try Fixtures.load("teams_2024.json")
        mock.stub(path: "teams", data: data)

        _ = try await QueryBuilder<[Team]>.teams(.all(season: 2024), client: mock)
            .sport(.tripleA)
            .fetch()

        let items = mock.lastEndpoint?.queryItems ?? []
        #expect(items.contains { $0.name == "sportId" && $0.value == "11" })
        #expect(!items.contains { $0.name == "sportId" && $0.value == "1" })
    }

    // MARK: - Affiliates

    @Test("affiliates fixture decodes correct count")
    func affiliatesCount() async throws {
        let data = try Fixtures.load("affiliates_147_2024.json")
        let mock = MockAPIClient()
        mock.stub(path: "teams/147/affiliates", data: data)

        let affiliates = try await QueryBuilder<[Team]>.affiliates(teamId: 147, season: 2024, client: mock).fetch()

        #expect(affiliates.count == 4)
    }

    @Test("affiliates includes MLB parent team with no parentOrgId")
    func affiliatesMLBTeam() async throws {
        let data = try Fixtures.load("affiliates_147_2024.json")
        let mock = MockAPIClient()
        mock.stub(path: "teams/147/affiliates", data: data)

        let affiliates = try await QueryBuilder<[Team]>.affiliates(teamId: 147, season: 2024, client: mock).fetch()

        let yankees = try #require(affiliates.first { $0.id == 147 })
        #expect(yankees.parentOrgId == nil)
        #expect(yankees.parentOrgName == nil)
        #expect(yankees.sportName == "Major League Baseball")
    }

    @Test("affiliates includes minor league teams with parentOrg fields")
    func affiliatesMinorLeagueTeam() async throws {
        let data = try Fixtures.load("affiliates_147_2024.json")
        let mock = MockAPIClient()
        mock.stub(path: "teams/147/affiliates", data: data)

        let affiliates = try await QueryBuilder<[Team]>.affiliates(teamId: 147, season: 2024, client: mock).fetch()

        let swb = try #require(affiliates.first { $0.id == 531 })
        #expect(swb.name == "Scranton/Wilkes-Barre RailRiders")
        #expect(swb.sportName == "Triple-A")
        #expect(swb.parentOrgId == 147)
        #expect(swb.parentOrgName == "New York Yankees")

        let somerset = try #require(affiliates.first { $0.id == 1956 })
        #expect(somerset.sportName == "Double-A")
        #expect(somerset.parentOrgId == 147)

        let tampa = try #require(affiliates.first { $0.id == 587 })
        #expect(tampa.sportName == "Single-A")
    }

    @Test("affiliates query uses correct path and season param")
    func affiliatesQueryBuilder() async throws {
        let data = try Fixtures.load("affiliates_147_2024.json")
        let mock = MockAPIClient()
        mock.stub(path: "teams/147/affiliates", data: data)

        _ = try await QueryBuilder<[Team]>.affiliates(teamId: 147, season: 2024, client: mock).fetch()

        #expect(mock.lastEndpoint?.path == "teams/147/affiliates")
        let seasonItem = mock.lastEndpoint?.queryItems.first { $0.name == "season" }
        #expect(seasonItem?.value == "2024")
    }

    @Test("SwiftBaseball.affiliates returns correct type")
    func namespacedAffiliates() {
        _ = SwiftBaseball.affiliates(teamId: 147, season: 2024)
    }

    // MARK: - Minor league roster

    @Test("Decode minor league roster fixture")
    func decodeMinorLeagueRoster() throws {
        let data = try Fixtures.load("roster_531_2024.json")
        let response = try JSONDecoder.mlb.decode(MLBRosterResponse.self, from: data)
        let entries = response.roster.map(MLBResponseConverters.rosterEntry)

        #expect(entries.count == 3)
        let first = try #require(entries.first { $0.person.id == 656185 })
        #expect(first.person.fullName == "Greg Allen")
        #expect(first.position == .centerField)
        #expect(first.status == "Active")
    }

    @Test("roster() with minor league teamId uses correct path")
    func minorLeagueRosterQueryBuilder() async throws {
        let data = try Fixtures.load("roster_531_2024.json")
        let mock = MockAPIClient()
        mock.stub(path: "teams/531/roster", data: data)

        let entries = try await QueryBuilder<[RosterEntry]>.roster(
            teamId: 531, season: 2024, client: mock
        ).fetch()

        #expect(entries.count == 3)
        #expect(mock.lastEndpoint?.path == "teams/531/roster")
    }

    @Test("roster() sends rosterType=fullSeason for fullSeason")
    func rosterQueryBuilderFullSeason() async throws {
        let mock = MockAPIClient()
        let data = try Fixtures.load("roster_531_2024.json")
        mock.stub(path: "teams/531/roster", data: data)

        _ = try await QueryBuilder<[RosterEntry]>.roster(
            teamId: 531, season: 2024, rosterType: .fullSeason, client: mock
        ).fetch()

        let rosterTypeItem = mock.lastEndpoint?.queryItems.first { $0.name == "rosterType" }
        #expect(rosterTypeItem?.value == "fullSeason")
    }

    // MARK: - Division enum

    @Test("Division enum maps correctly to league")
    func divisionLeagueMapping() {
        #expect(Division.alEast.league == .american)
        #expect(Division.alCentral.league == .american)
        #expect(Division.alWest.league == .american)
        #expect(Division.nlEast.league == .national)
        #expect(Division.nlCentral.league == .national)
        #expect(Division.nlWest.league == .national)
    }

    @Test("League enum has correct API IDs")
    func leagueIds() {
        #expect(League.american.leagueId == 103)
        #expect(League.national.leagueId == 104)
    }
}
