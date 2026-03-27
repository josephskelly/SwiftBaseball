import Foundation

// MARK: - All venues

extension QueryBuilder where T == [Venue] {
    static func venues(client: any APIClient) -> QueryBuilder<[Venue]> {
        let endpoint = Endpoint(path: "venues", queryItems: [
            URLQueryItem(name: "hydrate", value: "fieldInfo,location"),
            URLQueryItem(name: "activeStatus", value: "Both"),
        ])
        return QueryBuilder(endpoint: endpoint, client: client) { data in
            let response = try JSONDecoder.mlb.decode(MLBVenuesResponse.self, from: data)
            return MLBResponseConverters.venues(from: response)
        }
    }
}

// MARK: - Single venue

extension QueryBuilder where T == Venue {
    static func venue(id: Int, client: any APIClient) -> QueryBuilder<Venue> {
        let endpoint = Endpoint(
            path: "venues/\(id)",
            queryItems: [URLQueryItem(name: "hydrate", value: "fieldInfo,location")]
        )
        return QueryBuilder(endpoint: endpoint, client: client) { data in
            let response = try JSONDecoder.mlb.decode(MLBVenuesResponse.self, from: data)
            guard let raw = response.venues.first else {
                throw SwiftBaseballError.notFound("Venue \(id) not found")
            }
            return MLBResponseConverters.venue(from: raw)
        }
    }
}
