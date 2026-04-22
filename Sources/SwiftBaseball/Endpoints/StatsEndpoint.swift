import Foundation

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

    static func playerProjectedStats(id: Int, client: any APIClient) -> QueryBuilder<[PlayerSeasonStats]> {
        let endpoint = Endpoint(path: "people/\(id)/stats", queryItems: [
            URLQueryItem(name: "stats", value: "projected")
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
            URLQueryItem(name: "sitCodes", value: "vl,vr")
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
            URLQueryItem(name: "group", value: "hitting")
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
            URLQueryItem(name: "sitCodes", value: "vl,vr")
        ])
        let ref = PlayerReference(id: id, fullName: "")
        return QueryBuilder(endpoint: endpoint, client: client) { data in
            let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: data)
            return MLBResponseConverters.pitcherPlatoonStats(from: response, playerRef: ref)
        }
    }
}

// MARK: - Career platoon split factories

extension QueryBuilder where T == PlayerCareerPlatoonStats {
    /// Builds a request for career-aggregated platoon batting splits using `stats=careerStatSplits`.
    static func playerCareerPlatoonStats(id: Int, client: any APIClient) -> QueryBuilder<PlayerCareerPlatoonStats> {
        let endpoint = Endpoint(path: "people/\(id)/stats", queryItems: [
            URLQueryItem(name: "stats", value: "careerStatSplits"),
            URLQueryItem(name: "group", value: "hitting"),
            URLQueryItem(name: "sitCodes", value: "vl,vr")
        ])
        let ref = PlayerReference(id: id, fullName: "")
        return QueryBuilder(endpoint: endpoint, client: client) { data in
            let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: data)
            let p = MLBResponseConverters.playerPlatoonStats(from: response, playerRef: ref)
            return PlayerCareerPlatoonStats(vsLeft: p.vsLeft, vsRight: p.vsRight)
        }
    }
}

extension QueryBuilder where T == PitcherCareerPlatoonStats {
    /// Builds a request for career-aggregated platoon pitching splits using `stats=careerStatSplits`.
    static func pitcherCareerPlatoonStats(id: Int, client: any APIClient) -> QueryBuilder<PitcherCareerPlatoonStats> {
        let endpoint = Endpoint(path: "people/\(id)/stats", queryItems: [
            URLQueryItem(name: "stats", value: "careerStatSplits"),
            URLQueryItem(name: "group", value: "pitching"),
            URLQueryItem(name: "sitCodes", value: "vl,vr")
        ])
        let ref = PlayerReference(id: id, fullName: "")
        return QueryBuilder(endpoint: endpoint, client: client) { data in
            let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: data)
            let p = MLBResponseConverters.pitcherPlatoonStats(from: response, playerRef: ref)
            return PitcherCareerPlatoonStats(vsLeft: p.vsLeft, vsRight: p.vsRight)
        }
    }
}

// MARK: - Team bulk stat factories

extension QueryBuilder where T == [PlayerSeasonStats] {
    /// Fetches sabermetric stats (wOBA, wRC+, WAR) for all players on a team via the
    /// top-level `/stats` endpoint with `teamId` — one call replaces N per-player calls.
    static func teamSabermetrics(teamId: Int, client: any APIClient) -> QueryBuilder<[PlayerSeasonStats]> {
        let endpoint = Endpoint(path: "stats", queryItems: [
            URLQueryItem(name: "stats", value: "sabermetrics"),
            URLQueryItem(name: "group", value: "hitting"),
            URLQueryItem(name: "teamId", value: String(teamId)),
            URLQueryItem(name: "playerPool", value: "All")
        ])
        let stub = PlayerReference(id: 0, fullName: "")
        return QueryBuilder(endpoint: endpoint, client: client) { data in
            let response = try JSONDecoder.mlb.decode(MLBSabermetricResponse.self, from: data)
            return MLBResponseConverters.playerSabermetrics(from: response, playerRef: stub)
        }
    }

    /// Fetches season stats for all players on a team by stat group via the top-level
    /// `/stats` endpoint with `teamId` — one call replaces N per-player calls.
    static func teamStats(teamId: Int, group: StatGroup, client: any APIClient) -> QueryBuilder<[PlayerSeasonStats]> {
        let endpoint = Endpoint(path: "stats", queryItems: [
            URLQueryItem(name: "stats", value: "season"),
            URLQueryItem(name: "group", value: group.apiValue),
            URLQueryItem(name: "teamId", value: String(teamId)),
            URLQueryItem(name: "playerPool", value: "All")
        ])
        let stub = PlayerReference(id: 0, fullName: "")
        return QueryBuilder(endpoint: endpoint, client: client) { data in
            let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: data)
            return MLBResponseConverters.playerSeasonStats(from: response, playerRef: stub)
        }
    }
}

// MARK: - Home/Away split factories

extension QueryBuilder where T == PlayerHomeAwaySplits {
    static func playerHomeAwaySplits(id: Int, client: any APIClient) -> QueryBuilder<PlayerHomeAwaySplits> {
        let endpoint = Endpoint(path: "people/\(id)/stats", queryItems: [
            URLQueryItem(name: "stats", value: "statSplits"),
            URLQueryItem(name: "group", value: "hitting"),
            URLQueryItem(name: "sitCodes", value: "h,a")
        ])
        let ref = PlayerReference(id: id, fullName: "")
        return QueryBuilder(endpoint: endpoint, client: client) { data in
            let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: data)
            return MLBResponseConverters.playerHomeAwaySplits(from: response, playerRef: ref)
        }
    }
}

extension QueryBuilder where T == PitcherHomeAwaySplits {
    static func pitcherHomeAwaySplits(id: Int, client: any APIClient) -> QueryBuilder<PitcherHomeAwaySplits> {
        let endpoint = Endpoint(path: "people/\(id)/stats", queryItems: [
            URLQueryItem(name: "stats", value: "statSplits"),
            URLQueryItem(name: "group", value: "pitching"),
            URLQueryItem(name: "sitCodes", value: "h,a")
        ])
        let ref = PlayerReference(id: id, fullName: "")
        return QueryBuilder(endpoint: endpoint, client: client) { data in
            let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: data)
            return MLBResponseConverters.pitcherHomeAwaySplits(from: response, playerRef: ref)
        }
    }
}

// MARK: - Day/Night split factories

extension QueryBuilder where T == PlayerDayNightSplits {
    static func playerDayNightSplits(id: Int, client: any APIClient) -> QueryBuilder<PlayerDayNightSplits> {
        let endpoint = Endpoint(path: "people/\(id)/stats", queryItems: [
            URLQueryItem(name: "stats", value: "statSplits"),
            URLQueryItem(name: "group", value: "hitting"),
            URLQueryItem(name: "sitCodes", value: "d,n")
        ])
        let ref = PlayerReference(id: id, fullName: "")
        return QueryBuilder(endpoint: endpoint, client: client) { data in
            let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: data)
            return MLBResponseConverters.playerDayNightSplits(from: response, playerRef: ref)
        }
    }
}

extension QueryBuilder where T == PitcherDayNightSplits {
    static func pitcherDayNightSplits(id: Int, client: any APIClient) -> QueryBuilder<PitcherDayNightSplits> {
        let endpoint = Endpoint(path: "people/\(id)/stats", queryItems: [
            URLQueryItem(name: "stats", value: "statSplits"),
            URLQueryItem(name: "group", value: "pitching"),
            URLQueryItem(name: "sitCodes", value: "d,n")
        ])
        let ref = PlayerReference(id: id, fullName: "")
        return QueryBuilder(endpoint: endpoint, client: client) { data in
            let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: data)
            return MLBResponseConverters.pitcherDayNightSplits(from: response, playerRef: ref)
        }
    }
}

extension QueryBuilder where T == PlayerMonthlySplits {
    static func playerMonthlySplits(id: Int, client: any APIClient) -> QueryBuilder<PlayerMonthlySplits> {
        let endpoint = Endpoint(path: "people/\(id)/stats", queryItems: [
            URLQueryItem(name: "stats", value: "statSplits"),
            URLQueryItem(name: "group", value: "hitting"),
            URLQueryItem(name: "sitCodes", value: "m3,m4,m5,m6,m7,m8,m9,m10")
        ])
        let ref = PlayerReference(id: id, fullName: "")
        return QueryBuilder(endpoint: endpoint, client: client) { data in
            let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: data)
            return MLBResponseConverters.playerMonthlySplits(from: response, playerRef: ref)
        }
    }
}

extension QueryBuilder where T == PitcherMonthlySplits {
    static func pitcherMonthlySplits(id: Int, client: any APIClient) -> QueryBuilder<PitcherMonthlySplits> {
        let endpoint = Endpoint(path: "people/\(id)/stats", queryItems: [
            URLQueryItem(name: "stats", value: "statSplits"),
            URLQueryItem(name: "group", value: "pitching"),
            URLQueryItem(name: "sitCodes", value: "m3,m4,m5,m6,m7,m8,m9,m10")
        ])
        let ref = PlayerReference(id: id, fullName: "")
        return QueryBuilder(endpoint: endpoint, client: client) { data in
            let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: data)
            return MLBResponseConverters.pitcherMonthlySplits(from: response, playerRef: ref)
        }
    }
}

extension QueryBuilder where T == PlayerRunnersOnSplits {
    static func playerRunnersOnSplits(id: Int, client: any APIClient) -> QueryBuilder<PlayerRunnersOnSplits> {
        let endpoint = Endpoint(path: "people/\(id)/stats", queryItems: [
            URLQueryItem(name: "stats", value: "statSplits"),
            URLQueryItem(name: "group", value: "hitting"),
            URLQueryItem(name: "sitCodes", value: "ne,ro,ri,sf")
        ])
        let ref = PlayerReference(id: id, fullName: "")
        return QueryBuilder(endpoint: endpoint, client: client) { data in
            let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: data)
            return MLBResponseConverters.playerRunnersOnSplits(from: response, playerRef: ref)
        }
    }
}

extension QueryBuilder where T == PitcherRunnersOnSplits {
    static func pitcherRunnersOnSplits(id: Int, client: any APIClient) -> QueryBuilder<PitcherRunnersOnSplits> {
        let endpoint = Endpoint(path: "people/\(id)/stats", queryItems: [
            URLQueryItem(name: "stats", value: "statSplits"),
            URLQueryItem(name: "group", value: "pitching"),
            URLQueryItem(name: "sitCodes", value: "ne,ro,ri,sf")
        ])
        let ref = PlayerReference(id: id, fullName: "")
        return QueryBuilder(endpoint: endpoint, client: client) { data in
            let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: data)
            return MLBResponseConverters.pitcherRunnersOnSplits(from: response, playerRef: ref)
        }
    }
}

extension QueryBuilder where T == PlayerLeverageSplits {
    static func playerLeverageSplits(id: Int, client: any APIClient) -> QueryBuilder<PlayerLeverageSplits> {
        let endpoint = Endpoint(path: "people/\(id)/stats", queryItems: [
            URLQueryItem(name: "stats", value: "statSplits"),
            URLQueryItem(name: "group", value: "hitting"),
            URLQueryItem(name: "sitCodes", value: "le,lm,lh")
        ])
        let ref = PlayerReference(id: id, fullName: "")
        return QueryBuilder(endpoint: endpoint, client: client) { data in
            let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: data)
            return MLBResponseConverters.playerLeverageSplits(from: response, playerRef: ref)
        }
    }
}

extension QueryBuilder where T == PitcherLeverageSplits {
    static func pitcherLeverageSplits(id: Int, client: any APIClient) -> QueryBuilder<PitcherLeverageSplits> {
        let endpoint = Endpoint(path: "people/\(id)/stats", queryItems: [
            URLQueryItem(name: "stats", value: "statSplits"),
            URLQueryItem(name: "group", value: "pitching"),
            URLQueryItem(name: "sitCodes", value: "le,lm,lh")
        ])
        let ref = PlayerReference(id: id, fullName: "")
        return QueryBuilder(endpoint: endpoint, client: client) { data in
            let response = try JSONDecoder.mlb.decode(MLBPlayerStatsResponse.self, from: data)
            return MLBResponseConverters.pitcherLeverageSplits(from: response, playerRef: ref)
        }
    }
}
