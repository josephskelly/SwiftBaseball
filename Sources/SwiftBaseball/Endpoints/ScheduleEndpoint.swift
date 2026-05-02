import Foundation

// MARK: - Query type

/// Query type for game schedule endpoints.
public enum ScheduleQuery: Sendable {
    case date(String) // "2024-07-04"
    case dateRange(String, String) // start, end
    case season(Int)
}

// MARK: - Hydration

/// Optional data to embed in a schedule response via the MLB Stats API `hydrate` parameter.
public enum ScheduleHydration: String, Sendable {
    /// Embeds ``PlayerReference`` for each team's probable starting pitcher.
    case probablePitcher
}

// MARK: - Endpoint construction

extension ScheduleQuery {
    func endpoint(hydrating hydrations: [ScheduleHydration] = []) -> Endpoint {
        var items = baseQueryItems
        if !hydrations.isEmpty {
            items.append(URLQueryItem(name: "hydrate", value: hydrations.map(\.rawValue).joined(separator: ",")))
        }
        return Endpoint(path: "schedule", queryItems: items)
    }

    private var baseQueryItems: [URLQueryItem] {
        switch self {
        case .date(let date):
            [
                URLQueryItem(name: "sportId", value: "1"),
                URLQueryItem(name: "date", value: date)
            ]
        case let .dateRange(start, end):
            [
                URLQueryItem(name: "sportId", value: "1"),
                URLQueryItem(name: "startDate", value: start),
                URLQueryItem(name: "endDate", value: end)
            ]
        case .season(let year):
            [
                URLQueryItem(name: "sportId", value: "1"),
                URLQueryItem(name: "season", value: String(year))
            ]
        }
    }
}

// MARK: - QueryBuilder factory

extension QueryBuilder where T == [ScheduleEntry] {
    /// Creates a schedule query builder.
    ///
    /// - Parameters:
    ///   - query: The date/range/season to fetch.
    ///   - hydrate: Additional data to embed in the response. Pass ``ScheduleHydration/probablePitcher``
    ///     to populate ``ScheduleTeamEntry/probablePitcher`` on each game.
    ///   - client: The API client to use.
    static func schedule(
        _ query: ScheduleQuery,
        hydrate: [ScheduleHydration] = [],
        client: any APIClient
    ) -> QueryBuilder<[ScheduleEntry]> {
        QueryBuilder(endpoint: query.endpoint(hydrating: hydrate), client: client) { data in
            let response = try JSONDecoder.mlb.decode(MLBScheduleResponse.self, from: data)
            return MLBResponseConverters.scheduleEntries(from: response)
        }
    }

    /// Creates a query builder for the dedicated postseason schedule endpoint.
    ///
    /// Returns every postseason game (Wild Card, Division, League Championship, World Series)
    /// for the requested season as a flat list, in scheduled order.
    static func postseasonSchedule(
        season: Int,
        client: any APIClient
    ) -> QueryBuilder<[ScheduleEntry]> {
        let endpoint = Endpoint(path: "schedule/postseason", queryItems: [
            URLQueryItem(name: "sportId", value: "1"),
            URLQueryItem(name: "season", value: String(season))
        ])
        return QueryBuilder(endpoint: endpoint, client: client) { data in
            let response = try JSONDecoder.mlb.decode(MLBScheduleResponse.self, from: data)
            return MLBResponseConverters.scheduleEntries(from: response)
        }
    }
}

extension QueryBuilder where T == [PostseasonSeries] {
    /// Creates a query builder for the postseason series endpoint.
    ///
    /// Returns one ``PostseasonSeries`` per matchup (Wild Card, Division, League Championship,
    /// World Series), each grouping the games actually played in that series.
    static func postseasonSeries(
        season: Int,
        client: any APIClient
    ) -> QueryBuilder<[PostseasonSeries]> {
        let endpoint = Endpoint(path: "schedule/postseason/series", queryItems: [
            URLQueryItem(name: "sportId", value: "1"),
            URLQueryItem(name: "season", value: String(season))
        ])
        return QueryBuilder(endpoint: endpoint, client: client) { data in
            let response = try JSONDecoder.mlb.decode(MLBPostseasonSeriesResponse.self, from: data)
            return MLBResponseConverters.postseasonSeries(from: response)
        }
    }
}
