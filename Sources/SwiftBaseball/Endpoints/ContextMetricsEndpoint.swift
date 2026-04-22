import Foundation

// MARK: - QueryBuilder factories

extension QueryBuilder where T == GameContextMetrics {
    static func contextMetrics(gamePk: Int, client: any APIClient) -> QueryBuilder<GameContextMetrics> {
        let endpoint = Endpoint(path: "game/\(gamePk)/contextMetrics")
        return QueryBuilder(endpoint: endpoint, client: client) { data in
            let response = try JSONDecoder.mlb.decode(MLBContextMetricsResponse.self, from: data)
            return MLBResponseConverters.contextMetrics(from: response)
        }
    }
}
