import Foundation

/// A league entry from the MLB Stats API's `/leagues` catalog.
///
/// Returned by ``SwiftBaseball/leagues(sportId:)``. Covers MLB leagues
/// (American `id: 103`, National `id: 104`), every minor league association
/// and classification, spring training leagues, independent leagues, and
/// historical leagues including the Negro Leagues.
///
/// Distinct from ``League`` — the ``League`` enum is a compile-time set of
/// MLB leagues (AL/NL) used to scope standings queries. This struct is the
/// full catalog record for any league tracked by the API.
public struct LeagueCatalog: Codable, Sendable, Equatable, Identifiable {
    /// Stable league identifier.
    public let id: Int
    /// Full league name (e.g. `"American League"`).
    public let name: String
    /// Short form of the league name (e.g. `"American"`).
    public let nameShort: String?
    /// Display abbreviation (e.g. `"AL"`).
    public let abbreviation: String?
    /// Season this catalog record applies to (e.g. `"2026"`).
    public let season: String?
    /// Machine code MLB uses internally (e.g. `"AL"`).
    public let orgCode: String?
    /// Whether the league is currently active.
    public let active: Bool
    /// Identifier of the sport this league belongs to (see ``SportCatalog``).
    public let sportId: Int?
    /// Whether the league uses wild-card playoff berths.
    public let hasWildCard: Bool?
    /// Whether the league is split into two halves.
    public let hasSplitSeason: Bool?
    /// Whether standings are tracked by playoff points rather than W/L.
    public let hasPlayoffPoints: Bool?
    /// Total number of regular-season games played per team.
    public let numGames: Int?
    /// Number of teams in the league.
    public let numTeams: Int?
    /// Number of wild-card playoff berths.
    public let numWildcardTeams: Int?
    /// Whether the league is split into conferences.
    public let conferencesInUse: Bool?
    /// Whether the league is split into divisions.
    public let divisionsInUse: Bool?
    /// Current stage of the season (e.g. `"inseason"`, `"offseason"`).
    public let seasonState: String?
    /// Sort order used by MLB to group leagues in UI.
    public let sortOrder: Int?
    /// Key calendar dates for the league's season.
    public let seasonDates: LeagueSeasonDates?
}

/// Key calendar boundaries for a single league season.
///
/// Every field is optional because individual leagues omit phases that don't
/// apply to them — e.g. independent leagues have no postseason, and many
/// minor leagues don't track an all-star break.
public struct LeagueSeasonDates: Codable, Sendable, Equatable {
    /// Season identifier (typically a year, e.g. `"2026"`).
    public let seasonId: String?
    /// First day of pre-season activity.
    public let preSeasonStart: Date?
    /// Last day of pre-season activity.
    public let preSeasonEnd: Date?
    /// First day the season is formally active.
    public let seasonStart: Date?
    /// Final day of the season's activity, including postseason.
    public let seasonEnd: Date?
    /// First day of spring training games.
    public let springStart: Date?
    /// Last day of spring training games.
    public let springEnd: Date?
    /// First day of the regular season.
    public let regularSeasonStart: Date?
    /// Last day of the regular season.
    public let regularSeasonEnd: Date?
    /// Last day of the first half (pre-All-Star-break).
    public let lastDate1stHalf: Date?
    /// Date of the All-Star Game.
    public let allStarDate: Date?
    /// First day of the second half (post-All-Star-break).
    public let firstDate2ndHalf: Date?
    /// First day of postseason play.
    public let postSeasonStart: Date?
    /// Last day of postseason play.
    public let postSeasonEnd: Date?
    /// First day of the offseason.
    public let offseasonStart: Date?
    /// Last day of the offseason.
    public let offseasonEnd: Date?
}
