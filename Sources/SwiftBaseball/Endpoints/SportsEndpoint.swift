import Foundation

// MARK: - QueryBuilder factories

extension QueryBuilder where T == [SportCatalog] {
    static func sports(client: any APIClient) -> QueryBuilder<[SportCatalog]> {
        let endpoint = Endpoint(path: "sports")
        return QueryBuilder(endpoint: endpoint, client: client) { data in
            let response = try JSONDecoder.mlb.decode(MLBSportsResponse.self, from: data)
            return MLBResponseConverters.sports(from: response)
        }
    }
}
