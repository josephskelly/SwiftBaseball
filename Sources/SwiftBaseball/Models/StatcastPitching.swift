import Foundation

/// Aggregated Statcast pitching statistics from Baseball Savant.
///
/// Combines batted-ball-against data (the same metrics as ``StatcastBatting``,
/// but from the pitcher's perspective) with pitch-arsenal metrics such as
/// velocity, spin rate, whiff rate, and pitch-type usage.
///
/// All percentages are expressed as values between 0 and 1 (e.g. 0.25 = 25%).
public struct StatcastPitching: Sendable, Equatable, Codable {

    // MARK: - Batted Ball Against

    /// Total batted ball events used to compute batted-ball percentages.
    public let battedBallEvents: Int
    /// Ground ball count against.
    public let groundBalls: Int
    /// Fly ball count against.
    public let flyBalls: Int
    /// Line drive count against.
    public let lineDrives: Int
    /// Popup count against.
    public let popups: Int

    /// Ground ball rate against (0–1).
    public let gbPercent: Double?
    /// Fly ball rate against (0–1).
    public let fbPercent: Double?
    /// Line drive rate against (0–1).
    public let ldPercent: Double?
    /// Popup rate against (0–1).
    public let popupPercent: Double?

    /// Average exit velocity against (mph).
    public let avgExitVelocity: Double?
    /// Maximum exit velocity against (mph).
    public let maxExitVelocity: Double?
    /// Average launch angle against (degrees).
    public let avgLaunchAngle: Double?

    /// Barrel rate against (0–1).
    public let barrelRate: Double?
    /// Hard-hit rate against: fraction of batted balls with exit velocity >= 95 mph (0–1).
    public let hardHitRate: Double?

    /// Expected batting average against.
    public let xBA: Double?
    /// Expected slugging against.
    public let xSLG: Double?
    /// Expected weighted on-base average against.
    public let xwOBA: Double?

    // MARK: - PA Event Counts

    /// Strikeouts recorded against this pitcher in the sample.
    public let strikeouts: Int
    /// Walks (BB) allowed in the sample.
    public let walks: Int
    /// Hit-by-pitches (HBP) allowed in the sample.
    public let hitByPitch: Int
    /// Innings pitched derived from recorded outs in the sample.
    public let inningsPitched: Double

    // MARK: - Expected Performance

    /// Expected ERA derived from per-PA xwOBA.
    ///
    /// Computed by blending xwOBA on contact (`estimated_woba_using_speedangle`) with
    /// per-event linear weights for strikeouts (0.000), walks (0.690), and HBP (0.720)
    /// across all plate appearances, then scaling via the linear approximation
    /// `xERA = fullPAxwOBA × 13.0`.
    ///
    /// This is an approximation; values calibrate so that an average xwOBA (~0.320) maps
    /// to roughly league-average ERA (~4.16). `nil` when fewer than 3 PA-terminating
    /// events exist in the sample.
    public let xERA: Double?

    /// Expected FIP using `xHR = flyBalls × leagueHRperFBRate`.
    ///
    /// Formula: `((13 × xHR + 3 × (BB + HBP) − 2 × K) / IP) + FIPconstant`
    ///
    /// Uses hardcoded constants: `leagueHRperFBRate = 0.105`, `FIPconstant = 3.10`.
    /// `nil` when fewer than 1.0 innings pitched exists in the sample.
    public let xFIP: Double?

    // MARK: - Pitch Arsenal

    /// Total pitches thrown in the sample.
    public let totalPitches: Int
    /// Average fastball velocity (mph) across FF, SI, and FC pitch types.
    public let avgFastballVelo: Double?
    /// Maximum fastball velocity (mph) across FF, SI, and FC pitch types.
    public let maxFastballVelo: Double?
    /// Average spin rate (RPM) across all pitches.
    public let avgSpinRate: Double?
    /// Whiff rate: swinging strikes / total swings (0–1).
    public let whiffRate: Double?
    /// Called strikes + whiffs rate: (called strikes + swinging strikes) / total pitches (0–1).
    public let csw: Double?
    /// Pitch mix breakdown sorted by usage frequency.
    public let pitchMix: [PitchMixEntry]
}

/// A single entry in a pitcher's pitch-mix breakdown.
public struct PitchMixEntry: Sendable, Equatable, Identifiable, Codable {
    /// Unique identifier matching the pitch name.
    public var id: String { name }
    /// Human-readable pitch name (e.g. "4-Seam Fastball").
    public let name: String
    /// Number of times this pitch was thrown.
    public let count: Int
    /// Usage rate (0–1).
    public let percentage: Double
    /// Average release velocity for this pitch type (mph).
    public let avgVelocity: Double?
    /// Average spin rate for this pitch type (RPM).
    public let avgSpinRate: Double?
    /// Average horizontal movement (`pfx_x`) in feet (Baseball Savant CSV units).
    ///
    /// Positive values indicate arm-side run; negative values indicate glove-side break,
    /// both from the catcher's perspective. Multiply by 12 to convert to inches.
    public let avgHorizontalBreak: Double?
    /// Average induced vertical break (`pfx_z`) in feet (Baseball Savant CSV units).
    ///
    /// Positive values indicate rise (less gravity-drop than a spinless pitch);
    /// negative values indicate additional downward break. Multiply by 12 to convert to inches.
    public let avgInducedVerticalBreak: Double?
    /// Whiff rate for this pitch type: swinging strikes / total swings (0–1).
    ///
    /// `nil` when no swings were recorded against this pitch in the sample.
    public let whiffRate: Double?
    /// Called strikes + whiffs rate for this pitch type:
    /// (called strikes + swinging strikes) / total pitches of this type (0–1).
    ///
    /// `nil` when no pitches of this type were recorded in the sample.
    public let csw: Double?
    /// Expected weighted on-base average on contact for this pitch type.
    ///
    /// Averaged from `estimated_woba_using_speedangle` across batted balls of this
    /// pitch type only. `nil` when no batted ball events exist for this pitch in the sample.
    public let xwOBA: Double?

    enum CodingKeys: String, CodingKey {
        case name, count, percentage, avgVelocity, avgSpinRate
        case avgHorizontalBreak, avgInducedVerticalBreak, whiffRate, csw, xwOBA
    }
}
