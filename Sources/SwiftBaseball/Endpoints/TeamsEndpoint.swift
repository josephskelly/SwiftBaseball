import Foundation

// MARK: - Query type

/// Query type for team endpoints.
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
    /// Fetches a team roster for the given season and roster type.
    ///
    /// - Parameters:
    ///   - teamId: The MLB team identifier.
    ///   - season: The season year (e.g. 2025).
    ///   - rosterType: Which roster list to fetch. Defaults to ``RosterType/active``
    ///     (26-man active roster). Use ``RosterType/fortyMan`` or
    ///     ``RosterType/nonRosterInvitees`` for spring training.
    static func roster(
        teamId: Int,
        season: Int,
        rosterType: RosterType = .active,
        client: any APIClient
    ) -> QueryBuilder<[RosterEntry]> {
        var queryItems = [URLQueryItem(name: "season", value: String(season))]
        if rosterType != .active {
            queryItems.append(URLQueryItem(name: "rosterType", value: rosterType.rawValue))
        }
        let endpoint = Endpoint(path: "teams/\(teamId)/roster", queryItems: queryItems)
        return QueryBuilder(endpoint: endpoint, client: client) { data in
            let response = try JSONDecoder.mlb.decode(MLBRosterResponse.self, from: data)
            return response.roster.map(MLBResponseConverters.rosterEntry)
        }
    }
}
