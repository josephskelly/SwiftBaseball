import Foundation

// MARK: - QueryBuilder factories

extension QueryBuilder where T == LiveGameFeed {
    /// Builds a query for the live game feed at
    /// `GET /api/v1.1/game/{gamePk}/feed/live`.
    static func liveGameFeed(gamePk: Int, client: any APIClient) -> QueryBuilder<LiveGameFeed> {
        let endpoint = Endpoint(
            path: "game/\(gamePk)/feed/live",
            version: "v1.1"
        )
        return QueryBuilder(endpoint: endpoint, client: client) { data in
            let response = try JSONDecoder.mlb.decode(MLBLiveGameFeedResponse.self, from: data)
            return MLBResponseConverters.liveGameFeed(from: response)
        }
    }
}
