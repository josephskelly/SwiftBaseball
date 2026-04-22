import Foundation

// MARK: - QueryBuilder factory

extension QueryBuilder where T == [DraftPick] {
    static func draft(year: Int, client: any APIClient) -> QueryBuilder<[DraftPick]> {
        let endpoint = Endpoint(path: "draft/\(year)")
        return QueryBuilder(endpoint: endpoint, client: client) { data in
            let response = try JSONDecoder.mlb.decode(MLBDraftResponse.self, from: data)
            return MLBResponseConverters.draftPicks(from: response, year: year)
        }
    }
}
