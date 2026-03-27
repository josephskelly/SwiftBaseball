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
