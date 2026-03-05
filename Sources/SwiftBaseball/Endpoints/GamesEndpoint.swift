import Foundation

extension QueryBuilder where T == Boxscore {
    static func boxscore(gamePk: Int, client: any APIClient) -> QueryBuilder<Boxscore> {
        let endpoint = Endpoint(path: "game/\(gamePk)/boxscore")
        return QueryBuilder(endpoint: endpoint, client: client) { data in
            try JSONDecoder.mlb.decode(Boxscore.self, from: data)
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
