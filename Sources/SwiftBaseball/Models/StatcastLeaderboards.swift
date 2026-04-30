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

// MARK: - Catcher Pop Time

/// A single catcher's pop time entry from the Baseball Savant pop time leaderboard.
///
/// Pop time is the total elapsed time from the pitch reaching the catcher's mitt to the
/// fielder at 2B or 3B receiving the throw. It combines reaction time, exchange time
/// (glove to throwing position), and arm speed.
///
/// - Note: Team is not included in the Baseball Savant pop time CSV export.
///   Use ``playerId`` to look up team via ``SwiftBaseball/players(ids:)``.
public struct PopTimeEntry: Sendable, Equatable, Codable {
    /// MLB player ID.
    public let playerId: Int
    /// Player's full name as returned by the leaderboard (Last, First format).
    public let playerName: String
    /// Season year.
    public let season: Int
    /// Average pop time to 2B on steal attempts, in seconds.
    public let popTimeTo2B: Double
    /// Number of 2B steal attempts in the sample.
    public let throwsTo2B: Int
    /// Time from receiving the pitch to releasing the throw, in seconds.
    /// Combined across 2B and 3B attempts.
    public let exchangeTime: Double
    /// Maximum arm strength (velocity) on steal attempts, in mph.
    public let armStrength: Double
    /// Pop time to 2B on caught-stealing attempts. `nil` if no CS in sample.
    public let popTimeTo2BOnCS: Double?
    /// Pop time to 2B on stolen-base attempts. `nil` if no SB in sample.
    public let popTimeTo2BOnSB: Double?
    /// Average pop time to 3B on steal attempts. `nil` if fewer than threshold.
    public let popTimeTo3B: Double?
    /// Number of 3B steal attempts. `nil` if below threshold.
    public let throwsTo3B: Int?
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

// MARK: - Expected Stats — Batter

/// A single batter's expected-statistics entry from the Baseball Savant
/// expected-statistics leaderboard.
///
/// Compares a hitter's actual outcomes (BA / SLG / wOBA) against the values that
/// would be expected from the launch angle and exit velocity of every batted ball.
/// Positive `expected*Diff` values mean the player is outperforming their batted-ball
/// profile (lucky / better contact placement); negative values indicate they are
/// being suppressed by their batted-ball luck.
public struct ExpectedStatsBatterEntry: Sendable, Equatable, Codable {
    /// MLB player ID.
    public let playerId: Int
    /// Player's full name as returned by the leaderboard (`Last, First`).
    public let playerName: String
    /// Season year.
    public let season: Int
    /// Plate appearances in the sample.
    public let plateAppearances: Int
    /// Balls in play in the sample.
    public let battedBalls: Int
    /// Actual batting average.
    public let battingAverage: Double
    /// Expected batting average (xBA).
    public let expectedBattingAverage: Double
    /// `battingAverage − expectedBattingAverage`. Positive = outperforming.
    public let expectedBABIPDiff: Double
    /// Actual slugging percentage.
    public let slugging: Double
    /// Expected slugging percentage (xSLG).
    public let expectedSlugging: Double
    /// `slugging − expectedSlugging`. Positive = outperforming.
    public let expectedSluggingDiff: Double
    /// Actual weighted on-base average.
    public let wOBA: Double
    /// Expected weighted on-base average (xwOBA).
    public let expectedWOBA: Double
    /// `wOBA − expectedWOBA`. Positive = outperforming.
    public let expectedWOBADiff: Double
}

// MARK: - Expected Stats — Pitcher

/// A single pitcher's expected-statistics entry from the Baseball Savant
/// expected-statistics leaderboard.
///
/// Mirrors ``ExpectedStatsBatterEntry`` but represents stats _allowed_ — actual vs
/// quality-of-contact–driven expectations. Negative `expected*Diff` values
/// (actual minus expected) mean the pitcher is _outperforming_ their contact
/// profile, e.g. allowing fewer hits than expected based on exit velocity and
/// launch angle of balls in play.
public struct ExpectedStatsPitcherEntry: Sendable, Equatable, Codable {
    /// MLB player ID.
    public let playerId: Int
    /// Player's full name as returned by the leaderboard (`Last, First`).
    public let playerName: String
    /// Season year.
    public let season: Int
    /// Plate appearances faced.
    public let plateAppearances: Int
    /// Balls in play allowed.
    public let battedBalls: Int
    /// Actual batting average against.
    public let battingAverage: Double
    /// Expected batting average against (xBA).
    public let expectedBattingAverage: Double
    /// `battingAverage − expectedBattingAverage`.
    public let expectedBABIPDiff: Double
    /// Actual slugging percentage against.
    public let slugging: Double
    /// Expected slugging percentage against (xSLG).
    public let expectedSlugging: Double
    /// `slugging − expectedSlugging`.
    public let expectedSluggingDiff: Double
    /// Actual weighted on-base average against.
    public let wOBA: Double
    /// Expected weighted on-base average against (xwOBA).
    public let expectedWOBA: Double
    /// `wOBA − expectedWOBA`.
    public let expectedWOBADiff: Double
    /// Actual earned run average. `nil` if upstream omitted it.
    public let era: Double?
    /// Expected ERA driven by Statcast contact quality (xERA). `nil` if upstream omitted it.
    public let expectedERA: Double?
    /// `era − expectedERA`. `nil` if either side is unavailable.
    public let expectedERADiff: Double?
}

// MARK: - Percentile Ranks — Batter

/// A single batter's percentile-ranks entry from the Baseball Savant percentile-rankings leaderboard.
///
/// Each value is a 1–99 percentile rank (where 99 is best in class for that metric)
/// among the qualifying batter pool for the season. Fields the player did not
/// qualify for (e.g. fielders who don't run enough qualifying competitive sprints
/// for ``sprintSpeedPercentile``) are returned as `nil`.
public struct PercentileRanksBatterEntry: Sendable, Equatable, Codable {
    /// MLB player ID.
    public let playerId: Int
    /// Player's full name as returned by the leaderboard (`Last, First`).
    public let playerName: String
    /// Season year.
    public let season: Int
    /// xwOBA percentile rank (1–99).
    public let xwOBAPercentile: Int?
    /// Expected batting average percentile rank.
    public let xBAPercentile: Int?
    /// Expected slugging percentile rank.
    public let xSLGPercentile: Int?
    /// Expected isolated power percentile rank.
    public let xISOPercentile: Int?
    /// Expected on-base percentage percentile rank.
    public let xOBPPercentile: Int?
    /// Barrels percentile rank (raw barrel count).
    public let barrelsPercentile: Int?
    /// Barrel rate (barrels per batted ball event) percentile rank.
    public let barrelRatePercentile: Int?
    /// Average exit velocity percentile rank.
    public let exitVelocityPercentile: Int?
    /// Maximum exit velocity percentile rank.
    public let maxExitVelocityPercentile: Int?
    /// Hard-hit rate (95+ mph) percentile rank.
    public let hardHitPercentile: Int?
    /// Strikeout rate percentile rank (lower K% = higher percentile).
    public let strikeoutPercentile: Int?
    /// Walk rate percentile rank (higher BB% = higher percentile).
    public let walkPercentile: Int?
    /// Whiff rate percentile rank (lower whiff = higher percentile).
    public let whiffPercentile: Int?
    /// Chase rate (out-of-zone swing) percentile rank.
    public let chasePercentile: Int?
    /// Outfielder arm strength percentile rank.
    public let armStrengthPercentile: Int?
    /// Sprint speed percentile rank.
    public let sprintSpeedPercentile: Int?
    /// Outs Above Average percentile rank.
    public let oaaPercentile: Int?
    /// Bat speed percentile rank (2024+).
    public let batSpeedPercentile: Int?
    /// Squared-up rate percentile rank (2024+).
    public let squaredUpRatePercentile: Int?
    /// Swing length percentile rank (2024+).
    public let swingLengthPercentile: Int?
}

// MARK: - Percentile Ranks — Pitcher

/// A single pitcher's percentile-ranks entry from the Baseball Savant percentile-rankings leaderboard.
///
/// Each value is a 1–99 percentile rank among the qualifying pitcher pool.
/// Pitcher-specific metrics (``fastballVelocityPercentile``, spin percentiles)
/// replace the batter's running and bat-tracking percentiles.
public struct PercentileRanksPitcherEntry: Sendable, Equatable, Codable {
    /// MLB player ID.
    public let playerId: Int
    /// Player's full name as returned by the leaderboard (`Last, First`).
    public let playerName: String
    /// Season year.
    public let season: Int
    /// xwOBA-against percentile rank.
    public let xwOBAPercentile: Int?
    /// Expected batting average against percentile rank.
    public let xBAPercentile: Int?
    /// Expected slugging against percentile rank.
    public let xSLGPercentile: Int?
    /// Expected isolated power against percentile rank.
    public let xISOPercentile: Int?
    /// Expected on-base percentage against percentile rank.
    public let xOBPPercentile: Int?
    /// Barrels-allowed percentile rank.
    public let barrelsPercentile: Int?
    /// Barrel rate against percentile rank.
    public let barrelRatePercentile: Int?
    /// Average exit velocity allowed percentile rank.
    public let exitVelocityPercentile: Int?
    /// Maximum exit velocity allowed percentile rank.
    public let maxExitVelocityPercentile: Int?
    /// Hard-hit rate allowed percentile rank.
    public let hardHitPercentile: Int?
    /// Strikeout rate percentile rank (higher K% = higher percentile).
    public let strikeoutPercentile: Int?
    /// Walk rate percentile rank (lower BB% = higher percentile).
    public let walkPercentile: Int?
    /// Whiff rate generated percentile rank.
    public let whiffPercentile: Int?
    /// Chase rate induced percentile rank.
    public let chasePercentile: Int?
    /// Arm strength percentile rank.
    public let armStrengthPercentile: Int?
    /// Expected ERA percentile rank.
    public let xERAPercentile: Int?
    /// Fastball velocity percentile rank.
    public let fastballVelocityPercentile: Int?
    /// Fastball spin rate percentile rank.
    public let fastballSpinPercentile: Int?
    /// Curveball spin rate percentile rank. `nil` if pitcher does not throw a curve.
    public let curveSpinPercentile: Int?
}

// MARK: - Exit Velocity & Barrels — Batter

/// A single batter's exit-velocity & barrels entry from the Baseball Savant
/// `/leaderboard/statcast` board (Statcast quality-of-contact summary).
///
/// All percent fields (``hardHitRate``, ``barrelRate``, ``barrelsPerPA``, ``sweetSpotRate``)
/// are returned as percentages on a 0–100 scale, matching the Savant CSV wire format
/// — e.g. `35.2` means 35.2%, not 35.2× or 0.352.
public struct ExitVeloBarrelsBatterEntry: Sendable, Equatable, Codable {
    /// MLB player ID.
    public let playerId: Int
    /// Player's full name as returned by the leaderboard (`Last, First`).
    public let playerName: String
    /// Season year (passed through from the query — not present in the CSV).
    public let season: Int
    /// Number of batted-ball events used in the calculation.
    public let attempts: Int
    /// Average launch angle in degrees.
    public let avgLaunchAngle: Double
    /// Sweet-spot rate — share of batted balls in the 8°–32° launch-angle window (0–100).
    public let sweetSpotRate: Double
    /// Maximum exit velocity in the sample, mph.
    public let maxExitVelocity: Double
    /// Average exit velocity, mph.
    public let avgExitVelocity: Double
    /// Average exit velocity on the player's hardest-hit half of batted balls (EV50), mph.
    public let ev50: Double
    /// Average exit velocity on fly balls and line drives, mph.
    public let avgExitVelocityFBLD: Double
    /// Average exit velocity on ground balls, mph.
    public let avgExitVelocityGB: Double
    /// Maximum batted-ball distance in the sample, feet.
    public let maxDistance: Int
    /// Average batted-ball distance, feet.
    public let avgDistance: Int
    /// Average home-run distance, feet. `nil` if no home runs in the sample.
    public let avgHomeRunDistance: Int?
    /// Number of batted balls hit at 95+ mph.
    public let ev95Plus: Int
    /// Hard-hit rate — share of batted balls hit at 95+ mph (0–100).
    public let hardHitRate: Double
    /// Number of barrels.
    public let barrels: Int
    /// Barrel rate per batted-ball event (0–100).
    public let barrelRate: Double
    /// Barrels per plate appearance (0–100).
    public let barrelsPerPA: Double
}

// MARK: - Exit Velocity & Barrels — Pitcher

/// A single pitcher's exit-velocity & barrels entry from the Baseball Savant
/// `/leaderboard/statcast` board.
///
/// Mirrors ``ExitVeloBarrelsBatterEntry`` but reports values _allowed_. As with the
/// batter version, percent fields are 0–100 (not fractional), matching the
/// Savant CSV wire format.
public struct ExitVeloBarrelsPitcherEntry: Sendable, Equatable, Codable {
    /// MLB player ID.
    public let playerId: Int
    /// Player's full name as returned by the leaderboard (`Last, First`).
    public let playerName: String
    /// Season year (passed through from the query — not present in the CSV).
    public let season: Int
    /// Number of batted-ball events allowed.
    public let attempts: Int
    /// Average launch angle of contact allowed, degrees.
    public let avgLaunchAngle: Double
    /// Sweet-spot rate allowed (0–100).
    public let sweetSpotRate: Double
    /// Maximum exit velocity allowed in the sample, mph.
    public let maxExitVelocity: Double
    /// Average exit velocity allowed, mph.
    public let avgExitVelocity: Double
    /// EV50 allowed — average EV on the hardest-hit half of contact, mph.
    public let ev50: Double
    /// Average EV allowed on fly balls and line drives, mph.
    public let avgExitVelocityFBLD: Double
    /// Average EV allowed on ground balls, mph.
    public let avgExitVelocityGB: Double
    /// Maximum distance allowed, feet.
    public let maxDistance: Int
    /// Average distance allowed, feet.
    public let avgDistance: Int
    /// Average home-run distance allowed, feet. `nil` if no home runs allowed.
    public let avgHomeRunDistance: Int?
    /// Number of 95+ mph batted balls allowed.
    public let ev95Plus: Int
    /// Hard-hit rate allowed (0–100).
    public let hardHitRate: Double
    /// Number of barrels allowed.
    public let barrels: Int
    /// Barrel rate allowed per batted-ball event (0–100).
    public let barrelRate: Double
    /// Barrels allowed per plate appearance (0–100).
    public let barrelsPerPA: Double
}
