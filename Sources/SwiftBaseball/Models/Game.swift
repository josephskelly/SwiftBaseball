import Foundation

// MARK: - Boxscore

/// Full boxscore data for a completed or in-progress game.
///
/// Contains team-level and player-level stats for both teams.
/// Returned by ``SwiftBaseball/boxscore(gameId:)`` queries.
public struct Boxscore: Codable, Sendable, Equatable {
    /// Away and home team boxscore data.
    public let teams: BoxscoreTeams
    /// Game officials (umpires).
    public let officials: [Official]?
    /// Additional game information items (e.g. weather, attendance).
    public let info: [BoxscoreInfoItem]?
}

/// Container for away and home ``BoxscoreTeam`` data.
public struct BoxscoreTeams: Codable, Sendable, Equatable {
    /// Away team boxscore.
    public let away: BoxscoreTeam
    /// Home team boxscore.
    public let home: BoxscoreTeam
}

/// Boxscore data for one team in a game.
public struct BoxscoreTeam: Codable, Sendable, Equatable {
    /// Reference to the team.
    public let team: TeamReference
    /// Aggregate team stats (batting, pitching, fielding).
    public let teamStats: BoxscoreTeamStats
    /// Individual player stats keyed by `"ID{playerId}"`.
    public let players: [String: BoxscorePlayer]?
    /// Ordered list of batter player IDs.
    public let batters: [Int]?
    /// Ordered list of pitcher player IDs.
    public let pitchers: [Int]?
    /// Batting order player IDs.
    public let battingOrder: [Int]?
    /// Notes about the team's performance (e.g. double plays).
    public let note: [BoxscoreInfoItem]?
}

/// Aggregate batting, pitching, and fielding stats for a team in a game.
public struct BoxscoreTeamStats: Codable, Sendable, Equatable {
    /// Team batting totals.
    public let batting: BattingStats
    /// Team pitching totals.
    public let pitching: PitchingStats
    /// Team fielding totals.
    public let fielding: FieldingStats
}

/// An individual player's boxscore entry.
public struct BoxscorePlayer: Codable, Sendable, Equatable {
    /// Reference to the player.
    public let person: PlayerReference
    /// Jersey number.
    public let jerseyNumber: String?
    /// Position played in this game.
    public let position: Position
    /// Player's batting, pitching, and fielding stats for this game.
    public let stats: BoxscorePlayerStats
    /// Position in the batting order (e.g. "1", "2"), or `nil` if not in the lineup.
    public let battingOrder: String?
}

/// Batting, pitching, and fielding stats for one player in a game.
public struct BoxscorePlayerStats: Codable, Sendable, Equatable {
    /// Batting stats for this game.
    public let batting: BattingStats
    /// Pitching stats for this game.
    public let pitching: PitchingStats
    /// Fielding stats for this game.
    public let fielding: FieldingStats
}

/// A game official (umpire).
public struct Official: Codable, Sendable, Equatable {
    /// Reference to the official.
    public let official: PlayerReference
    /// Type of official (e.g. "Home Plate", "First Base").
    public let officialType: String
}

/// A labeled item in boxscore game info or notes.
public struct BoxscoreInfoItem: Codable, Sendable, Equatable {
    /// Label describing the info (e.g. "Weather", "Attendance").
    public let label: String
    /// Value of the info item.
    public let value: String?
}

// MARK: - Linescore

/// Inning-by-inning scoring summary for a game.
///
/// Includes per-inning lines, team totals, count, and current offensive/defensive positions.
/// Returned by ``SwiftBaseball/linescore(gameId:)`` queries.
public struct Linescore: Codable, Sendable, Equatable {
    /// Current inning number (1-based), or `nil` if game hasn't started.
    public let currentInning: Int?
    /// Ordinal display string (e.g. "7th").
    public let currentInningOrdinal: String?
    /// Current half of the inning ("Top" or "Bottom").
    public let inningHalf: String?
    /// Per-inning scoring lines.
    public let innings: [InningLine]
    /// Team run/hit/error totals.
    public let teams: LinescoreTeams
    /// Current out count.
    public let outs: Int?
    /// Current ball count on the batter.
    public let balls: Int?
    /// Current strike count on the batter.
    public let strikes: Int?
    /// Current offensive player positions (batter, baserunners).
    public let offense: LinescoreOffense?
    /// Current defensive player positions.
    public let defense: LinescoreDefense?
    /// Whether it is the top of the inning.
    public let isTopInning: Bool?
    /// Number of scheduled innings (typically 9).
    public let scheduledInnings: Int?
}

/// Scoring data for one inning.
public struct InningLine: Codable, Sendable, Equatable {
    /// Inning number (1-based).
    public let num: Int
    /// Ordinal display string (e.g. "1st").
    public let ordinalNum: String
    /// Home team scoring for this inning.
    public let home: InningScore
    /// Away team scoring for this inning.
    public let away: InningScore
}

/// Runs, hits, errors, and LOB for one team in one inning.
public struct InningScore: Codable, Sendable, Equatable {
    /// Runs scored.
    public let runs: Int?
    /// Hits.
    public let hits: Int?
    /// Errors committed.
    public let errors: Int?
    /// Runners left on base.
    public let leftOnBase: Int?
}

/// Container for home and away linescore totals.
public struct LinescoreTeams: Codable, Sendable, Equatable {
    /// Home team totals.
    public let home: LinescoreTeamTotals
    /// Away team totals.
    public let away: LinescoreTeamTotals
}

/// Total runs, hits, errors, and LOB for one team.
public struct LinescoreTeamTotals: Codable, Sendable, Equatable {
    /// Total runs scored.
    public let runs: Int?
    /// Total hits.
    public let hits: Int?
    /// Total errors.
    public let errors: Int?
    /// Total runners left on base.
    public let leftOnBase: Int?
}

/// Current offensive player positions during a live game.
public struct LinescoreOffense: Codable, Sendable, Equatable {
    /// Current batter.
    public let batter: PlayerReference?
    /// On-deck batter.
    public let onDeck: PlayerReference?
    /// In-the-hole batter.
    public let inHole: PlayerReference?
    /// Opposing pitcher.
    public let pitcher: PlayerReference?
    /// Runner on first base.
    public let first: PlayerReference?
    /// Runner on second base.
    public let second: PlayerReference?
    /// Runner on third base.
    public let third: PlayerReference?
}

/// Current defensive player positions during a live game.
public struct LinescoreDefense: Codable, Sendable, Equatable {
    /// Pitcher.
    public let pitcher: PlayerReference?
    /// Catcher.
    public let catcher: PlayerReference?
    /// First baseman.
    public let first: PlayerReference?
    /// Second baseman.
    public let second: PlayerReference?
    /// Third baseman.
    public let third: PlayerReference?
    /// Shortstop.
    public let shortstop: PlayerReference?
    /// Left fielder.
    public let left: PlayerReference?
    /// Center fielder.
    public let center: PlayerReference?
    /// Right fielder.
    public let right: PlayerReference?
    /// Current batter being faced.
    public let batter: PlayerReference?
    /// On-deck batter.
    public let onDeck: PlayerReference?
    /// In-the-hole batter.
    public let inHole: PlayerReference?
}
