import Foundation

// MARK: - QueryBuilder factories

extension QueryBuilder where T == [Transaction] {
    static func transactions(client: any APIClient) -> QueryBuilder<[Transaction]> {
        let endpoint = Endpoint(path: "transactions")
        return QueryBuilder(endpoint: endpoint, client: client) { data in
            let response = try JSONDecoder.mlb.decode(MLBTransactionsResponse.self, from: data)
            return MLBResponseConverters.transactions(from: response)
        }
    }
}
