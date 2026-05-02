import Foundation

extension QueryBuilder where T == [DraftProspect] {
    /// Creates a query builder for the full prospect pool of a draft year.
    ///
    /// `draft/prospects/{year}` returns every entered prospect — selected and unselected.
    /// Lists from earlier drafts may exceed several thousand rows, so consider iterating
    /// the result rather than holding all entries in memory at once.
    static func draftProspects(year: Int, client: any APIClient) -> QueryBuilder<[DraftProspect]> {
        let endpoint = Endpoint(path: "draft/prospects/\(year)", queryItems: [])
        return QueryBuilder(endpoint: endpoint, client: client) { data in
            let response = try JSONDecoder.mlb.decode(MLBDraftProspectsResponse.self, from: data)
            return MLBResponseConverters.draftProspects(from: response)
        }
    }
}

extension QueryBuilder where T == DraftLatest {
    /// Creates a query builder for the live in-progress snapshot of a draft.
    ///
    /// `draft/{year}/latest` returns the most recent pick, the next picks on the clock,
    /// and the overall pick number. Outside the active draft window, `pick` reflects
    /// the final selection of the most recent draft and `nextUp` is empty.
    static func draftLatest(year: Int, client: any APIClient) -> QueryBuilder<DraftLatest> {
        let endpoint = Endpoint(path: "draft/\(year)/latest", queryItems: [])
        return QueryBuilder(endpoint: endpoint, client: client) { data in
            let response = try JSONDecoder.mlb.decode(MLBDraftLatestResponse.self, from: data)
            return MLBResponseConverters.draftLatest(from: response)
        }
    }
}
