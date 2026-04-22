import Foundation

// MARK: - QueryBuilder factories

extension QueryBuilder where T == [TeamStaff] {
    static func teamCoaches(teamId: Int, client: any APIClient) -> QueryBuilder<[TeamStaff]> {
        let endpoint = Endpoint(path: "teams/\(teamId)/coaches")
        return QueryBuilder(endpoint: endpoint, client: client) { data in
            let response = try JSONDecoder.mlb.decode(MLBCoachesResponse.self, from: data)
            return response.roster.map(MLBResponseConverters.teamStaff)
        }
    }
}

extension QueryBuilder where T == [Player] {
    static func teamAlumni(teamId: Int, season: Int, client: any APIClient) -> QueryBuilder<[Player]> {
        let endpoint = Endpoint(path: "teams/\(teamId)/alumni", queryItems: [
            URLQueryItem(name: "season", value: String(season))
        ])
        return QueryBuilder(endpoint: endpoint, client: client) { data in
            let response = try JSONDecoder.mlb.decode(MLBPeopleResponse.self, from: data)
            return response.people.map(MLBResponseConverters.player)
        }
    }
}
