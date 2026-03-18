import Foundation

// MARK: - Query type

/// Query type for game schedule endpoints.
public enum ScheduleQuery: Sendable {
    case date(String)               // "2024-07-04"
    case dateRange(String, String)  // start, end
    case season(Int)
}

// MARK: - Endpoint construction

extension ScheduleQuery {
    /// Minimal field list for schedule responses.
    ///
    /// Strips fields the app never reads — `leagueRecord`, `score`, `isWinner`,
    /// `splitSquad`, series metadata, and unused status codes — to reduce payload
    /// size and lower the chance of hitting MLB Stats API rate limits.
    private static let scheduleFields = [
        "dates", "dates.date", "dates.games", "dates.games.gamePk", "dates.games.gameDate",
        "dates.games.status", "dates.games.status.detailedState",
        "dates.games.status.abstractGameState",
        "dates.games.teams", "dates.games.teams.away", "dates.games.teams.away.team",
        "dates.games.teams.away.team.id", "dates.games.teams.away.team.name",
        "dates.games.teams.home", "dates.games.teams.home.team",
        "dates.games.teams.home.team.id", "dates.games.teams.home.team.name",
        "dates.games.venue", "dates.games.venue.id", "dates.games.venue.name",
        "dates.games.gameType", "dates.games.season"
    ].joined(separator: ",")

    var endpoint: Endpoint {
        let fieldsItem = URLQueryItem(name: "fields", value: Self.scheduleFields)
        switch self {
        case .date(let date):
            return Endpoint(path: "schedule", queryItems: [
                URLQueryItem(name: "sportId", value: "1"),
                URLQueryItem(name: "date", value: date),
                fieldsItem
            ])
        case .dateRange(let start, let end):
            return Endpoint(path: "schedule", queryItems: [
                URLQueryItem(name: "sportId", value: "1"),
                URLQueryItem(name: "startDate", value: start),
                URLQueryItem(name: "endDate", value: end),
                fieldsItem
            ])
        case .season(let year):
            return Endpoint(path: "schedule", queryItems: [
                URLQueryItem(name: "sportId", value: "1"),
                URLQueryItem(name: "season", value: String(year)),
                fieldsItem
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
