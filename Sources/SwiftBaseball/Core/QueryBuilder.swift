import Foundation

/// A chainable query builder that configures and executes MLB Stats API requests.
///
/// Build queries using the fluent API on ``SwiftBaseball``, then call ``fetch()`` to execute.
///
/// ```swift
/// let schedule = try await SwiftBaseball.schedule()
///     .season(2024)
///     .teamId(147)
///     .fetch()
/// ```
public struct QueryBuilder<T: Sendable>: Sendable {
    let endpoint: Endpoint
    let client: any APIClient
    let transform: @Sendable (Data) throws -> T

    init(
        endpoint: Endpoint,
        client: any APIClient,
        transform: @escaping @Sendable (Data) throws -> T
    ) {
        self.endpoint = endpoint
        self.client = client
        self.transform = transform
    }

    // MARK: - Terminal

    /// Executes the query and returns the decoded result.
    ///
    /// - Returns: The decoded response of type `T`.
    /// - Throws: ``SwiftBaseballError`` if the request or decoding fails.
    public func fetch() async throws -> T {
        let data = try await client.fetchRaw(endpoint)
        do {
            return try transform(data)
        } catch let error as SwiftBaseballError {
            throw error
        } catch let error as DecodingError {
            throw SwiftBaseballError.decodingError(error)
        }
    }

    // MARK: - Fluent modifiers

    /// Filters results to a specific season year.
    public func season(_ year: Int) -> QueryBuilder<T> {
        modifying { $0.adding(name: "season", value: String(year)) }
    }

    /// Limits the number of results returned.
    public func limit(_ count: Int) -> QueryBuilder<T> {
        modifying { $0.adding(name: "limit", value: String(count)) }
    }

    /// Filters results to a specific league.
    public func league(_ league: League) -> QueryBuilder<T> {
        modifying { $0.replacing(name: "leagueId", value: String(league.leagueId)) }
    }

    /// Filters results to a specific team by MLB team ID.
    public func teamId(_ id: Int) -> QueryBuilder<T> {
        modifying { $0.adding(name: "teamId", value: String(id)) }
    }

    /// Filters results to a specific date in `"YYYY-MM-DD"` format.
    public func date(_ dateString: String) -> QueryBuilder<T> {
        modifying { $0.adding(name: "date", value: dateString) }
    }

    /// Filters results to a date range. Both dates use `"YYYY-MM-DD"` format.
    public func dateRange(start: String, end: String) -> QueryBuilder<T> {
        modifying {
            $0.adding(name: "startDate", value: start)
             .adding(name: "endDate", value: end)
        }
    }

    /// Filters stats by group (batting, pitching, or fielding).
    public func group(_ group: StatGroup) -> QueryBuilder<T> {
        modifying { $0.adding(name: "group", value: group.apiValue) }
    }

    // MARK: - Private

    private func modifying(_ transform: (Endpoint) -> Endpoint) -> QueryBuilder<T> {
        QueryBuilder(endpoint: transform(endpoint), client: client, transform: self.transform)
    }
}
