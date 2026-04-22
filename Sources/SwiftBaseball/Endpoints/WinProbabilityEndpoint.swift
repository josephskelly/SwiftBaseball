import Foundation

// MARK: - QueryBuilder factories

extension QueryBuilder where T == [PlayWinProbability] {
    static func winProbability(gamePk: Int, client: any APIClient) -> QueryBuilder<[PlayWinProbability]> {
        let endpoint = Endpoint(path: "game/\(gamePk)/winProbability")
        return QueryBuilder(endpoint: endpoint, client: client) { data in
            let response = try JSONDecoder.mlb.decode([MLBWinProbabilityPlay].self, from: data)
            return MLBResponseConverters.winProbability(from: response)
        }
    }
}
