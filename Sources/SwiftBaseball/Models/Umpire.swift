import Foundation

/// An MLB umpire assigned to the active umpire pool on a given date.
///
/// Returned by ``SwiftBaseball/umpires(date:)``. The upstream endpoint lists
/// the full umpire roster eligible to work games on the requested date — it
/// is not a per-game crew assignment. Most entries carry
/// ``Umpire/jobId`` of `"UMPR"`; crew chiefs and other umpire-desk roles
/// use distinct codes.
public struct Umpire: Codable, Sendable, Equatable, Identifiable {
    /// Computed from the person's MLB ID.
    public var id: Int {
        person.id
    }

    /// Reference to the umpire (id + fullName).
    public let person: PlayerReference
    /// Jersey number as a string (e.g. `"67"`), when assigned.
    public let jerseyNumber: String?
    /// Human-readable job title (e.g. `"Umpire"`, `"Crew Chief"`).
    public let job: String
    /// Short role code (e.g. `"UMPR"` for umpire).
    public let jobId: String
    /// Display title, when distinct from ``job``.
    public let title: String?
}
