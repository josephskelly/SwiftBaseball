import Foundation

/// A staff member on a team — coach, manager, trainer, medical, operations, or support.
///
/// Returned by both ``SwiftBaseball/teamCoaches(teamId:)`` (on-field staff:
/// manager, bench/hitting/pitching/base coaches) and
/// ``SwiftBaseball/teamPersonnel(teamId:)`` (off-field staff: trainers,
/// physicians, strength & conditioning, equipment, clubhouse, security,
/// travel). Both endpoints share the same shape; the role is encoded in
/// ``jobId`` (stable) and ``job`` / ``title`` (human-readable).
public struct TeamStaff: Codable, Sendable, Equatable, Identifiable {
    /// Computed from the person's MLB ID.
    public var id: Int {
        person.id
    }

    /// Reference to the staff member (id + fullName).
    public let person: PlayerReference
    /// Jersey number as a string (e.g. `"17"`), when assigned.
    public let jerseyNumber: String?
    /// Human-readable job title (e.g. `"Manager"`, `"Bench Coach"`).
    public let job: String
    /// Short role code (e.g. `"MNGR"`, `"COAB"`, `"COAT"`).
    ///
    /// Stable across seasons and useful for programmatic role filtering.
    public let jobId: String
    /// Display title, when distinct from ``job``.
    ///
    /// In practice the API usually populates ``title`` and ``job`` with the
    /// same string; this field is exposed for completeness.
    public let title: String?
}
