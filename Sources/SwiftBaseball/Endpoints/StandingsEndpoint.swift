import Foundation

// MARK: - Query type

/// Query type for standings endpoints.
public enum StandingsQuery: Sendable {
    case season(Int)
    case regularSeason(Int)
}

// MARK: - Endpoint construction

extension StandingsQuery {
    var endpoint: Endpoint {
        switch self {
        case .season(let year), .regularSeason(let year):
            return Endpoint(path: "standings", queryItems: [
                URLQueryItem(name: "leagueId", value: "103,104"),
                URLQueryItem(name: "season", value: String(year)),
                URLQueryItem(name: "standingsTypes", value: "regularSeason"),
                URLQueryItem(name: "hydrate", value: "division")
            ])
        }
    }
}

// MARK: - QueryBuilder factory

extension QueryBuilder where T == [DivisionStandings] {
    static func standings(_ query: StandingsQuery, client: any APIClient) -> QueryBuilder<[DivisionStandings]> {
        QueryBuilder(endpoint: query.endpoint, client: client) { data in
            let response = try JSONDecoder.mlb.decode(MLBStandingsResponse.self, from: data)
            return MLBResponseConverters.divisionStandings(from: response)
        }
    }
}
