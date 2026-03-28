import Foundation

// MARK: - Award recipients

extension QueryBuilder where T == [AwardRecipient] {
    /// Builds a query for recipients of a specific MLB award.
    ///
    /// Use `.season(_:)` to filter to a single year.
    static func awardRecipients(awardId: String, client: any APIClient) -> QueryBuilder<[AwardRecipient]> {
        let endpoint = Endpoint(path: "awards/\(awardId)/recipients")
        return QueryBuilder(endpoint: endpoint, client: client) { data in
            let response = try JSONDecoder.mlb.decode(MLBAwardRecipientsResponse.self, from: data)
            return MLBResponseConverters.awardRecipients(from: response)
        }
    }
}

// MARK: - Awards list

extension QueryBuilder where T == [Award] {
    /// Builds a query for all defined MLB awards.
    static func allAwards(client: any APIClient) -> QueryBuilder<[Award]> {
        let endpoint = Endpoint(path: "awards")
        return QueryBuilder(endpoint: endpoint, client: client) { data in
            let response = try JSONDecoder.mlb.decode(MLBAwardsListResponse.self, from: data)
            return MLBResponseConverters.awards(from: response)
        }
    }
}
