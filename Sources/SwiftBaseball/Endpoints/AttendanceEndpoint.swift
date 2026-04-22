import Foundation

// MARK: - QueryBuilder factories

extension QueryBuilder where T == [TeamAttendance] {
    static func attendance(teamId: Int, season: Int, client: any APIClient) -> QueryBuilder<[TeamAttendance]> {
        let endpoint = Endpoint(path: "attendance", queryItems: [
            URLQueryItem(name: "teamId", value: String(teamId)),
            URLQueryItem(name: "season", value: String(season))
        ])
        return QueryBuilder(endpoint: endpoint, client: client) { data in
            let response = try JSONDecoder.mlb.decode(MLBAttendanceResponse.self, from: data)
            return MLBResponseConverters.attendance(from: response)
        }
    }
}
