import Foundation

/// A single game's stat line from a player's game log.
///
/// Each entry represents one game played by a player, including the game context
/// (date, opponent, home/away) and the stat line for that game.
public struct GameLogEntry: Codable, Sendable, Equatable, Identifiable {
    /// Unique identifier — the MLB game primary key.
    public var id: Int {
        gamePk
    }

    /// The player who played in this game.
    public let player: PlayerReference
    /// The season year (e.g. `"2024"`).
    public let season: String
    /// The date the game was played.
    public let date: Date
    /// The MLB game primary key.
    public let gamePk: Int
    /// The team the player was on for this game.
    public let team: TeamReference
    /// The opposing team.
    public let opponent: TeamReference
    /// Whether the player's team was the home team.
    public let isHome: Bool
    /// Whether the player's team won the game.
    public let isWin: Bool
    /// The type of game (regular season, postseason, etc.).
    public let gameType: GameType
    /// The stat group for this entry.
    public let group: StatGroup
    /// Batting stats, populated when ``group`` is ``StatGroup/batting``.
    public let batting: BattingStats?
    /// Pitching stats, populated when ``group`` is ``StatGroup/pitching``.
    public let pitching: PitchingStats?
    /// Fielding stats, populated when ``group`` is ``StatGroup/fielding``.
    public let fielding: FieldingStats?
}
