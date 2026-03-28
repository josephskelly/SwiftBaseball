import Foundation

/// An MLB or minor league team with full organizational details.
///
/// Returned by ``SwiftBaseball/teams(_:)``, ``SwiftBaseball/team(id:)``, and
/// ``SwiftBaseball/affiliates(teamId:season:)`` queries. Minor league teams
/// include ``parentOrgId``, ``parentOrgName``, and ``sportName`` to identify
/// the MLB parent organization and competition level.
public struct Team: Codable, Sendable, Equatable, Identifiable {
    /// MLB team ID.
    public let id: Int
    /// Full team name (e.g. "New York Yankees", "Scranton/Wilkes-Barre RailRiders").
    public let name: String
    /// Team name without location (e.g. "Yankees", "RailRiders").
    public let teamName: String
    /// Location/city name (e.g. "New York", "Moosic").
    public let locationName: String
    /// Standard abbreviation (e.g. "NYY", "SWB").
    public let abbreviation: String
    /// Short display name (e.g. "NY Yankees", "Scranton/WB").
    public let shortName: String
    /// Franchise name (e.g. "Yankees").
    public let franchiseName: String?
    /// Club name (e.g. "Yankees", "RailRiders").
    public let clubName: String?
    /// Season year this team record applies to.
    public let season: Int?
    /// First year the franchise began play (as a string, e.g. "1901").
    public let firstYearOfPlay: String?
    /// Whether the team is currently active.
    public let active: Bool
    /// Reference to the team's league.
    public let league: LeagueReference
    /// Reference to the team's division.
    public let division: DivisionReference
    /// Reference to the team's home venue.
    public let venue: VenueReference
    /// Human-readable sport/level name (e.g. `"Triple-A"`, `"Double-A"`,
    /// `"Major League Baseball"`). `nil` for results that predate sport-level
    /// hydration in the MLB Stats API.
    public let sportName: String?
    /// MLB ID of the parent organization for minor league affiliates.
    /// `nil` for MLB teams and top-level organizations.
    public let parentOrgId: Int?
    /// Name of the parent MLB organization (e.g. `"New York Yankees"`).
    /// `nil` for MLB teams.
    public let parentOrgName: String?
}
