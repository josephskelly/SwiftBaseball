import Foundation

/// A single entry in a league leaders list.
public struct LeaderEntry: Codable, Sendable, Equatable {
    /// Rank within the leader category (1-based).
    public let rank: Int
    /// Stat value as a string (e.g. "45", ".330").
    public let value: String
    /// Reference to the player.
    public let player: PlayerReference
    /// Reference to the player's team, if available.
    public let team: TeamReference?
    /// Season year (e.g. "2024").
    public let season: String?
    /// Player's rank within the league.
    public let leagueRank: Int?
}

/// A category of league leaders (e.g. home runs, batting average).
///
/// Returned by ``SwiftBaseball/leaders(_:)`` queries.
public struct LeaderCategory: Codable, Sendable, Equatable {
    /// Category name (e.g. "homeRuns", "battingAverage").
    public let leaderCategory: String
    /// Ordered list of leader entries for this category.
    public let leaders: [LeaderEntry]
}

/// A category of team leaders for a single stat, stat group, and season.
///
/// Returned by ``SwiftBaseball/teamLeaders(teamId:category:)``. The upstream
/// endpoint returns one ``TeamLeaderCategory`` per (category, stat group)
/// pair — so asking for `.homeRuns` yields two entries, one with
/// ``statGroup`` `.batting` (position-player HR leaders) and one with
/// `.pitching` (pitchers who allowed the most HR).
public struct TeamLeaderCategory: Codable, Sendable, Equatable {
    /// Category name (e.g. `"homeRuns"`, `"battingAverage"`).
    public let leaderCategory: String
    /// Stat group this split belongs to.
    ///
    /// `nil` when the upstream API reports an unrecognized group. Use this to
    /// distinguish hitting leaders from pitching leaders when the same stat
    /// category exists in both groups (home runs, strikeouts, etc.).
    public let statGroup: StatGroup?
    /// Season (e.g. `"2024"`), when scoped to a single season. Empty for
    /// career/all-time leader queries.
    public let season: String
    /// Game type the record covers (regular season, postseason, …). `nil`
    /// when the upstream API omits it or the code is unrecognized.
    public let gameType: GameType?
    /// Team whose leaders are listed.
    public let team: TeamReference
    /// Total number of split entries the API had available — often higher
    /// than ``leaders``.count when the endpoint applies an implicit cap.
    public let totalSplits: Int?
    /// Ranked leader entries for this category. Order matches the API.
    public let leaders: [LeaderEntry]
}

// MARK: - Common stat categories

/// Predefined stat categories for leader queries.
///
/// Use with ``SwiftBaseball/leaders(_:)`` to query specific leaderboards.
public enum LeaderStatCategory: String, Codable, Sendable, CaseIterable {
    /// Batting
    /// Home runs.
    case homeRuns
    /// Batting average.
    case battingAverage
    /// On-base plus slugging.
    case onBasePlusSlugging
    /// Runs batted in.
    case rbi
    /// Base hits.
    case hits
    /// Stolen bases.
    case stolenBases
    /// Runs scored.
    case runs
    /// Doubles.
    case doubles
    /// Triples.
    case triples

    /// Pitching
    /// Earned run average.
    case earnedRunAverage
    /// Pitcher wins.
    case wins
    /// Pitcher strikeouts.
    case strikeouts
    /// Saves.
    case saves
    /// Walks plus hits per inning pitched.
    case whip
    /// Innings pitched.
    case inningsPitched
    /// Walks and hits per inning pitched (full name).
    case walksAndHitsPerInningPitched
    /// Strikeouts per 9 innings.
    case strikeoutsPer9Inn
}
