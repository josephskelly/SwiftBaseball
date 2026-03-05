import Foundation

/// An MLB team with full organizational details.
///
/// Returned by ``SwiftBaseball/teams()`` and ``SwiftBaseball/team(id:)`` queries.
public struct Team: Codable, Sendable, Equatable, Identifiable {
    /// MLB team ID.
    public let id: Int
    /// Full team name (e.g. "New York Yankees").
    public let name: String
    /// Team name without location (e.g. "Yankees").
    public let teamName: String
    /// Location/city name (e.g. "New York").
    public let locationName: String
    /// Standard abbreviation (e.g. "NYY").
    public let abbreviation: String
    /// Short display name (e.g. "NY Yankees").
    public let shortName: String
    /// Franchise name (e.g. "Yankees").
    public let franchiseName: String?
    /// Club name (e.g. "Yankees").
    public let clubName: String?
    /// Season year this team record applies to.
    public let season: Int?
    /// First year the franchise began play (as a string, e.g. "1901").
    public let firstYearOfPlay: String?
    /// Whether the team is currently active in MLB.
    public let active: Bool
    /// Reference to the team's league.
    public let league: LeagueReference
    /// Reference to the team's division.
    public let division: DivisionReference
    /// Reference to the team's home venue.
    public let venue: VenueReference
}
