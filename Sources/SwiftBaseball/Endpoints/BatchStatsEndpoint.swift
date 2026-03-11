import Foundation

/// A concurrent batch query for season stats across multiple players.
///
/// Fan-out is handled with `withThrowingTaskGroup`; rate limiting is enforced
/// automatically by the underlying ``APIClient``.
///
/// ```swift
/// let stats = try await SwiftBaseball
///     .batchStats([660271, 592450, 665742], group: .batting)
///     .season(2024)
///     .fetch()
/// ```
public struct BatchStatsQuery: Sendable {
    let playerIds: [Int]
    let group: StatGroup
    var seasonYear: Int?
    let client: any APIClient

    /// Returns a copy filtered to a specific season year.
    public func season(_ year: Int) -> BatchStatsQuery {
        var copy = self
        copy.seasonYear = year
        return copy
    }

    /// Executes the batch query concurrently and returns all results.
    ///
    /// Results may arrive in any order relative to `playerIds`.
    ///
    /// - Returns: All successfully fetched ``PlayerSeasonStats`` across all player IDs.
    /// - Throws: ``SwiftBaseballError`` if any individual request fails.
    public func fetch() async throws -> [PlayerSeasonStats] {
        try await withThrowingTaskGroup(of: [PlayerSeasonStats].self) { group in
            for id in playerIds {
                group.addTask {
                    var builder = QueryBuilder<[PlayerSeasonStats]>.playerStats(
                        id: id, client: client
                    )
                    builder = builder.group(self.group)
                    if let year = seasonYear {
                        builder = builder.season(year)
                    }
                    return try await builder.fetch()
                }
            }
            var results: [PlayerSeasonStats] = []
            for try await partial in group {
                results.append(contentsOf: partial)
            }
            return results
        }
    }
}
