import Foundation

/// A sport or baseball level from the MLB Stats API's `/sports` catalog.
///
/// Returned by ``SwiftBaseball/sports()``. Covers MLB (`id: 1`), each minor
/// league level (AAA, AA, High-A, Single-A, Rookie), foreign professional
/// leagues (KBO, NPB), international/Olympic competition, and the Negro
/// Leagues historical catalog.
///
/// Distinct from ``Sport`` — the ``Sport`` enum is a fixed, type-safe set of
/// minor league levels used in query chains (e.g. `.sport(.tripleA)`). This
/// type is the full catalog record returned by the lookup endpoint.
public struct SportCatalog: Codable, Sendable, Equatable, Identifiable {
    /// Stable sport identifier (e.g. `1` for MLB).
    public let id: Int
    /// Short machine code (e.g. `"mlb"`, `"aaa"`, `"kor"`).
    public let code: String?
    /// Display name (e.g. `"Major League Baseball"`).
    public let name: String
    /// Display abbreviation (e.g. `"MLB"`, `"AAA"`).
    public let abbreviation: String?
    /// Sort order used by MLB to group levels in UI.
    public let sortOrder: Int?
    /// Whether the sport is currently active in the API catalog.
    public let active: Bool
}
