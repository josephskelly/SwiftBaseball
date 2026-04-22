import Foundation

/// Season attendance totals for a team.
///
/// Returned by ``SwiftBaseball/attendance(teamId:season:)``. Each value is
/// one record from the MLB `records` array — the upstream API returns one
/// record per (season, gameType) pair. A team that played both regular-season
/// and postseason games in the requested year will therefore appear in
/// multiple entries.
///
/// Attendance counts reflect paid gate, not game-day turnstile, matching the
/// figures MLB publishes publicly. Home, away, and total are reported
/// independently; cross-team aggregation is the caller's responsibility.
public struct TeamAttendance: Codable, Sendable, Equatable {
    /// The team whose attendance this record describes.
    public let team: TeamReference
    /// Season (e.g. `"2024"`), as reported by the upstream API.
    public let year: String
    /// Game type covered by this record (regular season, postseason, spring, etc.).
    ///
    /// `nil` if the upstream record omits it or the code is unrecognized.
    public let gameType: GameType?

    /// Scheduled games the team was slated to play (home + away + lost openings).
    public let openingsTotal: Int?
    /// Scheduled home games.
    public let openingsTotalHome: Int?
    /// Scheduled away games.
    public let openingsTotalAway: Int?
    /// Games lost to weather, cancellation, or other non-played outcomes.
    public let openingsTotalLost: Int?

    /// Games actually played (home + away).
    public let gamesTotal: Int?
    /// Home games played.
    public let gamesHomeTotal: Int?
    /// Away games played.
    public let gamesAwayTotal: Int?

    /// Total paid attendance across home + away games.
    public let attendanceTotal: Int?
    /// Total paid home attendance.
    public let attendanceTotalHome: Int?
    /// Total paid away attendance (fans in opponents' parks).
    public let attendanceTotalAway: Int?

    /// Combined home + away average per game.
    public let attendanceAverageYtd: Int?
    /// Average paid attendance for home games.
    public let attendanceAverageHome: Int?
    /// Average paid attendance for away games.
    public let attendanceAverageAway: Int?
    /// Average home attendance on scheduled home openings, including lost dates.
    public let attendanceOpeningAverage: Int?

    /// Highest single-game paid home attendance for the record.
    public let attendanceHigh: Int?
    /// Date of the highest-attendance home game, when available.
    public let attendanceHighDate: Date?
    /// `gamePk` of the highest-attendance home game, when available.
    public let attendanceHighGamePk: Int?

    /// Lowest single-game paid home attendance for the record.
    public let attendanceLow: Int?
    /// Date of the lowest-attendance home game, when available.
    public let attendanceLowDate: Date?
    /// `gamePk` of the lowest-attendance home game, when available.
    public let attendanceLowGamePk: Int?
}
