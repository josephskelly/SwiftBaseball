import Foundation

// MARK: - QueryBuilder factories

extension QueryBuilder where T == [TeamLeaderCategory] {
    static func teamLeaders(
        teamId: Int,
        category: LeaderStatCategory,
        client: any APIClient
    ) -> QueryBuilder<[TeamLeaderCategory]> {
        let endpoint = Endpoint(path: "teams/\(teamId)/leaders", queryItems: [
            URLQueryItem(name: "leaderCategories", value: category.rawValue)
        ])
        return QueryBuilder(endpoint: endpoint, client: client) { data in
            let response = try JSONDecoder.mlb.decode(MLBTeamLeadersResponse.self, from: data)
            return MLBResponseConverters.teamLeaders(from: response)
        }
    }
}
