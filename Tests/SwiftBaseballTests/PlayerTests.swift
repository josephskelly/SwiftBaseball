import Testing
import Foundation
@testable import SwiftBaseball

@Suite("Player Tests")
struct PlayerTests {

    // MARK: - Decode single player (Ohtani)

    @Test("Decode Ohtani from fixture")
    func decodeOhtani() throws {
        let data = try Fixtures.load("player_660271.json")
        let response = try JSONDecoder.mlb.decode(MLBPeopleResponse.self, from: data)

        #expect(response.people.count == 1)

        let raw = try #require(response.people.first)
        let player = MLBResponseConverters.player(from: raw)

        #expect(player.id == 660271)
        #expect(player.fullName == "Shohei Ohtani")
        #expect(player.firstName == "Shohei")
        #expect(player.lastName == "Ohtani")
        #expect(player.primaryNumber == "17")
        #expect(player.active == true)
        #expect(player.primaryPosition == .twoWayPlayer)
        #expect(player.batSide == .left)
        #expect(player.pitchHand == .right)
        #expect(player.currentTeam?.id == 119)
        #expect(player.currentTeam?.name == "Los Angeles Dodgers")
        #expect(player.weight == 210)
        #expect(player.birthCountry == "Japan")
        #expect(player.birthCity == "Oshu")
    }

    // MARK: - Decode single player (Judge)

    @Test("Decode Judge from fixture")
    func decodeJudge() throws {
        let data = try Fixtures.load("player_592450.json")
        let response = try JSONDecoder.mlb.decode(MLBPeopleResponse.self, from: data)
        let raw = try #require(response.people.first)
        let player = MLBResponseConverters.player(from: raw)

        #expect(player.id == 592450)
        #expect(player.fullName == "Aaron Judge")
        #expect(player.firstName == "Aaron")
        #expect(player.lastName == "Judge")
        #expect(player.primaryNumber == "99")
        #expect(player.active == true)
        #expect(player.primaryPosition == .rightField)
        #expect(player.batSide == .right)
        #expect(player.pitchHand == .right)
        #expect(player.currentTeam?.id == 147)
        #expect(player.currentTeam?.name == "New York Yankees")
        #expect(player.weight == 282)
        #expect(player.height == "6' 7\"")
        #expect(player.birthCountry == "USA")
    }

    // MARK: - Date parsing

    @Test("Decode player birth date")
    func decodePlayerBirthDate() throws {
        let data = try Fixtures.load("player_660271.json")
        let response = try JSONDecoder.mlb.decode(MLBPeopleResponse.self, from: data)
        let raw = try #require(response.people.first)
        let player = MLBResponseConverters.player(from: raw)

        let birthDate = try #require(player.birthDate)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let components = calendar.dateComponents([.year, .month, .day], from: birthDate)

        #expect(components.year == 1994)
        #expect(components.month == 7)
        #expect(components.day == 5)
    }

    @Test("Decode player MLB debut date")
    func decodePlayerDebutDate() throws {
        let data = try Fixtures.load("player_660271.json")
        let response = try JSONDecoder.mlb.decode(MLBPeopleResponse.self, from: data)
        let raw = try #require(response.people.first)
        let player = MLBResponseConverters.player(from: raw)

        let debutDate = try #require(player.mlbDebutDate)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let components = calendar.dateComponents([.year, .month, .day], from: debutDate)

        #expect(components.year == 2018)
        #expect(components.month == 3)
        #expect(components.day == 29)
    }

    // MARK: - Player search

    @Test("Decode player search results")
    func decodePlayerSearch() throws {
        let data = try Fixtures.load("player_search_ohtani.json")
        let response = try JSONDecoder.mlb.decode(MLBPeopleResponse.self, from: data)
        let players = response.people.map(MLBResponseConverters.player)

        #expect(players.count >= 1)
        let ohtani = try #require(players.first { $0.id == 660271 })
        #expect(ohtani.fullName == "Shohei Ohtani")
        #expect(ohtani.currentTeam?.id == 119)
    }

    @Test("Empty search returns empty array")
    func emptySearchReturnsEmptyArray() throws {
        let data = try Fixtures.load("player_search_empty.json")
        let response = try JSONDecoder.mlb.decode(MLBPeopleResponse.self, from: data)
        let players = response.people.map(MLBResponseConverters.player)

        #expect(players.isEmpty)
    }

    // MARK: - QueryBuilder via mock

    @Test("players(.search()) query builder uses correct path and hydration")
    func playerSearchQueryBuilder() async throws {
        let mock = MockAPIClient()
        let data = try Fixtures.load("player_search_ohtani.json")
        mock.stub(path: "people/search", data: data)

        let builder = QueryBuilder<[Player]>.players(.search("Ohtani"), client: mock)
        let players = try await builder.fetch()

        #expect(!players.isEmpty)
        #expect(mock.lastEndpoint?.path == "people/search")

        let hydrateItem = mock.lastEndpoint?.queryItems.first { $0.name == "hydrate" }
        #expect(hydrateItem?.value == "currentTeam")
    }

    @Test("player(id:) query builder uses correct path and hydration")
    func singlePlayerQueryBuilder() async throws {
        let mock = MockAPIClient()
        let data = try Fixtures.load("player_660271.json")
        mock.stub(path: "people/660271", data: data)

        let builder = QueryBuilder<Player>.singlePlayer(id: 660271, client: mock)
        let player = try await builder.fetch()

        #expect(player.id == 660271)
        #expect(mock.lastEndpoint?.path == "people/660271")

        let hydrateItem = mock.lastEndpoint?.queryItems.first { $0.name == "hydrate" }
        #expect(hydrateItem?.value == "currentTeam")
    }

    @Test("playerNotFound error thrown when no people returned")
    func playerNotFoundError() async throws {
        let mock = MockAPIClient()
        let emptyResponse = #"{"people": []}"#.data(using: .utf8)!
        mock.stub(path: "people/999999", data: emptyResponse)

        let builder = QueryBuilder<Player>.singlePlayer(id: 999999, client: mock)

        await #expect(throws: SwiftBaseballError.self) {
            _ = try await builder.fetch()
        }
    }

    // MARK: - Position enum

    @Test("Position decodes known MLB codes")
    func positionDecodesKnownCodes() {
        #expect(Position(rawValue: "1") == .pitcher)
        #expect(Position(rawValue: "2") == .catcher)
        #expect(Position(rawValue: "3") == .firstBase)
        #expect(Position(rawValue: "4") == .secondBase)
        #expect(Position(rawValue: "5") == .thirdBase)
        #expect(Position(rawValue: "6") == .shortstop)
        #expect(Position(rawValue: "7") == .leftField)
        #expect(Position(rawValue: "8") == .centerField)
        #expect(Position(rawValue: "9") == .rightField)
        #expect(Position(rawValue: "10") == .designatedHitter)
        #expect(Position(rawValue: "Y") == .twoWayPlayer)
    }

    @Test("Position falls back to unknown for unrecognized codes via JSON decoding")
    func positionFallsBackToUnknown() throws {
        let json = #""ZZZZZ""#.data(using: .utf8)!
        let decoded = try JSONDecoder().decode(Position.self, from: json)
        #expect(decoded == .unknown)
    }

    // MARK: - HandSide enum

    @Test("HandSide decodes L/R/S codes")
    func handSideDecoding() {
        #expect(HandSide(rawValue: "L") == .left)
        #expect(HandSide(rawValue: "R") == .right)
        #expect(HandSide(rawValue: "S") == .both)
    }

    // MARK: - Player model Equatable

    @Test("Player models with same data are equal")
    func playerEquality() throws {
        let data = try Fixtures.load("player_660271.json")
        let response = try JSONDecoder.mlb.decode(MLBPeopleResponse.self, from: data)
        let raw = try #require(response.people.first)
        let player1 = MLBResponseConverters.player(from: raw)
        let player2 = MLBResponseConverters.player(from: raw)

        #expect(player1 == player2)
    }
}
