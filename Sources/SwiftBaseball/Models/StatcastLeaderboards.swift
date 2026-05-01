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

// MARK: - Active Spin

/// A single pitcher × pitch-type entry from the Baseball Savant `active-spin` leaderboard.
///
/// "Active spin" is the share of a pitch's total spin that contributes to its movement
/// (Magnus effect), as opposed to gyro spin which doesn't move the ball. Values are
/// reported as percentages on the **0–100 scale** as Savant publishes them — e.g.
/// `98.7` means 98.7%, not 0.987.
///
/// The upstream CSV is wide — one row per pitcher with one column per pitch type
/// (`active_spin_fourseam`, `active_spin_sinker`, …). ``ActiveSpinQuery`` flattens
/// that wide shape into one ``ActiveSpinEntry`` per (pitcher, pitch type), skipping
/// pitch types the pitcher doesn't throw.
///
/// Pitch types are mapped to Statcast codes:
/// `FF` (4-seam), `SI` (sinker), `FC` (cutter), `CH` (changeup), `FS` (splitter),
/// `CU` (curveball), `SL` (slider), `ST` (sweeper), `SV` (slurve).
public struct ActiveSpinEntry: Sendable, Equatable, Codable {
    /// MLB player ID of the pitcher.
    public let pitcherId: Int
    /// Pitcher's full name as returned by the leaderboard (`Last, First`).
    public let pitcherName: String
    /// Pitching hand (`"L"` or `"R"`).
    public let pitchHand: String
    /// Season year (passed through from the query — not present in the CSV).
    public let season: Int
    /// Statcast pitch-type code (e.g. `"FF"`, `"SL"`).
    public let pitchType: String
    /// Active spin percentage on the 0–100 scale (Savant wire format).
    public let activeSpinPercent: Double
}

// MARK: - Running Splits

/// A single base-running splits entry from the Baseball Savant `running_splits` leaderboard.
///
/// Reports cumulative seconds elapsed at every five-foot mark from the moment of contact
/// (`secondsTo0ft`, the contact instant, is always `0.00`) through 90 feet (the home-to-first
/// distance). Useful for reconstructing acceleration profiles — early splits surface
/// reaction time and explosiveness, later splits surface top-end speed.
///
/// The upstream board separates splits by handedness of the swing — switch-hitters appear
/// twice (once with ``batSide`` = `"L"`, once with `"R"`).
public struct RunningSplitsEntry: Sendable, Equatable, Codable {
    /// MLB player ID.
    public let playerId: Int
    /// Player's full name as returned by the leaderboard (`Last, First`).
    public let playerName: String
    /// Team abbreviation (e.g. `"WSH"`).
    public let team: String
    /// Primary fielding position (e.g. `"SS"`, `"CF"`).
    public let position: String
    /// Player age, in years.
    public let age: Int
    /// Side of the plate the player swung from for this row (`"L"`, `"R"`, or `"S"`).
    public let batSide: String
    /// Season year (passed through from the query — not present in the CSV).
    public let season: Int
    /// Cumulative seconds at 0 ft (always `0.00`).
    public let secondsTo0ft: Double
    /// Cumulative seconds at 5 ft from contact.
    public let secondsTo5ft: Double?
    /// Cumulative seconds at 10 ft from contact.
    public let secondsTo10ft: Double?
    /// Cumulative seconds at 15 ft from contact.
    public let secondsTo15ft: Double?
    /// Cumulative seconds at 20 ft from contact.
    public let secondsTo20ft: Double?
    /// Cumulative seconds at 25 ft from contact.
    public let secondsTo25ft: Double?
    /// Cumulative seconds at 30 ft from contact.
    public let secondsTo30ft: Double?
    /// Cumulative seconds at 35 ft from contact.
    public let secondsTo35ft: Double?
    /// Cumulative seconds at 40 ft from contact.
    public let secondsTo40ft: Double?
    /// Cumulative seconds at 45 ft from contact.
    public let secondsTo45ft: Double?
    /// Cumulative seconds at 50 ft from contact.
    public let secondsTo50ft: Double?
    /// Cumulative seconds at 55 ft from contact.
    public let secondsTo55ft: Double?
    /// Cumulative seconds at 60 ft from contact.
    public let secondsTo60ft: Double?
    /// Cumulative seconds at 65 ft from contact.
    public let secondsTo65ft: Double?
    /// Cumulative seconds at 70 ft from contact.
    public let secondsTo70ft: Double?
    /// Cumulative seconds at 75 ft from contact.
    public let secondsTo75ft: Double?
    /// Cumulative seconds at 80 ft from contact.
    public let secondsTo80ft: Double?
    /// Cumulative seconds at 85 ft from contact.
    public let secondsTo85ft: Double?
    /// Cumulative seconds at 90 ft (home to first distance) from contact.
    public let secondsTo90ft: Double?
}

// MARK: - Bat Tracking

/// A single batter's bat-tracking entry from the Baseball Savant `bat-tracking` leaderboard.
///
/// Reports swing-level mechanics first lit up by Statcast in 2024: average bat speed,
/// swing length, fast-swing rate, squared-up rate, blast rate, and run value derived
/// from those swing characteristics.
///
/// - Important: Rate fields on this board are reported on the **0–1 fraction scale**
///   (e.g. `0.8519` means 85.19%), not the 0–100 scale used by other Savant
///   leaderboards (``ExitVeloBarrelsBatterEntry/hardHitRate``,
///   ``PitchArsenalStatsEntry/whiffRate``, etc.). This matches the Savant CSV
///   wire format verbatim.
///
/// - Important: This board is **2024 and later**. Earlier seasons return empty data.
public struct BatTrackingEntry: Sendable, Equatable, Codable {
    /// MLB player ID.
    public let playerId: Int
    /// Player's full name as returned by the leaderboard (`Last, First`).
    public let playerName: String
    /// Season year (passed through from the query — not present in the CSV).
    public let season: Int
    /// Number of competitive swings (no checked / late swings) used in the calculation.
    public let competitiveSwings: Int
    /// Share of total swings that were competitive (0–1 fraction).
    public let competitiveSwingRate: Double
    /// Number of competitive swings that produced contact.
    public let contact: Int
    /// Average bat speed at point of contact (or closest equivalent), in mph.
    public let avgBatSpeed: Double
    /// Hard-swing rate — share of competitive swings at ≥75 mph bat speed (0–1 fraction).
    public let hardSwingRate: Double
    /// Squared-up rate per contact — share of contact events that exited at ≥80% of
    /// the maximum possible exit velocity for the swing's bat speed (0–1 fraction).
    public let squaredUpPerContact: Double
    /// Squared-up rate per swing — share of competitive swings that produced
    /// a squared-up contact (0–1 fraction).
    public let squaredUpPerSwing: Double
    /// Blast rate per contact — share of contact events meeting both the squared-up
    /// criterion and a fast-swing criterion (0–1 fraction).
    public let blastPerContact: Double
    /// Blast rate per swing — share of competitive swings that produced a blast
    /// contact (0–1 fraction).
    public let blastPerSwing: Double
    /// Average swing length in feet, measured from the start of swing to point of contact.
    public let avgSwingLength: Double
    /// "Sword" swings — pitches where the batter is geometrically beaten by the pitch
    /// (extreme combination of swing decision and pitch movement).
    public let swords: Int
    /// Run value of the player's swing decisions and outcomes attributed to bat tracking.
    public let batterRunValue: Double
    /// Total whiffs (swing-and-miss) on competitive swings.
    public let whiffs: Int
    /// Whiff rate per competitive swing (0–1 fraction).
    public let whiffPerSwing: Double
    /// Total batted-ball events.
    public let battedBallEvents: Int
    /// Batted-ball events per competitive swing (0–1 fraction).
    public let battedBallEventPerSwing: Double
}

// MARK: - Outfield Catch Probability

/// A single outfielder's catch-probability breakdown from the Baseball Savant
/// `catch_probability` leaderboard.
///
/// Catch probability bins each fielding opportunity into one of five star ratings
/// based on the difficulty of the catch (1-star = easiest, 5-star = hardest, < 25%
/// expected catch rate). The entry reports, per star bucket, how many opportunities
/// the fielder saw, how many of them were converted to outs, and the conversion rate.
///
/// Catch percentages are reported on the **0–100 scale** (e.g. `38.5` means 38.5%).
/// A bucket's percent field is `nil` when the fielder had zero opportunities at that
/// difficulty (Savant emits an empty cell to avoid divide-by-zero).
///
/// - Note: Team is not included in the Savant catch-probability CSV. Use
///   ``playerId`` to look up team via ``SwiftBaseball/players(ids:)``.
public struct OutfieldCatchProbabilityEntry: Sendable, Equatable, Codable {
    /// MLB player ID.
    public let playerId: Int
    /// Player's full name as returned by the leaderboard (Last, First format).
    public let playerName: String
    /// Season year.
    public let season: Int
    /// Total Outs Above Average across all star buckets.
    public let outsAboveAverage: Int
    /// Number of 5-star catches (≥ 76% effort, < 25% expected).
    public let fiveStarOuts: Int
    /// Number of 5-star opportunities.
    public let fiveStarOpportunities: Int
    /// Catch percentage on 5-star opportunities (0–100). `nil` if no opportunities.
    public let fiveStarCatchPercent: Double?
    /// Number of 4-star catches (26–50% expected).
    public let fourStarOuts: Int
    /// Number of 4-star opportunities.
    public let fourStarOpportunities: Int
    /// Catch percentage on 4-star opportunities (0–100). `nil` if no opportunities.
    public let fourStarCatchPercent: Double?
    /// Number of 3-star catches (51–75% expected).
    public let threeStarOuts: Int
    /// Number of 3-star opportunities.
    public let threeStarOpportunities: Int
    /// Catch percentage on 3-star opportunities (0–100). `nil` if no opportunities.
    public let threeStarCatchPercent: Double?
    /// Number of 2-star catches (76–90% expected).
    public let twoStarOuts: Int
    /// Number of 2-star opportunities.
    public let twoStarOpportunities: Int
    /// Catch percentage on 2-star opportunities (0–100). `nil` if no opportunities.
    public let twoStarCatchPercent: Double?
    /// Number of 1-star catches (≥ 91% expected).
    public let oneStarOuts: Int
    /// Number of 1-star opportunities.
    public let oneStarOpportunities: Int
    /// Catch percentage on 1-star opportunities (0–100). `nil` if no opportunities.
    public let oneStarCatchPercent: Double?
}

// MARK: - Outfielder Jumps

/// A single outfielder's jump-tracking entry from the Baseball Savant `outfield_jump`
/// leaderboard.
///
/// "Jump" measures the first 1.5 seconds of an outfielder's pursuit of a fly ball,
/// decomposed into three additive distance components (relative to league average):
/// reaction (first 0–1.5 s before any committed direction), burst (1.5–3.0 s of
/// acceleration), and routing (efficiency of the path taken). Bootup distance is the
/// sum of all three. All `relLeague*` fields are signed feet versus league average —
/// positive = better than average. `fBootupDistance` is the absolute distance covered
/// in feet (typical range 30–37 ft).
///
/// - Note: Team is not included in the Savant outfield-jump CSV. Use ``playerId``
///   to look up team via ``SwiftBaseball/players(ids:)``.
public struct OutfielderJumpEntry: Sendable, Equatable, Codable {
    /// MLB player ID (Savant calls this `resp_fielder_id`).
    public let playerId: Int
    /// Player's full name as returned by the leaderboard (Last, First format).
    public let playerName: String
    /// Season year.
    public let season: Int
    /// Outs Above Average attributable to first-step jump performance.
    public let outsAboveAverage: Int
    /// Outs per 100 plays — overall conversion percentage on tracked opportunities (0–100).
    public let outsPerPlay: Double
    /// Burst distance vs league average, in feet (1.5–3.0 s window).
    public let relLeagueBurstDistance: Double
    /// Reaction distance vs league average, in feet (0–1.5 s window).
    public let relLeagueReactionDistance: Double
    /// Routing efficiency vs league average, in feet (path quality).
    public let relLeagueRoutingDistance: Double
    /// Total bootup distance vs league average, in feet (sum of reaction + burst + routing).
    public let relLeagueBootupDistance: Double
    /// Absolute bootup distance in feet — total ground covered in the first 3 seconds.
    public let fBootupDistance: Double
    /// Number of two-star-or-harder opportunities in the sample.
    public let opportunities: Int
    /// Number of those opportunities converted to outs.
    public let outs: Int
}

// MARK: - Pitcher Fielding Run Value

/// A single pitcher's accumulated fielding-run-value entry from the Baseball Savant
/// `fielding-run-value` leaderboard.
///
/// This board credits each pitcher with the **team-defense run value** earned during
/// their innings — i.e. the cumulative fielding runs from infielders, outfielders,
/// and the catcher (framing, blocking, and throwing) on plays where this pitcher
/// was on the mound. It is therefore a **pitcher-context** metric and not the
/// fielder's own defensive value.
///
/// Pitchers with elite team defense behind them rank highly; pitchers backed by
/// poor defenses rank low. All values are reported in runs (positive = added value).
///
/// - Note: Despite the column names, `framingRuns`, `catchingRuns`, `throwingRuns`,
///   and `blockingRuns` reflect the team's catcher behind this pitcher — not the
///   pitcher's own catching contribution.
/// - Note: Team is not included in the Savant CSV. Use ``playerId`` to look up
///   team via ``SwiftBaseball/players(ids:)``.
public struct PitcherFieldingRunValueEntry: Sendable, Equatable, Codable {
    /// MLB player ID of the pitcher.
    public let playerId: Int
    /// Pitcher's full name as returned by the leaderboard (Last, First format).
    public let playerName: String
    /// Season year.
    public let season: Int
    /// Total fielding runs accumulated by the team's defense during this pitcher's innings.
    public let totalRuns: Double
    /// Combined infield + outfield runs (range + arm + double-play turn) on this pitcher's plays.
    public let infieldOutfieldRuns: Double
    /// Range runs — infielder/outfielder positioning and reaction.
    public let rangeRuns: Double
    /// Arm runs — outfielder throwing and infielder arm strength.
    public let armRuns: Double
    /// Double-play turn runs — turning twins on this pitcher's plays.
    public let doublePlayRuns: Double
    /// Combined catching runs (framing + throwing + blocking).
    public let catchingRuns: Double
    /// Catcher framing runs on this pitcher's pitches.
    public let framingRuns: Double
    /// Catcher throwing runs (caught stealing) on this pitcher's runners.
    public let throwingRuns: Double
    /// Catcher blocking runs (wild pitches / passed balls) on this pitcher's pitches.
    public let blockingRuns: Double
    /// Total plays / batters faced included in the sample.
    public let totalPlays: Int
}

// MARK: - Baserunning Run Value

/// A single player's baserunning-run-value entry from the Baseball Savant
/// `baserunning-run-value` leaderboard.
///
/// Baserunning Run Value decomposes a runner's value into two main components:
/// taking extra bases (hits, errors, wild pitches, advancing on outs) and stolen
/// bases. Each component carries opportunity counts (`runnersMoved*` fields) and
/// run-value totals (positive = value added, negative = value lost).
///
/// Stolen-base sub-decomposition: `runnerRunsSB2` covers steals of second,
/// `runnerRunsSB3` covers steals of third, and the `simpleStolenSB*` fields carry
/// Savant's simpler "stolen base credit" decomposition for each base.
///
/// - Note: The Savant CSV exposes `start_year` and `end_year` separately — for
///   single-season queries they match. The entry's `season` is set from `start_year`.
public struct BaserunningRunValueEntry: Sendable, Equatable, Codable {
    /// MLB player ID.
    public let playerId: Int
    /// Player's full name as returned by the leaderboard (Last, First format).
    public let playerName: String
    /// Team abbreviation (e.g. `"STL"`).
    public let team: String
    /// Season year (the CSV's `start_year`).
    public let season: Int
    /// Total baserunning run value across all components.
    public let runnerRunsTotal: Double
    /// Run value from extra-base taking (advancing on hits, errors, wild pitches, outs).
    public let runnerRunsExtraBase: Double
    /// Run value from stolen-base attempts.
    public let runnerRunsStolenBase: Double
    /// Total opportunities the runner moved or could have moved.
    public let runnersMoved: Int
    /// Extra-base credit attributable to swiping (aggressive base taking).
    public let runnerRunsExtraBaseSwipe: Double
    /// Extra-base credit attributable to sniping (avoiding tags / sliding).
    public let runnerRunsExtraBaseSnipe: Double
    /// Extra-base credit attributable to freezing (holding the bag — negative if too cautious).
    public let runnerRunsExtraBaseFreeze: Double
    /// Extra-base opportunity count.
    public let runnersMovedExtraBase: Int
    /// Stolen-base run value at second base.
    public let runnerRunsSecond: Double
    /// Stolen-base run value at third base.
    public let runnerRunsThird: Double
    /// Simple stolen-base credit at second base.
    public let simpleStolenSecond: Double
    /// Simple stolen-base credit at third base.
    public let simpleStolenThird: Double
    /// Stolen-base opportunity count.
    public let runnersMovedStolenBase: Int
}

// MARK: - Swing / Take

/// A single batter's swing/take entry from the Baseball Savant `swing-take` leaderboard.
///
/// Decomposes a batter's swing-decision run value across the four pitch-location
/// zones Savant tracks:
///
/// - **Heart** — middle of the strike zone (best to swing at).
/// - **Shadow** — edges of the strike zone (borderline pitches).
/// - **Chase** — just outside the zone (the swing-decision battleground).
/// - **Waste** — far outside the zone (clearly take pitches).
///
/// All values are reported in runs above/below average (positive = better decisions
/// than league average, negative = worse). `runsAll` is the cumulative total across
/// the four zones.
public struct SwingTakeEntry: Sendable, Equatable, Codable {
    /// MLB player ID.
    public let playerId: Int
    /// Player's full name as returned by the leaderboard (Last, First format).
    public let playerName: String
    /// Team ID (MLB Stats API team identifier, e.g. `109` for Arizona).
    public let teamId: Int
    /// Season year.
    public let season: Int
    /// Plate appearances in the sample.
    public let plateAppearances: Int
    /// Total pitches seen in the sample.
    public let pitches: Int
    /// Total swing/take run value across all four zones.
    public let runsAll: Double
    /// Run value on heart-of-zone pitches (middle).
    public let runsHeart: Double
    /// Run value on shadow-zone pitches (edges of strike zone).
    public let runsShadow: Double
    /// Run value on chase-zone pitches (just outside the strike zone).
    public let runsChase: Double
    /// Run value on waste-zone pitches (far outside the strike zone).
    public let runsWaste: Double
}

// MARK: - Pitch Tilt (Spin Direction)

/// A single pitcher's spin-direction (a.k.a. pitch tilt) entry from the Baseball Savant
/// `spin-direction-pitches` leaderboard, one row per (pitcher × pitch type).
///
/// Pitch tilt expresses the axis a pitch spins around as a clock-face position — e.g.
/// `"12:00"` is pure backspin (a riding fastball), `"6:00"` is pure topspin (a 12-6
/// curveball), `"3:00"` is pure side-spin from a right-hander, and `"9:00"` is pure
/// side-spin from a left-hander. Savant publishes two tilt readings per pitch:
///
/// - **Hawk-Eye measured**: the directly observed spin axis from optical tracking.
/// - **Movement-inferred**: the spin axis a pitch would need to produce its observed
///   movement, given gravity and air resistance. This excludes gyro-spin (which does
///   not contribute to movement).
///
/// The gap between the two measurements (`diffDegrees` / `diffClockLabel`) reveals
/// how much of a pitch's spin is gyro (non-Magnus) — a large gap typically indicates
/// a slider or other gyro-heavy offering. Active spin (`activeSpinFraction`,
/// `activeSpinPercent`) is the share of total spin that produces movement.
public struct PitchTiltEntry: Sendable, Equatable, Codable {
    /// MLB player ID of the pitcher.
    public let pitcherId: Int
    /// Pitcher's full name as returned by the leaderboard (Last, First format).
    public let pitcherName: String
    /// Season year.
    public let season: Int
    /// Pitch hand (`"L"` or `"R"`).
    public let pitchHand: String
    /// Pitch type code (e.g. `"FF"`, `"SL"`, `"CU"`).
    public let pitchType: String
    /// Long-form pitch type name (e.g. `"4-Seam Fastball"`, `"Slider"`).
    public let pitchTypeName: String
    /// Number of pitches of this type thrown in the sample.
    public let pitches: Int
    /// Average release speed in mph.
    public let releaseSpeed: Double
    /// Average spin rate in rpm.
    public let spinRate: Double
    /// Total break in inches (movement magnitude).
    public let movementInches: Double
    /// Active spin as a 0–1 fraction (share of total spin that produces movement).
    public let activeSpinFraction: Double
    /// Active spin on the 0–100 scale (e.g. `96.3` means 96.3%).
    public let activeSpinPercent: Double
    /// Hawk-Eye measured spin axis in degrees (0° = 12:00, increasing clockwise).
    public let hawkeyeMeasuredDegrees: Double
    /// Movement-inferred spin axis in degrees (0° = 12:00, increasing clockwise).
    public let movementInferredDegrees: Double
    /// Difference between the two measurements in degrees (inferred minus measured).
    public let diffDegrees: Double
    /// Hawk-Eye measured tilt as a clock-face label (e.g. `"12:45"`).
    public let hawkeyeMeasuredClockLabel: String
    /// Movement-inferred tilt as a clock-face label (e.g. `"12:45"`).
    public let movementInferredClockLabel: String
    /// Difference between the two as a clock label (e.g. `"+0H 15M"`, `"-0H 15M"`, `" 0H 00M"`).
    public let diffClockLabel: String
}
