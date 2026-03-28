import Foundation

extension QueryBuilder where T == GameHighlights {
    /// Builds a query for highlight videos from `GET /api/v1/game/{gamePk}/content`.
    static func gameHighlights(gamePk: Int, client: any APIClient) -> QueryBuilder<GameHighlights> {
        let endpoint = Endpoint(path: "game/\(gamePk)/content")
        return QueryBuilder(endpoint: endpoint, client: client) { data in
            let response = try JSONDecoder.mlb.decode(MLBGameContentResponse.self, from: data)
            return MLBResponseConverters.gameHighlights(from: response)
        }
    }
}
