import Foundation

/// A scheduled or completed MLB game entry.
///
/// Returned by ``SwiftBaseball/schedule()`` queries.
public struct ScheduleEntry: Codable, Sendable, Equatable, Identifiable {
    /// Game primary key (`gamePk`).
    public let id: Int
    /// Scheduled game date and time.
    public let gameDate: Date
    /// Current game status.
    public let status: GameStatus
    /// Away and home team entries.
    public let teams: ScheduleTeams
    /// Venue where the game is played.
    public let venue: VenueReference
    /// Type of game (regular season, postseason, etc.).
    public let gameType: GameType
    /// Season year (e.g. "2024").
    public let season: String
    /// Series description (e.g. "Regular Season", "ALDS").
    public let seriesDescription: String?
    /// Total games in the series.
    public let gamesInSeries: Int?
    /// This game's number within the series.
    public let seriesGameNumber: Int?

    enum CodingKeys: String, CodingKey {
        case id = "gamePk"
        case gameDate, status, teams, venue, gameType, season
        case seriesDescription, gamesInSeries, seriesGameNumber
    }
}

/// Container for away and home ``ScheduleTeamEntry`` data.
public struct ScheduleTeams: Codable, Sendable, Equatable {
    /// Away team entry.
    public let away: ScheduleTeamEntry
    /// Home team entry.
    public let home: ScheduleTeamEntry
}

/// A team's entry within a ``ScheduleEntry``.
public struct ScheduleTeamEntry: Codable, Sendable, Equatable {
    /// Reference to the team.
    public let team: TeamReference
    /// Score, if the game has started.
    public let score: Int?
    /// Whether this team won, if the game is final.
    public let isWinner: Bool?
    /// Whether this is a split-squad game for this team.
    public let splitSquad: Bool?
    /// Team's current league record (W-L-Pct).
    public let leagueRecord: LeagueRecord?
}

/// A team's win-loss record and winning percentage.
public struct LeagueRecord: Codable, Sendable, Equatable {
    /// Number of wins.
    public let wins: Int
    /// Number of losses.
    public let losses: Int
    /// Winning percentage as a string (e.g. ".600").
    public let pct: String
}
