import Foundation

/// A postseason series — Wild Card, Division, League Championship, or World Series.
///
/// Returned by ``SwiftBaseball/postseasonSeries(season:)``. Each series groups all
/// scheduled and completed games between two teams (best-of-three, -five, or -seven).
public struct PostseasonSeries: Codable, Sendable, Equatable, Identifiable {
    /// Series identifier (e.g. `"W_1"`, `"L_2"`, `"D_3"`, `"F_4"`). The prefix encodes
    /// the round (`W`/`L`/`D`/`F` = World Series / League Championship / Division / Wild Card),
    /// and the suffix is the seeded matchup number within that round.
    public let id: String
    /// The round of the postseason this series belongs to.
    public let gameType: GameType
    /// Sort order of the series within its round (1-based).
    public let sortNumber: Int
    /// Total number of games actually scheduled or played in this series.
    public let totalGames: Int
    /// All games in the series, in scheduled order.
    public let games: [ScheduleEntry]

    /// Creates a postseason series.
    public init(
        id: String,
        gameType: GameType,
        sortNumber: Int,
        totalGames: Int,
        games: [ScheduleEntry]
    ) {
        self.id = id
        self.gameType = gameType
        self.sortNumber = sortNumber
        self.totalGames = totalGames
        self.games = games
    }
}
