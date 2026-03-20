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

    /// Expected batting average based on exit velocity and launch angle.
    public let xBA: Double?
    /// Expected slugging based on exit velocity and launch angle.
    public let xSLG: Double?
    /// Expected weighted on-base average based on exit velocity and launch angle.
    public let xwOBA: Double?
}
