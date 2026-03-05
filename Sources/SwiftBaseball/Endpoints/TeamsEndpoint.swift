import Foundation

// MARK: - Query type

public enum TeamQuery: Sendable {
    case all(season: Int)
    case roster(teamId: Int, season: Int)
}

// MARK: - Endpoint construction

extension TeamQuery {
    var endpoint: Endpoint {
        switch self {
        case .all(let season):
            return Endpoint(path: "teams", queryItems: [
                URLQueryItem(name: "sportId", value: "1"),
                URLQueryItem(name: "season", value: String(season))
            ])
        case .roster(let teamId, let season):
            return Endpoint(path: "teams/\(teamId)/roster", queryItems: [
                URLQueryItem(name: "season", value: String(season))
            ])
        }
    }
}

// MARK: - QueryBuilder factories

extension QueryBuilder where T == [Team] {
    static func teams(_ query: TeamQuery, client: any APIClient) -> QueryBuilder<[Team]> {
        QueryBuilder(endpoint: query.endpoint, client: client) { data in
            let response = try JSONDecoder.mlb.decode(MLBTeamsResponse.self, from: data)
            return response.teams.map(MLBResponseConverters.team)
        }
    }

    static func team(id: Int, client: any APIClient) -> QueryBuilder<[Team]> {
        let endpoint = Endpoint(path: "teams/\(id)")
        return QueryBuilder(endpoint: endpoint, client: client) { data in
            let response = try JSONDecoder.mlb.decode(MLBTeamsResponse.self, from: data)
            return response.teams.map(MLBResponseConverters.team)
        }
    }
}

extension QueryBuilder where T == Team {
    static func singleTeam(id: Int, client: any APIClient) -> QueryBuilder<Team> {
        let endpoint = Endpoint(path: "teams/\(id)")
        return QueryBuilder(endpoint: endpoint, client: client) { data in
            let response = try JSONDecoder.mlb.decode(MLBTeamsResponse.self, from: data)
            guard let team = response.teams.first else {
                throw SwiftBaseballError.invalidResponse(statusCode: 404)
            }
            return MLBResponseConverters.team(from: team)
        }
    }
}

extension QueryBuilder where T == [RosterEntry] {
    static func roster(teamId: Int, season: Int, client: any APIClient) -> QueryBuilder<[RosterEntry]> {
        let endpoint = Endpoint(path: "teams/\(teamId)/roster", queryItems: [
            URLQueryItem(name: "season", value: String(season))
        ])
        return QueryBuilder(endpoint: endpoint, client: client) { data in
            let response = try JSONDecoder.mlb.decode(MLBRosterResponse.self, from: data)
            return response.roster.map(MLBResponseConverters.rosterEntry)
        }
    }
}
