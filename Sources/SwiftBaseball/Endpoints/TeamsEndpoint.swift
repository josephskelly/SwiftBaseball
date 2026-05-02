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
            Endpoint(path: "teams", queryItems: [
                URLQueryItem(name: "sportId", value: "1"),
                URLQueryItem(name: "season", value: String(season))
            ])
        case let .roster(teamId, season):
            Endpoint(path: "teams/\(teamId)/roster", queryItems: [
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
    /// Works for both MLB and minor league team IDs. For minor league teams,
    /// omitting `rosterType` (using the default ``RosterType/active``) returns
    /// the active roster; pass ``RosterType/fullSeason`` to get every player
    /// who appeared on the team during the season.
    ///
    /// - Parameters:
    ///   - teamId: The MLB or minor league team identifier.
    ///   - season: The season year (e.g. 2025).
    ///   - rosterType: Which roster list to fetch. Defaults to ``RosterType/active``.
    ///   - date: Optional date string (`"YYYY-MM-DD"`) for historical roster lookups.
    static func roster(
        teamId: Int,
        season: Int,
        rosterType: RosterType = .active,
        date: String? = nil,
        client: any APIClient
    ) -> QueryBuilder<[RosterEntry]> {
        var queryItems = [URLQueryItem(name: "season", value: String(season))]
        if rosterType != .active {
            queryItems.append(URLQueryItem(name: "rosterType", value: rosterType.rawValue))
        }
        if let date {
            queryItems.append(URLQueryItem(name: "date", value: date))
        }
        let endpoint = Endpoint(path: "teams/\(teamId)/roster", queryItems: queryItems)
        return QueryBuilder(endpoint: endpoint, client: client) { data in
            let response = try JSONDecoder.mlb.decode(MLBRosterResponse.self, from: data)
            return response.roster.map(MLBResponseConverters.rosterEntry)
        }
    }
}

// MARK: - Affiliates

extension QueryBuilder where T == [Team] {
    /// Fetches all affiliate teams for an MLB organization.
    static func affiliates(teamId: Int, season: Int, client: any APIClient) -> QueryBuilder<[Team]> {
        let endpoint = Endpoint(path: "teams/\(teamId)/affiliates", queryItems: [
            URLQueryItem(name: "season", value: String(season))
        ])
        return QueryBuilder(endpoint: endpoint, client: client) { data in
            let response = try JSONDecoder.mlb.decode(MLBTeamsResponse.self, from: data)
            return response.teams.map(MLBResponseConverters.team)
        }
    }
}

// MARK: - Team venue history

extension QueryBuilder where T == [Team] {
    /// Fetches venue-change history for one or more franchises.
    ///
    /// Each returned ``Team`` is a snapshot of the franchise at a season when
    /// its home venue (or location) changed. ``Team/season`` carries the year
    /// of that snapshot and ``Team/venue`` the home park as of that season.
    /// Results are ordered most-recent first within each team. Division and
    /// other roster-context fields not included by the upstream history
    /// endpoint default to sentinel values (id 0, empty name).
    static func teamHistory(teamIds: [Int], client: any APIClient) -> QueryBuilder<[Team]> {
        let endpoint = Endpoint(path: "teams/history", queryItems: [
            URLQueryItem(name: "teamIds", value: teamIds.map(String.init).joined(separator: ","))
        ])
        return QueryBuilder(endpoint: endpoint, client: client) { data in
            let response = try JSONDecoder.mlb.decode(MLBTeamsResponse.self, from: data)
            return response.teams.map(MLBResponseConverters.team)
        }
    }
}
