import Foundation

// MARK: - QueryBuilder factories

extension QueryBuilder where T == PlayByPlay {
    static func playByPlay(gamePk: Int, client: any APIClient) -> QueryBuilder<PlayByPlay> {
        let endpoint = Endpoint(path: "game/\(gamePk)/playByPlay")
        return QueryBuilder(endpoint: endpoint, client: client) { data in
            let response = try JSONDecoder.mlb.decode(MLBPlayByPlayResponse.self, from: data)
            return MLBResponseConverters.playByPlay(from: response)
        }
    }
}
