import Foundation

// MARK: - QueryBuilder factories

extension QueryBuilder where T == [Umpire] {
    static func umpires(date: String, client: any APIClient) -> QueryBuilder<[Umpire]> {
        let endpoint = Endpoint(path: "jobs/umpires", queryItems: [
            URLQueryItem(name: "date", value: date)
        ])
        return QueryBuilder(endpoint: endpoint, client: client) { data in
            let response = try JSONDecoder.mlb.decode(MLBUmpiresResponse.self, from: data)
            return response.roster.map(MLBResponseConverters.umpire)
        }
    }
}
