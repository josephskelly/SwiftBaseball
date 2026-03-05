import Foundation

// MARK: - Query types

public enum StatsQuery: Sendable {
    case batting
    case pitching
    case fielding
}

// MARK: - QueryBuilder factories

extension QueryBuilder where T == [PlayerSeasonStats] {
    static func playerStats(id: Int, client: any APIClient) -> QueryBuilder<[PlayerSeasonStats]> {
        let endpoint = Endpoint(path: "people/\(id)/stats", queryItems: [
            URLQueryItem(name: "stats", value: "season")
        ])
        let ref = PlayerReference(id: id, fullName: "")
        return QueryBuilder(endpoint: endpoint, client: client) { data in
            let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: data)
            return MLBResponseConverters.playerSeasonStats(from: response, playerRef: ref)
        }
    }
}
