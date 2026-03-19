import Foundation

/// Aggregated Statcast pitching statistics from Baseball Savant.
///
/// Combines batted-ball-against data (the same metrics as ``StatcastBatting``,
/// but from the pitcher's perspective) with pitch-arsenal metrics such as
/// velocity, spin rate, whiff rate, and pitch-type usage.
///
/// All percentages are expressed as values between 0 and 1 (e.g. 0.25 = 25%).
public struct StatcastPitching: Sendable, Equatable {

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
public struct PitchMixEntry: Sendable, Equatable, Identifiable {
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
}
