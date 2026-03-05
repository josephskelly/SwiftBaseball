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

// MARK: - Common stat categories

/// Predefined stat categories for leader queries.
///
/// Use with ``SwiftBaseball/leaders(_:)`` to query specific leaderboards.
public enum LeaderStatCategory: String, Codable, Sendable, CaseIterable {
    // Batting
    /// Home runs.
    case homeRuns             = "homeRuns"
    /// Batting average.
    case battingAverage       = "battingAverage"
    /// On-base plus slugging.
    case onBasePlusSlugging   = "onBasePlusSlugging"
    /// Runs batted in.
    case rbi                  = "rbi"
    /// Base hits.
    case hits                 = "hits"
    /// Stolen bases.
    case stolenBases          = "stolenBases"
    /// Runs scored.
    case runs                 = "runs"
    /// Doubles.
    case doubles              = "doubles"
    /// Triples.
    case triples              = "triples"
    /// Strikeouts per 9 innings (pitching).
    case strikeoutsPer9Inn    = "strikeoutsPer9Inn"

    // Pitching
    /// Earned run average.
    case earnedRunAverage     = "earnedRunAverage"
    /// Pitcher wins.
    case wins                 = "wins"
    /// Pitcher strikeouts.
    case strikeouts           = "strikeouts"
    /// Saves.
    case saves                = "saves"
    /// Walks plus hits per inning pitched.
    case whip                 = "whip"
    /// Innings pitched.
    case inningsPitched       = "inningsPitched"
    /// Walks and hits per inning pitched (full name).
    case walksAndHitsPerInningPitched = "walksAndHitsPerInningPitched"
}
