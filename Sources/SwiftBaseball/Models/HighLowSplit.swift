import Foundation

/// A single-game peak (or trough) from the MLB Stats API `highLow` endpoints.
///
/// Each entry represents one game in which a player or team posted the
/// `n`-th highest (or lowest) value of `sortStat` for the given season and
/// stat group — e.g. "third-highest single-game home runs by any team in
/// 2024 was the Braves' 6 HR vs. Cincinnati on 2024-09-19."
///
/// Returned by ``SwiftBaseball/highLowPlayer(group:sortStat:season:)`` and
/// ``SwiftBaseball/highLowTeam(group:sortStat:season:)``. Player splits carry
/// a non-nil ``player``; team splits do not.
public struct HighLowSplit: Codable, Sendable, Equatable {
    /// Season the split is from.
    public let season: Int
    /// Numeric value of the sort stat in this single game (e.g. `3` HR).
    public let statValue: Double
    /// API stat key (e.g. `"homeRuns"`) — matches the `sortStat` query parameter.
    public let statName: String
    /// The player who achieved the peak. `nil` for team-level splits.
    public let player: PlayerReference?
    /// The team the player or team plays for.
    public let team: TeamReference
    /// The opposing team in the game.
    public let opponent: TeamReference
    /// Date of the game.
    public let date: Date
    /// `true` if the team played at home.
    public let isHome: Bool
    /// Rank within the leaderboard (1 = peak / trough).
    public let rank: Int
    /// Number of innings the game ran (e.g. 9, 10, 11). `nil` if unreported.
    public let gameInnings: Int?
    /// MLB game-pk identifier for the underlying game.
    public let gamePk: Int
}
