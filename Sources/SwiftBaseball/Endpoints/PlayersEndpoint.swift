import Foundation

// MARK: - Query type

/// Query type for player search endpoints.
public enum PlayerQuery: Sendable {
    case search(String)
}

// MARK: - Endpoint construction

extension PlayerQuery {
    var endpoint: Endpoint {
        switch self {
        case .search(let name):
            return Endpoint(path: "people/search", queryItems: [
                URLQueryItem(name: "names", value: name),
                URLQueryItem(name: "hydrate", value: "currentTeam")
            ])
        }
    }
}

// MARK: - QueryBuilder factories

extension QueryBuilder where T == [Player] {
    static func players(_ query: PlayerQuery, client: any APIClient) -> QueryBuilder<[Player]> {
        QueryBuilder(endpoint: query.endpoint, client: client) { data in
            let response = try JSONDecoder.mlb.decode(MLBPeopleResponse.self, from: data)
            return response.people.map(MLBResponseConverters.player)
        }
    }
}

extension QueryBuilder where T == Player {
    static func singlePlayer(id: Int, client: any APIClient) -> QueryBuilder<Player> {
        let endpoint = Endpoint(path: "people/\(id)", queryItems: [
            URLQueryItem(name: "hydrate", value: "currentTeam")
        ])
        return QueryBuilder(endpoint: endpoint, client: client) { data in
            let response = try JSONDecoder.mlb.decode(MLBPeopleResponse.self, from: data)
            guard let person = response.people.first else {
                throw SwiftBaseballError.playerNotFound(String(id))
            }
            return MLBResponseConverters.player(from: person)
        }
    }
}
