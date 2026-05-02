import Foundation

extension QueryBuilder where T == [OfficialScorer] {
    /// Creates a query builder for the official-scorer roster active on the given date.
    static func officialScorers(date: String, client: any APIClient) -> QueryBuilder<[OfficialScorer]> {
        let endpoint = Endpoint(path: "jobs/officialScorers", queryItems: [
            URLQueryItem(name: "date", value: date)
        ])
        return QueryBuilder(endpoint: endpoint, client: client) { data in
            let response = try JSONDecoder.mlb.decode(MLBUmpiresResponse.self, from: data)
            return response.roster.map(MLBResponseConverters.officialScorer)
        }
    }
}
