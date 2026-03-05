import Foundation

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

    public func season(_ year: Int) -> QueryBuilder<T> {
        modifying { $0.adding(name: "season", value: String(year)) }
    }

    public func limit(_ count: Int) -> QueryBuilder<T> {
        modifying { $0.adding(name: "limit", value: String(count)) }
    }

    public func league(_ league: League) -> QueryBuilder<T> {
        modifying { $0.replacing(name: "leagueId", value: String(league.leagueId)) }
    }

    public func teamId(_ id: Int) -> QueryBuilder<T> {
        modifying { $0.adding(name: "teamId", value: String(id)) }
    }

    public func date(_ dateString: String) -> QueryBuilder<T> {
        modifying { $0.adding(name: "date", value: dateString) }
    }

    public func dateRange(start: String, end: String) -> QueryBuilder<T> {
        modifying {
            $0.adding(name: "startDate", value: start)
             .adding(name: "endDate", value: end)
        }
    }

    public func group(_ group: StatGroup) -> QueryBuilder<T> {
        modifying { $0.adding(name: "group", value: group.apiValue) }
    }

    // MARK: - Private

    private func modifying(_ transform: (Endpoint) -> Endpoint) -> QueryBuilder<T> {
        QueryBuilder(endpoint: transform(endpoint), client: client, transform: self.transform)
    }
}
