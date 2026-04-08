import Testing
import Foundation
@testable import SwiftBaseball

@Suite("Enum Tests")
struct EnumTests {

    // MARK: - Position

    @Test("All Position cases round-trip through rawValue", arguments: Position.allCases)
    func positionRoundTrip(_ position: Position) {
        #expect(Position(rawValue: position.rawValue) == position)
    }

    @Test("All Position cases have non-empty displayName", arguments: Position.allCases)
    func positionDisplayName(_ position: Position) {
        #expect(!position.displayName.isEmpty)
    }

    @Test("Position.unknown is the fallback for unrecognized codes")
    func positionUnknownFallback() {
        #expect(Position(rawValue: "ZZZ") == nil)  // rawValue init returns nil
        // The lenient JSON decoder maps unrecognized to .unknown
        let json = #""ZZZZZ""#.data(using: .utf8)!
        let decoded = try? JSONDecoder().decode(Position.self, from: json)
        #expect(decoded == .unknown)
    }

    // MARK: - HandSide

    @Test("All HandSide cases round-trip through rawValue", arguments: HandSide.allCases)
    func handSideRoundTrip(_ side: HandSide) {
        #expect(HandSide(rawValue: side.rawValue) == side)
    }

    @Test("HandSide.unknown is the fallback for unrecognized codes")
    func handSideUnknownFallback() {
        let json = #""X""#.data(using: .utf8)!
        let decoded = try? JSONDecoder().decode(HandSide.self, from: json)
        #expect(decoded == .unknown)
    }

    // MARK: - GameType

    @Test("All GameType cases round-trip through rawValue", arguments: GameType.allCases)
    func gameTypeRoundTrip(_ type: GameType) {
        #expect(GameType(rawValue: type.rawValue) == type)
    }

    @Test("GameType.exhibition decodes from 'E'")
    func gameTypeExhibition() {
        let json = #""E""#.data(using: .utf8)!
        let decoded = try? JSONDecoder().decode(GameType.self, from: json)
        #expect(decoded == .exhibition)
    }

    @Test("All GameType cases have non-empty displayName", arguments: GameType.allCases)
    func gameTypeDisplayName(_ type: GameType) {
        #expect(!type.displayName.isEmpty)
    }

    @Test("GameType.unknown is the fallback for unrecognized codes")
    func gameTypeUnknownFallback() {
        let json = #""X""#.data(using: .utf8)!
        let decoded = try? JSONDecoder().decode(GameType.self, from: json)
        #expect(decoded == .unknown)
    }

    // MARK: - GameStatus

    @Test("All GameStatus cases round-trip through rawValue", arguments: GameStatus.allCases)
    func gameStatusRoundTrip(_ status: GameStatus) {
        #expect(GameStatus(rawValue: status.rawValue) == status)
    }

    @Test("GameStatus.scheduled is the fallback for unrecognized codes")
    func gameStatusUnknownFallback() {
        let json = #""NotAStatus""#.data(using: .utf8)!
        let decoded = try? JSONDecoder().decode(GameStatus.self, from: json)
        #expect(decoded == .scheduled)
    }

    @Test("GameStatus new cases round-trip through rawValue")
    func gameStatusNewCasesRoundTrip() {
        let cases: [(GameStatus, String)] = [
            (.preGame,        "Pre-Game"),
            (.completedEarly, "Completed Early"),
            (.gameOver,       "Game Over"),
            (.rainDelay,      "Rain Delay"),
            (.delayed,        "Delayed"),
            (.delayedStart,   "Delayed Start"),
        ]
        for (status, raw) in cases {
            #expect(GameStatus(rawValue: raw) == status)
            #expect(status.rawValue == raw)
        }
    }

    // MARK: - StatGroup

    @Test("All StatGroup cases round-trip through rawValue", arguments: StatGroup.allCases)
    func statGroupRoundTrip(_ group: StatGroup) {
        #expect(StatGroup(rawValue: group.rawValue) == group)
    }

    @Test("StatGroup apiValue is non-empty for all cases", arguments: StatGroup.allCases)
    func statGroupApiValue(_ group: StatGroup) {
        #expect(!group.apiValue.isEmpty)
    }

    // MARK: - Division

    @Test("All Division cases map to the correct league", arguments: Division.allCases)
    func divisionLeague(_ division: Division) {
        switch division {
        case .alEast, .alCentral, .alWest:
            #expect(division.league == .american)
        case .nlEast, .nlCentral, .nlWest:
            #expect(division.league == .national)
        }
    }

    @Test("All Division cases have non-empty displayName", arguments: Division.allCases)
    func divisionDisplayName(_ division: Division) {
        #expect(!division.displayName.isEmpty)
    }

    // MARK: - RosterType

    @Test("RosterType.active has correct rawValue")
    func rosterTypeActiveRawValue() {
        #expect(RosterType.active.rawValue == "active")
    }

    @Test("RosterType.fortyMan has correct rawValue for API")
    func rosterTypeFortyManRawValue() {
        #expect(RosterType.fortyMan.rawValue == "40Man")
    }

    @Test("RosterType.nonRosterInvitees has correct rawValue")
    func rosterTypeNRIRawValue() {
        #expect(RosterType.nonRosterInvitees.rawValue == "nonRosterInvitees")
    }

    @Test("All RosterType cases round-trip through rawValue", arguments: RosterType.allCases)
    func rosterTypeRoundTrip(_ type: RosterType) {
        #expect(RosterType(rawValue: type.rawValue) == type)
    }
}
