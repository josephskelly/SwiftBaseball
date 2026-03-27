import Foundation

/// A single pick from the MLB Draft.
///
/// Returned by ``SwiftBaseball/draft(year:)`` queries. Each pick represents
/// one team selection, ordered by overall pick number. Pass picks have
/// `isPass == true` and no `person`.
public struct DraftPick: Codable, Sendable, Equatable, Identifiable {
    /// The overall pick number (1-based). Used as the stable identifier.
    public let id: Int
    /// The draft year.
    public let year: Int
    /// Round label (e.g. `"1"`, `"2"`, `"CBA"`, `"COMP"`).
    public let round: String
    /// The pick's sequence number within this round.
    public let roundPickNumber: Int?
    /// The team that made the selection.
    public let team: TeamReference?
    /// The player selected. `nil` for pass picks.
    public let person: PlayerReference?
    /// The school or organization the player is coming from.
    public let school: School?
    /// Reported signing bonus (e.g. `"$9,500,000"`). `nil` until the pick signs.
    public let signingBonus: String?
    /// Brief player biography or summary blurb.
    public let blurb: String?
    /// Detailed pre-draft scouting report.
    public let scoutingReport: String?
    /// `true` once the pick has been used.
    public let isDrafted: Bool
    /// `true` if the team passed on this selection slot.
    public let isPass: Bool
}

/// The school or organization a draft prospect is coming from.
public struct School: Codable, Sendable, Equatable {
    /// School or program name (e.g. `"LSU"`, `"Vanderbilt"`).
    public let name: String?
    /// Level of play: `"College"`, `"HS"`, `"JUCO"`, etc.
    public let schoolClass: String?
    /// City where the school is located.
    public let city: String?
    /// State abbreviation (e.g. `"CA"`, `"TX"`).
    public let state: String?
    /// Country (e.g. `"USA"`, `"Dominican Republic"`).
    public let country: String?
}
