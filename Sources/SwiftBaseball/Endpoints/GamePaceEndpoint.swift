import Foundation

// MARK: - QueryBuilder factories

extension QueryBuilder where T == GamePace {
    static func teamGamePace(teamId: Int, season: Int, client: any APIClient) -> QueryBuilder<GamePace> {
        let endpoint = Endpoint(path: "gamePace", queryItems: [
            URLQueryItem(name: "teamIds", value: String(teamId)),
            URLQueryItem(name: "season", value: String(season))
        ])
        return QueryBuilder(endpoint: endpoint, client: client) { data in
            let response = try JSONDecoder.mlb.decode(MLBGamePaceResponse.self, from: data)
            guard let pace = MLBResponseConverters.teamGamePace(from: response) else {
                throw SwiftBaseballError.notFound("Game pace for team \(teamId), season \(season)")
            }
            return pace
        }
    }

    static func leagueGamePace(season: Int, client: any APIClient) -> QueryBuilder<GamePace> {
        let endpoint = Endpoint(path: "gamePace", queryItems: [
            URLQueryItem(name: "sportId", value: "1"),
            URLQueryItem(name: "season", value: String(season))
        ])
        return QueryBuilder(endpoint: endpoint, client: client) { data in
            let response = try JSONDecoder.mlb.decode(MLBGamePaceResponse.self, from: data)
            guard let pace = MLBResponseConverters.leagueGamePace(from: response) else {
                throw SwiftBaseballError.notFound("League game pace for season \(season)")
            }
            return pace
        }
    }
}
