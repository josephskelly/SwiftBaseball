import Foundation

// MARK: - QueryBuilder factories

extension QueryBuilder where T == [DivisionCatalog] {
    static func divisions(sportId: Int?, client: any APIClient) -> QueryBuilder<[DivisionCatalog]> {
        var queryItems: [URLQueryItem] = []
        if let sportId {
            queryItems.append(URLQueryItem(name: "sportId", value: String(sportId)))
        }
        let endpoint = Endpoint(path: "divisions", queryItems: queryItems)
        return QueryBuilder(endpoint: endpoint, client: client) { data in
            let response = try JSONDecoder.mlb.decode(MLBDivisionsResponse.self, from: data)
            return MLBResponseConverters.divisions(from: response)
        }
    }
}
