import Foundation

/// An MLB player with biographical and career information.
///
/// Returned by ``SwiftBaseball/players(_:)`` and related queries.
public struct Player: Codable, Sendable, Equatable, Identifiable {
    /// MLB player ID.
    public let id: Int
    /// Full display name (e.g. "Shohei Ohtani").
    public let fullName: String
    /// First name.
    public let firstName: String
    /// Last name.
    public let lastName: String
    /// Jersey number as a string (e.g. "17").
    public let primaryNumber: String?
    /// Date of birth.
    public let birthDate: Date?
    /// Current age in years.
    public let currentAge: Int?
    /// Birth city.
    public let birthCity: String?
    /// Birth country.
    public let birthCountry: String?
    /// Height as a formatted string (e.g. "6' 4\"").
    public let height: String?
    /// Weight in pounds.
    public let weight: Int?
    /// Whether the player is on an active MLB roster.
    public let active: Bool
    /// Primary defensive position.
    public let primaryPosition: Position
    /// Batting side (left, right, or switch).
    public let batSide: HandSide
    /// Throwing hand.
    public let pitchHand: HandSide
    /// Reference to the player's current team, if any.
    public let currentTeam: TeamReference?
    /// Date of MLB debut.
    public let mlbDebutDate: Date?
}

/// A roster entry linking a player to a team and role.
///
/// Returned by ``SwiftBaseball/roster(teamId:)`` queries.
public struct RosterEntry: Codable, Sendable, Equatable, Identifiable {
    /// Computed from the person's MLB ID.
    public var id: Int { person.id }
    /// Reference to the rostered player.
    public let person: PlayerReference
    /// Jersey number as a string.
    public let jerseyNumber: String?
    /// Defensive position on the roster.
    public let position: Position
    /// Roster status description (e.g. "Active").
    public let status: String?
}
