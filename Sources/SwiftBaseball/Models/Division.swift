import Foundation

/// A division entry from the MLB Stats API's `/divisions` catalog.
///
/// Returned by ``SwiftBaseball/divisions(sportId:)``. Covers every division
/// across the MLB, minor leagues, and any other league the API tracks —
/// e.g. AL East, NL Central, International League North, etc.
///
/// Distinct from ``Division`` — the ``Division`` enum is a compile-time set
/// of MLB's six divisions used to scope standings queries. This struct is
/// the full catalog record for any division tracked by the API.
public struct DivisionCatalog: Codable, Sendable, Equatable, Identifiable {
    /// Stable division identifier.
    public let id: Int
    /// Full division name (e.g. `"American League East"`).
    public let name: String
    /// Short form of the division name (e.g. `"AL East"`).
    public let nameShort: String?
    /// Display abbreviation (e.g. `"ALE"`).
    public let abbreviation: String?
    /// Season this catalog record applies to (e.g. `"2026"`).
    public let season: String?
    /// Identifier of the league this division belongs to.
    public let leagueId: Int?
    /// Identifier of the sport this division belongs to.
    public let sportId: Int?
    /// Whether the division awards a wild-card berth.
    public let hasWildcard: Bool?
    /// Number of teams from this division that advance to the postseason.
    public let numPlayoffTeams: Int?
    /// Sort order used by MLB to group divisions in UI.
    public let sortOrder: Int?
    /// Whether the division is currently active.
    public let active: Bool
}
