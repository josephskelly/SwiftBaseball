import Foundation

// MARK: - Query type

public enum ScheduleQuery: Sendable {
    case date(String)               // "2024-07-04"
    case dateRange(String, String)  // start, end
    case season(Int)
}

// MARK: - Endpoint construction

extension ScheduleQuery {
    var endpoint: Endpoint {
        switch self {
        case .date(let date):
            return Endpoint(path: "schedule", queryItems: [
                URLQueryItem(name: "sportId", value: "1"),
                URLQueryItem(name: "date", value: date)
            ])
        case .dateRange(let start, let end):
            return Endpoint(path: "schedule", queryItems: [
                URLQueryItem(name: "sportId", value: "1"),
                URLQueryItem(name: "startDate", value: start),
                URLQueryItem(name: "endDate", value: end)
            ])
        case .season(let year):
            return Endpoint(path: "schedule", queryItems: [
                URLQueryItem(name: "sportId", value: "1"),
                URLQueryItem(name: "season", value: String(year))
            ])
        }
    }
}

// MARK: - QueryBuilder factory

extension QueryBuilder where T == [ScheduleEntry] {
    static func schedule(_ query: ScheduleQuery, client: any APIClient) -> QueryBuilder<[ScheduleEntry]> {
        QueryBuilder(endpoint: query.endpoint, client: client) { data in
            let response = try JSONDecoder.mlb.decode(MLBScheduleResponse.self, from: data)
            return MLBResponseConverters.scheduleEntries(from: response)
        }
    }
}
