import Foundation

/// An MLB official scorer assigned to the active scorer pool on a given date.
///
/// Returned by ``SwiftBaseball/officialScorers(date:)``. The upstream endpoint lists
/// the full official-scorer roster eligible to work games on the requested date — it
/// is not a per-game assignment. Most entries carry ``OfficialScorer/jobId`` of
/// `"SCOR"`.
public struct OfficialScorer: Codable, Sendable, Equatable, Identifiable {
    /// Computed from the person's MLB ID.
    public var id: Int { person.id }

    /// Reference to the official scorer (id + fullName).
    public let person: PlayerReference
    /// Jersey number as a string. Almost always empty for scorers.
    public let jerseyNumber: String?
    /// Human-readable job title (e.g. `"Official Scorer"`).
    public let job: String
    /// Short role code (e.g. `"SCOR"`).
    public let jobId: String
    /// Display title, when distinct from ``job``.
    public let title: String?
}
