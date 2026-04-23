import Foundation

// MARK: - QueryBuilder factories

extension QueryBuilder where T == [LeagueCatalog] {
    static func leagues(sportId: Int?, client: any APIClient) -> QueryBuilder<[LeagueCatalog]> {
        var queryItems: [URLQueryItem] = []
        if let sportId {
            queryItems.append(URLQueryItem(name: "sportId", value: String(sportId)))
        }
        let endpoint = Endpoint(path: "leagues", queryItems: queryItems)
        return QueryBuilder(endpoint: endpoint, client: client) { data in
            let response = try JSONDecoder.mlb.decode(MLBLeaguesResponse.self, from: data)
            return MLBResponseConverters.leagues(from: response)
        }
    }
}
