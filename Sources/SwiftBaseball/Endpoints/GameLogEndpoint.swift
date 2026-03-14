import Foundation

// MARK: - QueryBuilder factories

extension QueryBuilder where T == [GameLogEntry] {
    static func gameLog(playerId: Int, client: any APIClient) -> QueryBuilder<[GameLogEntry]> {
        let endpoint = Endpoint(path: "people/\(playerId)/stats", queryItems: [
            URLQueryItem(name: "stats", value: "gameLog")
        ])
        return QueryBuilder(endpoint: endpoint, client: client) { data in
            let response = try JSONDecoder.mlb.decode(MLBGameLogResponse.self, from: data)
            return MLBResponseConverters.gameLogEntries(from: response)
        }
    }
}
