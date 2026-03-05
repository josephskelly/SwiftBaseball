import Foundation

extension QueryBuilder where T == [LeaderCategory] {
    static func leaders(_ category: LeaderStatCategory, client: any APIClient) -> QueryBuilder<[LeaderCategory]> {
        let endpoint = Endpoint(path: "stats/leaders", queryItems: [
            URLQueryItem(name: "leaderCategories", value: category.rawValue),
            URLQueryItem(name: "sportId", value: "1")
        ])
        return QueryBuilder(endpoint: endpoint, client: client) { data in
            let response = try JSONDecoder.mlb.decode(MLBLeadersResponse.self, from: data)
            return MLBResponseConverters.leaderEntries(from: response)
        }
    }
}
