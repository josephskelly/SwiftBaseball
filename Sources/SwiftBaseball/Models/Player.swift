import Foundation

public struct Player: Codable, Sendable, Equatable, Identifiable {
    public let id: Int
    public let fullName: String
    public let firstName: String
    public let lastName: String
    public let primaryNumber: String?
    public let birthDate: Date?
    public let currentAge: Int?
    public let birthCity: String?
    public let birthCountry: String?
    public let height: String?
    public let weight: Int?
    public let active: Bool
    public let primaryPosition: Position
    public let batSide: HandSide
    public let pitchHand: HandSide
    public let currentTeam: TeamReference?
    public let mlbDebutDate: Date?
}

/// A roster entry linking a player to a team and role.
public struct RosterEntry: Codable, Sendable, Equatable, Identifiable {
    public var id: Int { person.id }
    public let person: PlayerReference
    public let jerseyNumber: String?
    public let position: Position
    public let status: String?
}
