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

// MARK: - Pitch Arsenal

/// Which arsenal metric a ``PitchArsenalEntry`` reports.
///
/// The Baseball Savant pitch-arsenals board exposes two views in CSV form —
/// one per metric. Use this enum to select which view to fetch via
/// ``PitchArsenalQuery/metric(_:)``.
///
/// - Note: The upstream board includes a usage view in HTML, but the CSV export
///   for `type=n` / `type=usage` returns empty cells. Per-pitch usage and pitch
///   counts are available via ``PitchArsenalStatsEntry/pitchUsage`` and
///   ``PitchArsenalStatsEntry/pitches`` on the `pitch-arsenal-stats` board
///   instead.
public enum PitchArsenalMetric: String, Sendable, Equatable, Codable {
    /// Average release velocity in miles per hour (`<pitch>_avg_speed` columns).
    case velocity
    /// Average spin rate in revolutions per minute (`<pitch>_avg_spin` columns).
    case spin
}

/// A single pitcher × pitch-type entry from the Baseball Savant pitch-arsenals leaderboard.
///
/// The upstream CSV is wide — one row per pitcher with one column per pitch type
/// (`ff_avg_speed`, `si_avg_speed`, …). ``PitchArsenalQuery`` flattens that wide
/// shape into one ``PitchArsenalEntry`` per (pitcher, pitch type) so all three
/// arsenal views (velocity / spin / usage) share the same row layout.
///
/// Pitch-type codes follow the Statcast convention:
/// `FF` (4-seam), `SI` (sinker), `FC` (cutter), `SL` (slider), `CH` (changeup),
/// `CU` (curveball), `FS` (splitter), `KN` (knuckleball), `ST` (sweeper),
/// `SV` (slurve).
public struct PitchArsenalEntry: Sendable, Equatable, Codable {
    /// MLB player ID of the pitcher.
    public let pitcherId: Int
    /// Pitcher's full name as returned by the leaderboard (`Last, First`).
    public let pitcherName: String
    /// Season year (passed through from the query — not present in the CSV).
    public let season: Int
    /// Statcast pitch-type code (e.g. `"FF"`, `"SL"`).
    public let pitchType: String
    /// Which arsenal metric the ``value`` represents.
    public let metric: PitchArsenalMetric
    /// The metric value: mph for ``PitchArsenalMetric/velocity``, rpm for
    /// ``PitchArsenalMetric/spin``, raw pitch count for ``PitchArsenalMetric/usage``.
    public let value: Double
}

// MARK: - Pitch Arsenal Stats

/// A single pitcher × pitch-type performance entry from the Baseball Savant
/// `pitch-arsenal-stats` leaderboard.
///
/// One row per pitcher per pitch type, surfacing how each individual pitch
/// performed: usage share, run value, swing-and-miss, and quality-of-contact
/// outcomes (BA / SLG / wOBA actual and expected, hard-hit rate).
///
/// Percent fields (``pitchUsage``, ``whiffRate``, ``strikeoutRate``,
/// ``putAwayRate``, ``hardHitRate``) are reported on the Savant CSV's
/// 0–100 scale.
public struct PitchArsenalStatsEntry: Sendable, Equatable, Codable {
    /// MLB player ID of the pitcher.
    public let playerId: Int
    /// Pitcher's full name as returned by the leaderboard (`Last, First`).
    public let playerName: String
    /// Season year (passed through from the query — not present in the CSV).
    public let season: Int
    /// Team abbreviation (e.g. `"MIL"`).
    public let team: String
    /// Statcast pitch-type code (e.g. `"FF"`, `"SL"`).
    public let pitchType: String
    /// Human-readable pitch name (e.g. `"4-Seam Fastball"`).
    public let pitchName: String
    /// Run value per 100 pitches of this type. Negative is good for the pitcher.
    public let runValuePer100: Double
    /// Total run value of all pitches of this type. Negative is good for the pitcher.
    public let runValue: Int
    /// Number of pitches of this type thrown.
    public let pitches: Int
    /// Share of total pitches that were of this type (0–100).
    public let pitchUsage: Double
    /// Plate appearances ending on this pitch type.
    public let plateAppearances: Int
    /// Batting average against this pitch type.
    public let battingAverage: Double
    /// Slugging percentage against this pitch type.
    public let slugging: Double
    /// Weighted on-base average against this pitch type.
    public let wOBA: Double
    /// Whiff rate (swings and misses ÷ swings) against this pitch type (0–100).
    public let whiffRate: Double
    /// Strikeout rate when this pitch is in the at-bat (0–100).
    public let strikeoutRate: Double
    /// Put-away rate — share of two-strike pitches of this type that ended the AB in a K (0–100).
    public let putAwayRate: Double
    /// Expected batting average against this pitch type.
    public let expectedBattingAverage: Double
    /// Expected slugging against this pitch type.
    public let expectedSlugging: Double
    /// Expected wOBA against this pitch type.
    public let expectedWOBA: Double
    /// Hard-hit rate (95+ mph) against this pitch type (0–100).
    public let hardHitRate: Double
}

// MARK: - Pitch Movement

/// A single pitcher × pitch-type movement entry from the Baseball Savant
/// `pitch-movement` leaderboard.
///
/// One row per pitcher per pitch type, describing how the pitch moves relative
/// to league average for that pitch type — vertical drop (gravity-included and
/// induced-only), horizontal break, and percentile ranks of the differentials
/// against the league at the same release point and velocity.
///
/// "Z" axis is vertical (positive = upward / less drop than gravity); "X" axis
/// is horizontal (sign convention follows Savant: positive = toward the
/// pitcher's arm side).
public struct PitchMovementEntry: Sendable, Equatable, Codable {
    /// MLB player ID of the pitcher.
    public let pitcherId: Int
    /// Pitcher's full name as returned by the leaderboard (`Last, First`).
    public let pitcherName: String
    /// Season year.
    public let season: Int
    /// Team display name (e.g. `"Nationals"`).
    public let team: String
    /// Team abbreviation (e.g. `"WSH"`).
    public let teamAbbreviation: String
    /// Pitching hand (`"L"` or `"R"`).
    public let pitchHand: String
    /// Statcast pitch-type code (e.g. `"FF"`).
    public let pitchType: String
    /// Human-readable pitch name (e.g. `"4-Seam Fastball"`).
    public let pitchTypeName: String
    /// Average release velocity, mph.
    public let avgSpeed: Double
    /// Number of pitches of this type thrown by the pitcher.
    public let pitchesThrown: Int
    /// Total pitches thrown by the pitcher across all types in the sample.
    public let totalPitches: Int
    /// Average pitches of this type thrown per game.
    public let pitchesPerGame: Double
    /// Share of the pitcher's total arsenal made up by this pitch (0–1 fraction).
    public let pitchUsage: Double
    /// Pitcher's vertical drop in inches (gravity-included).
    public let pitcherBreakZ: Double
    /// League-average vertical drop in inches at this pitch type and velocity (gravity-included).
    public let leagueBreakZ: Double
    /// `pitcherBreakZ − leagueBreakZ`, in inches.
    public let diffZ: Double
    /// Approximate "rise" relative to league as an integer percent (Savant's `rise` column).
    public let rise: Int
    /// Pitcher's induced vertical break in inches (gravity stripped out).
    public let pitcherBreakZInduced: Double
    /// Pitcher's horizontal break in inches (positive = arm-side).
    public let pitcherBreakX: Double
    /// League-average horizontal break in inches at this pitch type and velocity.
    public let leagueBreakX: Double
    /// `pitcherBreakX − leagueBreakX`, in inches.
    public let diffX: Double
    /// Approximate horizontal "tail" relative to league as an integer percent (Savant's `tail` column).
    public let tail: Int
    /// Percentile rank of the vertical-break differential vs league (0–1 fraction).
    public let percentRankDiffZ: Double
    /// Percentile rank of the horizontal-break differential vs league (0–1 fraction).
    public let percentRankDiffX: Double
}
