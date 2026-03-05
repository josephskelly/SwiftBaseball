import Foundation

extension QueryBuilder where T == Boxscore {
    static func boxscore(gamePk: Int, client: any APIClient) -> QueryBuilder<Boxscore> {
        let endpoint = Endpoint(path: "game/\(gamePk)/boxscore")
        return QueryBuilder(endpoint: endpoint, client: client) { data in
            let response = try JSONDecoder.mlb.decode(MLBBoxscoreResponse.self, from: data)
            return MLBResponseConverters.boxscore(from: response)
        }
    }
}

extension QueryBuilder where T == Linescore {
    static func linescore(gamePk: Int, client: any APIClient) -> QueryBuilder<Linescore> {
        let endpoint = Endpoint(path: "game/\(gamePk)/linescore")
        return QueryBuilder(endpoint: endpoint, client: client) { data in
            try JSONDecoder.mlb.decode(Linescore.self, from: data)
        }
    }
}
