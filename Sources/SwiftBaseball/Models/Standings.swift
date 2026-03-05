import Foundation

/// A team's record within division standings.
///
/// Includes win-loss record, rankings, and run differential.
public struct StandingsRecord: Codable, Sendable, Equatable {
    /// Reference to the team.
    public let team: TeamReference
    /// Total wins.
    public let wins: Int
    /// Total losses.
    public let losses: Int
    /// Winning percentage (0.0–1.0).
    public let winningPercentage: Double
    /// Games behind the division leader, or `nil` for the leader.
    public let gamesBack: Double?
    /// Games behind in the wild card race.
    public let wildCardGamesBack: Double?
    /// Rank within the division.
    public let divisionRank: Int
    /// Rank within the league.
    public let leagueRank: Int
    /// Wild card rank, if applicable.
    public let wildCardRank: Int?
    /// Whether this team has clinched the division.
    public let divisionChamp: Bool
    /// Whether this team currently leads the division.
    public let divisionLeader: Bool
    /// Whether this team holds a wild card spot.
    public let hasWildCard: Bool
    /// Whether the team has clinched a playoff spot.
    public let clinched: Bool
    /// Elimination number, or `nil` if eliminated or clinched.
    public let eliminationNumber: String?
    /// Current win/loss streak.
    public let streak: Streak
    /// Record over the last 10 games.
    public let lastTen: LastTen
    /// Total runs allowed.
    public let runsAllowed: Int?
    /// Total runs scored.
    public let runsScored: Int?
    /// Run differential (runs scored minus runs allowed).
    public let runDifferential: Int?

    /// Total games played (wins + losses).
    public var gamesPlayed: Int { wins + losses }
}

/// A team's current win or loss streak.
public struct Streak: Codable, Sendable, Equatable {
    /// Streak type ("W" for wins, "L" for losses).
    public let streakType: String?
    /// Number of consecutive wins or losses.
    public let streakNumber: Int?
    /// Short code (e.g. "W3", "L2").
    public let streakCode: String?
}

/// A team's record over the last 10 games.
public struct LastTen: Codable, Sendable, Equatable {
    /// Wins in the last 10 games.
    public let wins: Int
    /// Losses in the last 10 games.
    public let losses: Int
    /// Winning percentage as a string (e.g. ".700").
    public let pct: String
}

/// Standings for one division, containing all team records.
///
/// Returned by ``SwiftBaseball/standings()`` queries.
public struct DivisionStandings: Codable, Sendable, Equatable {
    /// Reference to the division.
    public let division: DivisionReference
    /// Team records sorted by division rank.
    public let teamRecords: [StandingsRecord]
}
