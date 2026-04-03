import Foundation

/// Aggregated Statcast batted ball and quality-of-contact statistics.
///
/// Computed from pitch-level data fetched from Baseball Savant.
/// All percentages are expressed as values between 0 and 1 (e.g. 0.45 = 45%).
public struct StatcastBatting: Sendable, Equatable, Codable {
    /// Total batted ball events used to compute percentages.
    public let battedBallEvents: Int
    /// Ground ball count.
    public let groundBalls: Int
    /// Fly ball count.
    public let flyBalls: Int
    /// Line drive count.
    public let lineDrives: Int
    /// Popup count.
    public let popups: Int

    /// Ground ball rate (0–1).
    public let gbPercent: Double?
    /// Fly ball rate (0–1).
    public let fbPercent: Double?
    /// Line drive rate (0–1).
    public let ldPercent: Double?
    /// Popup rate (0–1).
    public let popupPercent: Double?

    /// Average exit velocity (mph) across all batted ball events.
    public let avgExitVelocity: Double?
    /// Maximum exit velocity (mph) in the sample.
    public let maxExitVelocity: Double?
    /// Average launch angle (degrees).
    public let avgLaunchAngle: Double?

    /// Barrel rate: fraction of batted balls classified as barrels (0–1).
    ///
    /// A barrel is a batted ball with an optimal combination of exit velocity
    /// and launch angle, typically producing a hit ~.500+ of the time.
    public let barrelRate: Double?
    /// Hard-hit rate: fraction of batted balls with exit velocity >= 95 mph (0–1).
    public let hardHitRate: Double?

    /// Expected batting average based on exit velocity and launch angle (BBE mean).
    public let xBA: Double?
    /// Expected slugging based on exit velocity and launch angle (BBE mean).
    public let xSLG: Double?
    /// Full-PA expected weighted on-base average.
    ///
    /// Blends contact xwOBA (`estimated_woba_using_speedangle`) over batted ball events
    /// with per-event linear weights for strikeouts (0.000), walks (0.690), and HBP (0.720),
    /// then divides by total plate appearances. Matches Baseball Savant xwOBA methodology.
    public let xwOBA: Double?

    // MARK: - Plate Appearance Counts

    /// Strikeouts in the sample.
    public let strikeouts: Int
    /// Walks (unintentional) in the sample.
    public let walks: Int
    /// Hit by pitches in the sample.
    public let hitByPitches: Int
    /// Total plate appearances (BBE + strikeouts + walks + HBP).
    public let plateAppearances: Int
}

// MARK: - Career splits

/// Career plate-appearance stats for one opposing-pitcher-handedness split,
/// sourced from Baseball Savant. Covers the Statcast era (2015–present).
public struct CareerSplitStats: Sendable, Equatable {
    /// Full-PA career xwOBA (contact xwOBA blended with walk/HBP linear weights).
    ///
    /// Mirrors the Baseball Savant xwOBA methodology: each in-play event contributes
    /// its `estimated_woba_using_speedangle` value; walks contribute 0.690;
    /// HBP contributes 0.720; strikeouts contribute 0.000.
    public let xwOBA: Double?
    /// Total plate appearances in this split.
    public let pa: Int
    /// `true` if the Savant response hit the 25,000-row cap and data may be incomplete.
    ///
    /// When `true`, treat `xwOBA` and `pa` as lower bounds, not exact career totals.
    /// Career leaders with long tenures (e.g. 10+ Statcast seasons vs one handedness)
    /// are most likely to be affected.
    public let isTruncated: Bool
}

/// Career Statcast batting splits keyed by opposing pitcher handedness.
///
/// Returned by ``SwiftBaseball/statcastCareerSplits(playerId:)`` and
/// ``SwiftBaseball/statcastBatchCareerSplits(_:)``.
public struct StatcastCareerSplits: Sendable, Equatable {
    /// Career stats vs left-handed pitchers.
    public let vsLHP: CareerSplitStats
    /// Career stats vs right-handed pitchers.
    public let vsRHP: CareerSplitStats
}
