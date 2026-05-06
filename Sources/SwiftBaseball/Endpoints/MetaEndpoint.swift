import Foundation

extension QueryBuilder {
    /// Generic factory for any MLB Stats API catalog endpoint that returns a top-level
    /// JSON array. Used internally by the ``SwiftBaseball/Meta`` namespace.
    static func metaCatalog<U: Decodable>(
        path: String,
        client: any APIClient
    ) -> QueryBuilder<[U]> where T == [U] {
        QueryBuilder(endpoint: Endpoint(path: path, queryItems: []), client: client) { data in
            try JSONDecoder.mlb.decode([U].self, from: data)
        }
    }
}
