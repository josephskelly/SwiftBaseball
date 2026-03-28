import Foundation

/// An MLB award definition (e.g. AL MVP, NL Cy Young, Hall of Fame).
///
/// Returned by ``SwiftBaseball/awards()`` queries. Each entry describes one
/// award type. Use ``SwiftBaseball/awardRecipients(awardId:)`` to fetch the
/// winners for a specific award and season.
public struct Award: Codable, Sendable, Equatable, Identifiable {
    /// The unique award identifier (e.g. `"ALMVP"`, `"NLCY"`, `"MLBHOF"`).
    public let id: String
    /// Human-readable award name (e.g. `"AL MVP"`, `"NL Cy Young"`).
    public let name: String
    /// Additional descriptive text for the award.
    public let description: String?
    /// Whether this award is currently active.
    public let active: Bool
    /// The MLB league ID associated with this award, if applicable.
    public let leagueId: Int?
    /// The MLB sport ID associated with this award, if applicable.
    public let sportId: Int?
}

/// A single award recipient entry for a given season.
///
/// Returned by ``SwiftBaseball/awardRecipients(awardId:)`` queries. Each entry
/// represents one player who received the award in a particular season.
///
/// - Note: The MLB Stats API does not return the team name for recipients;
///   use ``teamId`` with ``SwiftBaseball/team(id:)`` to look up full team details.
public struct AwardRecipient: Codable, Sendable, Equatable {
    /// The award identifier (e.g. `"ALMVP"`).
    public let awardId: String
    /// The award display name (e.g. `"AL MVP"`).
    public let awardName: String
    /// The season in which the award was given (e.g. `"2024"`).
    public let season: String?
    /// The date the award was announced.
    public let date: Date?
    /// The player who received the award.
    public let player: PlayerReference?
    /// The MLB team ID of the recipient's team at the time of the award.
    public let teamId: Int?
}
