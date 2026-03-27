import Foundation

// MARK: - Sprint Speed

/// A single player's sprint speed entry from the Baseball Savant sprint-speed leaderboard.
///
/// Sprint speed is measured as feet per second on competitive runs (max effort sprints
/// of at least 90 feet), sourced from Baseball Savant's tracking system.
public struct SprintSpeedEntry: Sendable, Equatable, Codable {
    /// MLB player ID.
    public let playerId: Int
    /// Player's full name as returned by the leaderboard.
    public let playerName: String
    /// Team abbreviation (e.g. "LAD").
    public let team: String
    /// Season year.
    public let season: Int
    /// Sprint speed in feet per second.
    public let sprintSpeed: Double
    /// Number of competitive sprint attempts in the sample.
    public let sprintAttempts: Int
    /// Percentile rank among all qualified players (1–99). `nil` if not provided.
    public let percentile: Int?
    /// Home-to-first time in seconds. `nil` if not provided.
    public let homeToFirst: Double?
}

// MARK: - Catcher Framing

/// A single catcher's framing entry from the Baseball Savant catcher framing leaderboard.
///
/// Framing runs added (`framingRunsAdded`) measures how many runs of value a catcher
/// generates by converting borderline pitches into called strikes above what an average
/// catcher would. Positive values indicate elite framers; negative values indicate
/// below-average framers.
///
/// - Note: Team is not included in the Baseball Savant framing CSV export.
///   Use ``playerId`` to look up team via ``SwiftBaseball/players(ids:)``.
public struct CatcherFramingEntry: Sendable, Equatable, Codable {
    /// MLB player ID.
    public let playerId: Int
    /// Player's full name as returned by the leaderboard (Last, First format).
    public let playerName: String
    /// Season year.
    public let season: Int
    /// Framing runs added above average. Positive = elite framer, negative = below average.
    public let framingRunsAdded: Double
    /// Overall called strike rate on all pitches (0–1 scale).
    public let calledStrikeRate: Double
    /// Total pitches received in the sample.
    public let pitchesSeen: Int
}

// MARK: - Outs Above Average

/// A single player's Outs Above Average (OAA) entry from the Baseball Savant leaderboard.
///
/// OAA measures how many outs a fielder creates above or below the average fielder,
/// accounting for the difficulty of each play based on Statcast tracking data.
public struct OutsAboveAverageEntry: Sendable, Equatable, Codable {
    /// MLB player ID.
    public let playerId: Int
    /// Player's full name as returned by the leaderboard.
    public let playerName: String
    /// Team abbreviation (e.g. "LAD").
    public let team: String
    /// Season year.
    public let season: Int
    /// Outs Above Average (positive = above average, negative = below).
    public let oaa: Double
    /// Total fielding attempts used in the OAA calculation. `nil` if not provided.
    public let fielderAttempts: Int?
    /// Percentile rank among all qualified players (1–99). `nil` if not provided.
    public let percentile: Int?
    /// Primary fielding position (e.g. "SS", "CF"). `nil` if not provided.
    public let position: String?
}
