import Foundation

// MARK: - Query types

/// Query type for player statistics endpoints.
public enum StatsQuery: Sendable {
    case batting
    case pitching
    case fielding
}

// MARK: - QueryBuilder factories

extension QueryBuilder where T == [PlayerSeasonStats] {
    static func playerStats(id: Int, client: any APIClient) -> QueryBuilder<[PlayerSeasonStats]> {
        let endpoint = Endpoint(path: "people/\(id)/stats", queryItems: [
            URLQueryItem(name: "stats", value: "season")
        ])
        let ref = PlayerReference(id: id, fullName: "")
        return QueryBuilder(endpoint: endpoint, client: client) { data in
            let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: data)
            return MLBResponseConverters.playerSeasonStats(from: response, playerRef: ref)
        }
    }

    static func playerCareerStats(id: Int, client: any APIClient) -> QueryBuilder<[PlayerSeasonStats]> {
        let endpoint = Endpoint(path: "people/\(id)/stats", queryItems: [
            URLQueryItem(name: "stats", value: "career")
        ])
        let ref = PlayerReference(id: id, fullName: "")
        return QueryBuilder(endpoint: endpoint, client: client) { data in
            let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: data)
            return MLBResponseConverters.playerSeasonStats(from: response, playerRef: ref)
        }
    }

    static func playerYearByYear(id: Int, client: any APIClient) -> QueryBuilder<[PlayerSeasonStats]> {
        let endpoint = Endpoint(path: "people/\(id)/stats", queryItems: [
            URLQueryItem(name: "stats", value: "yearByYear")
        ])
        let ref = PlayerReference(id: id, fullName: "")
        return QueryBuilder(endpoint: endpoint, client: client) { data in
            let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: data)
            return MLBResponseConverters.playerSeasonStats(from: response, playerRef: ref)
        }
    }
}

extension QueryBuilder where T == PlayerPlatoonStats {
    static func playerPlatoonStats(id: Int, client: any APIClient) -> QueryBuilder<PlayerPlatoonStats> {
        let endpoint = Endpoint(path: "people/\(id)/stats", queryItems: [
            URLQueryItem(name: "stats", value: "statSplits"),
            URLQueryItem(name: "group", value: "hitting"),
            URLQueryItem(name: "sitCodes", value: "vl,vr"),
        ])
        let ref = PlayerReference(id: id, fullName: "")
        return QueryBuilder(endpoint: endpoint, client: client) { data in
            let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: data)
            return MLBResponseConverters.playerPlatoonStats(from: response, playerRef: ref)
        }
    }
}

extension QueryBuilder where T == [PlayerSeasonStats] {
    static func playerSabermetrics(id: Int, client: any APIClient) -> QueryBuilder<[PlayerSeasonStats]> {
        let endpoint = Endpoint(path: "people/\(id)/stats", queryItems: [
            URLQueryItem(name: "stats", value: "sabermetrics"),
            URLQueryItem(name: "group", value: "hitting"),
        ])
        let ref = PlayerReference(id: id, fullName: "")
        return QueryBuilder(endpoint: endpoint, client: client) { data in
            let response = try JSONDecoder.mlb.decode(MLBSabermetricResponse.self, from: data)
            return MLBResponseConverters.playerSabermetrics(from: response, playerRef: ref)
        }
    }
}

extension QueryBuilder where T == PitcherPlatoonStats {
    static func pitcherPlatoonStats(id: Int, client: any APIClient) -> QueryBuilder<PitcherPlatoonStats> {
        let endpoint = Endpoint(path: "people/\(id)/stats", queryItems: [
            URLQueryItem(name: "stats", value: "statSplits"),
            URLQueryItem(name: "group", value: "pitching"),
            URLQueryItem(name: "sitCodes", value: "vl,vr"),
        ])
        let ref = PlayerReference(id: id, fullName: "")
        return QueryBuilder(endpoint: endpoint, client: client) { data in
            let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: data)
            return MLBResponseConverters.pitcherPlatoonStats(from: response, playerRef: ref)
        }
    }
}
