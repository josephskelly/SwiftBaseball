import Foundation

/// Aggregate pace-of-play metrics for a team or league over a season.
///
/// Returned by ``SwiftBaseball/gamePace(teamId:season:)`` (team-scoped) and
/// ``SwiftBaseball/leagueGamePace(season:)`` (sport-wide). Time values are
/// exposed as ``TimeInterval`` (seconds) — the upstream API formats them as
/// `H:MM:SS` duration strings (e.g. `"6426:37:00"` for a full season of
/// play), which are parsed at decoding time.
public struct GamePace: Codable, Sendable, Equatable {
    /// Season the metrics cover (e.g. `"2024"`).
    public let season: String

    /// Team the record describes. `nil` for league-wide records.
    public let team: TeamReference?
    /// League the team belongs to. `nil` for league-wide records.
    public let league: LeagueReference?
    /// Sport identifier (e.g. `1` for MLB).
    public let sportId: Int?
    /// Sport display name, when reported (e.g. `"Major League Baseball"`).
    public let sportName: String?

    // MARK: - Game counts

    /// Total games counted toward these pace figures.
    public let totalGames: Int?
    /// Nine-inning games (the most common case).
    public let total9InnGames: Int?
    /// Seven-inning games (typically doubleheader halves under recent rules).
    public let total7InnGames: Int?
    /// Games that went to extra innings.
    public let totalExtraInnGames: Int?
    /// Scheduled nine-inning games, including those shortened or postponed.
    public let total9InnGamesScheduled: Int?
    /// Nine-inning games completed early (e.g. weather-shortened).
    public let total9InnGamesCompletedEarly: Int?
    /// Nine-inning games that did not go to extras.
    public let total9InnGamesWithoutExtraInn: Int?

    // MARK: - Cumulative totals

    /// Sum of all innings played across the counted games.
    public let totalInningsPlayed: Double?
    /// Sum of hits across the counted games.
    public let totalHits: Int?
    /// Sum of runs across the counted games.
    public let totalRuns: Int?
    /// Sum of plate appearances across the counted games.
    public let totalPlateAppearances: Int?
    /// Pitcher-game appearances (a pitcher counted once per game they appeared in).
    public let totalPitchers: Int?
    /// Total pitches thrown.
    public let totalPitches: Int?

    // MARK: - Per-game / per-9-inning rates

    /// Hits per 9 innings pitched.
    public let hitsPer9Inn: Double?
    /// Runs per 9 innings pitched.
    public let runsPer9Inn: Double?
    /// Pitches per 9 innings pitched.
    public let pitchesPer9Inn: Double?
    /// Plate appearances per 9 innings.
    public let plateAppearancesPer9Inn: Double?
    /// Hits per game (regardless of length).
    public let hitsPerGame: Double?
    /// Runs per game.
    public let runsPerGame: Double?
    /// Average innings played per game.
    public let inningsPlayedPerGame: Double?
    /// Pitches per game.
    public let pitchesPerGame: Double?
    /// Pitchers used per game.
    public let pitchersPerGame: Double?
    /// Plate appearances per game.
    public let plateAppearancesPerGame: Double?
    /// Hits required on average to produce one run.
    public let hitsPerRun: Double?
    /// Average pitches thrown per pitcher appearance.
    public let pitchesPerPitcher: Double?

    // MARK: - Durations (seconds)

    /// Total elapsed game time across the counted games.
    public let totalGameTime: TimeInterval?
    /// Average elapsed time per game.
    public let timePerGame: TimeInterval?
    /// Average elapsed time per pitch.
    public let timePerPitch: TimeInterval?
    /// Average elapsed time per hit.
    public let timePerHit: TimeInterval?
    /// Average elapsed time per run.
    public let timePerRun: TimeInterval?
    /// Average elapsed time per plate appearance.
    public let timePerPlateAppearance: TimeInterval?
    /// Average elapsed time per 9 innings played.
    public let timePer9Inn: TimeInterval?
    /// Average elapsed time per 77 plate appearances (MLB's normalized pace figure).
    public let timePer77PlateAppearances: TimeInterval?
    /// Total extra-inning time across all games that went to extras.
    public let totalExtraInnTime: TimeInterval?
    /// Average elapsed time per 7-inning game (rounded sub-metric).
    public let timePer7InnGame: TimeInterval?
    /// Average elapsed time per 9-inning game (rounded sub-metric).
    public let timePer9InnGame: TimeInterval?
    /// Average elapsed time per extra-inning game (rounded sub-metric).
    public let timePerExtraInnGame: TimeInterval?
}
