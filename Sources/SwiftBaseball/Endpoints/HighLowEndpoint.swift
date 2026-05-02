import Foundation

// MARK: - Direction

/// Direction of the high/low query.
public enum HighLowDirection: String, Sendable {
    /// Highest single-game values.
    case high
    /// Lowest single-game values.
    case low
}

// MARK: - QueryBuilder factories

extension QueryBuilder where T == [HighLowSplit] {
    static func highLowPlayer(
        group: StatGroup,
        sortStat: LeaderStatCategory,
        season: Int,
        direction: HighLowDirection,
        client: any APIClient
    ) -> QueryBuilder<[HighLowSplit]> {
        highLow(
            path: "highLow/player",
            group: group,
            sortStat: sortStat,
            season: season,
            direction: direction,
            client: client
        )
    }

    static func highLowTeam(
        group: StatGroup,
        sortStat: LeaderStatCategory,
        season: Int,
        direction: HighLowDirection,
        client: any APIClient
    ) -> QueryBuilder<[HighLowSplit]> {
        highLow(
            path: "highLow/team",
            group: group,
            sortStat: sortStat,
            season: season,
            direction: direction,
            client: client
        )
    }

    private static func highLow(
        path: String,
        group: StatGroup,
        sortStat: LeaderStatCategory,
        season: Int,
        direction: HighLowDirection,
        client: any APIClient
    ) -> QueryBuilder<[HighLowSplit]> {
        let endpoint = Endpoint(path: path, queryItems: [
            URLQueryItem(name: "statGroup", value: group.apiValue),
            URLQueryItem(name: "season", value: String(season)),
            URLQueryItem(name: "sortStat", value: sortStat.rawValue),
            URLQueryItem(name: "highLow", value: direction.rawValue)
        ])
        return QueryBuilder(endpoint: endpoint, client: client) { data in
            let response = try JSONDecoder.mlb.decode(MLBHighLowResponse.self, from: data)
            return MLBResponseConverters.highLowSplits(from: response)
        }
    }
}
