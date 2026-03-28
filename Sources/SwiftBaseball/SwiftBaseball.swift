import Foundation

/// Top-level namespace and fluent API entry point.
///
/// ```swift
/// let players = try await SwiftBaseball.players(.search("Ohtani")).fetch()
/// let judge   = try await SwiftBaseball.player(id: 592450).fetch()
/// let games   = try await SwiftBaseball.schedule(.date("2024-07-04")).fetch()
/// ```
public enum SwiftBaseball {

    // MARK: - Configuration

    // Class wrapper allows safe mutation from configure() before concurrent use.
    private final class State: @unchecked Sendable {
        var client: any APIClient = URLSessionAPIClient()
        var statcastClient: StatcastAPIClient = StatcastAPIClient()
        var configuration: Configuration = .default
    }
    private static let _state = State()

    public static func configure(_ configuration: Configuration) {
        _state.configuration = configuration
        let base = URLSessionAPIClient(configuration: configuration)
        if configuration.cacheEnabled {
            let cache = CacheManager(defaultTTL: configuration.cacheTTL)
            _state.client = CachingAPIClient(wrapped: base, cache: cache, ttl: configuration.cacheTTL)
        } else {
            _state.client = base
        }
        _state.statcastClient = StatcastAPIClient(configuration: configuration)
    }

    private static var client: any APIClient { _state.client }
    private static var statcastClient: StatcastAPIClient { _state.statcastClient }

    // MARK: - Players

    /// Search players by name.
    ///
    ///     let results = try await SwiftBaseball.players(.search("Ohtani")).fetch()
    public static func players(_ query: PlayerQuery) -> QueryBuilder<[Player]> {
        .players(query, client: client)
    }

    /// Fetch a single player by MLB ID.
    ///
    ///     let judge = try await SwiftBaseball.player(id: 592450).fetch()
    public static func player(id: Int) -> QueryBuilder<Player> {
        .singlePlayer(id: id, client: client)
    }

    // MARK: - Teams

    /// Query MLB teams. Chain `.sport(_:)` to list minor league teams at a given level.
    ///
    ///     let mlbTeams   = try await SwiftBaseball.teams(.all(season: 2024)).fetch()
    ///     let aaaTeams   = try await SwiftBaseball.teams(.all(season: 2024)).sport(.tripleA).fetch()
    ///     let doubleATeams = try await SwiftBaseball.teams(.all(season: 2024)).sport(.doubleA).fetch()
    public static func teams(_ query: TeamQuery) -> QueryBuilder<[Team]> {
        .teams(query, client: client)
    }

    /// Fetch a single team by MLB or minor league team ID.
    ///
    ///     let yankees    = try await SwiftBaseball.team(id: 147).fetch()
    ///     let railRiders = try await SwiftBaseball.team(id: 531).fetch()  // SWB AAA affiliate
    public static func team(id: Int) -> QueryBuilder<Team> {
        .singleTeam(id: id, client: client)
    }

    /// Fetch all affiliate teams for an MLB organization.
    ///
    /// Returns the MLB club plus every affiliated minor league team. Each
    /// ``Team`` in the result carries ``Team/parentOrgId``, ``Team/parentOrgName``,
    /// and ``Team/sportName`` so you can identify the level without extra calls.
    /// Use the returned team IDs directly with ``roster(teamId:season:rosterType:)``.
    ///
    ///     let affiliates = try await SwiftBaseball.affiliates(teamId: 147, season: 2024).fetch()
    ///     let aaaAffiliate = affiliates.first { $0.sportName == "Triple-A" }
    ///     let aaaRoster = try await SwiftBaseball.roster(teamId: aaaAffiliate!.id, season: 2024).fetch()
    ///
    /// - SeeAlso: ``Team/sportName``, ``Team/parentOrgId``, ``roster(teamId:season:rosterType:)``
    public static func affiliates(teamId: Int, season: Int) -> QueryBuilder<[Team]> {
        .affiliates(teamId: teamId, season: season, client: client)
    }

    /// Fetch a team's roster.
    ///
    /// Works for both MLB and minor league team IDs. The default
    /// ``RosterType/active`` returns the current active roster.
    /// For minor league teams, use ``RosterType/fullSeason`` to get every
    /// player who appeared on the team during the season.
    ///
    ///     // MLB active 26-man
    ///     let roster = try await SwiftBaseball.roster(teamId: 147, season: 2024).fetch()
    ///     // Minor league full-season roster
    ///     let mibRoster = try await SwiftBaseball.roster(teamId: 531, season: 2024, rosterType: .fullSeason).fetch()
    ///     // Spring training 40-man
    ///     let spring = try await SwiftBaseball.roster(teamId: 147, season: 2025, rosterType: .fortyMan).fetch()
    public static func roster(
        teamId: Int,
        season: Int,
        rosterType: RosterType = .active
    ) -> QueryBuilder<[RosterEntry]> {
        .roster(teamId: teamId, season: season, rosterType: rosterType, client: client)
    }

    // MARK: - Schedule

    /// Query game schedule.
    ///
    ///     let games  = try await SwiftBaseball.schedule(.date("2024-07-04")).fetch()
    ///     let season = try await SwiftBaseball.schedule(.season(2024)).teamId(147).fetch()
    public static func schedule(_ query: ScheduleQuery) -> QueryBuilder<[ScheduleEntry]> {
        .schedule(query, client: client)
    }

    // MARK: - Games

    /// Fetch a game's box score.
    public static func boxscore(gamePk: Int) -> QueryBuilder<Boxscore> {
        .boxscore(gamePk: gamePk, client: client)
    }

    /// Fetch play-by-play data for a game.
    ///
    ///     let pbp = try await SwiftBaseball.playByPlay(gamePk: 745612).fetch()
    public static func playByPlay(gamePk: Int) -> QueryBuilder<PlayByPlay> {
        .playByPlay(gamePk: gamePk, client: client)
    }

    /// Fetch a game's line score.
    public static func linescore(gamePk: Int) -> QueryBuilder<Linescore> {
        .linescore(gamePk: gamePk, client: client)
    }

    /// Fetch highlight videos and condensed game clips for a completed game.
    ///
    ///     let content = try await SwiftBaseball.gameHighlights(gamePk: 745612).fetch()
    ///     for clip in content.highlights {
    ///         print(clip.title ?? "", clip.duration ?? "")
    ///     }
    ///     // Access the best playback URL:
    ///     let url = content.highlights.first?.playbacks.first?.url
    public static func gameHighlights(gamePk: Int) -> QueryBuilder<GameHighlights> {
        .gameHighlights(gamePk: gamePk, client: client)
    }

    // MARK: - Game Log

    /// Fetch per-game stat lines for a player.
    ///
    ///     let log = try await SwiftBaseball.gameLog(playerId: 660271).season(2024).group(.batting).fetch()
    public static func gameLog(playerId: Int) -> QueryBuilder<[GameLogEntry]> {
        .gameLog(playerId: playerId, client: client)
    }

    // MARK: - Transactions

    /// Fetch MLB transactions (trades, signings, roster moves).
    ///
    ///     let trades = try await SwiftBaseball.transactions()
    ///         .dateRange(start: "2024-07-01", end: "2024-07-31")
    ///         .fetch()
    public static func transactions() -> QueryBuilder<[Transaction]> {
        .transactions(client: client)
    }

    // MARK: - Stats

    /// Fetch season stats for a player.
    ///
    /// Chain `.group(_:)` to scope to batting, pitching, or fielding. Chain
    /// `.sport(_:)` to fetch stats from a minor league level instead of MLB.
    ///
    ///     // MLB 2024 batting stats
    ///     let stats = try await SwiftBaseball.playerStats(id: 660271).season(2024).group(.batting).fetch()
    ///     // Triple-A 2024 batting stats
    ///     let aaaStats = try await SwiftBaseball.playerStats(id: 605141)
    ///         .season(2024).group(.batting).sport(.tripleA).fetch()
    ///
    /// The returned ``PlayerSeasonStats`` carries ``PlayerSeasonStats/sport`` and
    /// ``PlayerSeasonStats/league`` when the response includes them (minor league
    /// queries always do).
    public static func playerStats(id: Int) -> QueryBuilder<[PlayerSeasonStats]> {
        .playerStats(id: id, client: client)
    }

    /// Fetch career (lifetime) stats for a player.
    ///
    /// Returns a single ``PlayerSeasonStats`` entry per requested group with
    /// cumulative totals. Chain `.sport(_:)` to scope to a minor league level.
    /// The `season` property on returned entries will be empty (`""`).
    ///
    ///     let career    = try await SwiftBaseball.playerCareerStats(id: 660271).group(.batting).fetch()
    ///     let aaaCareer = try await SwiftBaseball.playerCareerStats(id: 605141).group(.batting).sport(.tripleA).fetch()
    public static func playerCareerStats(id: Int) -> QueryBuilder<[PlayerSeasonStats]> {
        .playerCareerStats(id: id, client: client)
    }

    /// Fetch year-by-year stats for a player.
    ///
    /// Returns one ``PlayerSeasonStats`` entry per season. Chain `.sport(_:)` to
    /// scope to a minor league level; each returned entry's
    /// ``PlayerSeasonStats/sport`` and ``PlayerSeasonStats/league`` identify the
    /// level and league for that season.
    ///
    ///     let history    = try await SwiftBaseball.playerYearByYear(id: 660271).group(.batting).fetch()
    ///     let aaaHistory = try await SwiftBaseball.playerYearByYear(id: 656185).group(.batting).sport(.tripleA).fetch()
    public static func playerYearByYear(id: Int) -> QueryBuilder<[PlayerSeasonStats]> {
        .playerYearByYear(id: id, client: client)
    }

    /// Fetch full-season projected stats for an active player.
    ///
    /// Returns projected totals as a ``PlayerSeasonStats`` entry. Only available
    /// mid-season for active players; returns an empty array in the off-season.
    /// Use `.group(_:)` to request batting or pitching projections.
    ///
    ///     let proj = try await SwiftBaseball.playerProjectedStats(id: 660271).group(.batting).fetch()
    public static func playerProjectedStats(id: Int) -> QueryBuilder<[PlayerSeasonStats]> {
        .playerProjectedStats(id: id, client: client)
    }

    /// Fetch sabermetric stats (wOBA, wRC+, WAR, etc.) for a player.
    ///
    ///     let saber = try await SwiftBaseball.playerSabermetrics(id: 660271).season(2024).fetch()
    public static func playerSabermetrics(id: Int) -> QueryBuilder<[PlayerSeasonStats]> {
        .playerSabermetrics(id: id, client: client)
    }

    /// Fetch home/away batting splits for a position player.
    ///
    ///     let splits = try await SwiftBaseball.playerHomeAwaySplits(id: 660271).season(2024).fetch()
    public static func playerHomeAwaySplits(id: Int) -> QueryBuilder<PlayerHomeAwaySplits> {
        .playerHomeAwaySplits(id: id, client: client)
    }

    /// Fetch home/away pitching splits for a pitcher.
    ///
    ///     let splits = try await SwiftBaseball.pitcherHomeAwaySplits(id: 543037).season(2024).fetch()
    public static func pitcherHomeAwaySplits(id: Int) -> QueryBuilder<PitcherHomeAwaySplits> {
        .pitcherHomeAwaySplits(id: id, client: client)
    }

    /// Fetch day/night batting splits for a position player.
    ///
    ///     let splits = try await SwiftBaseball.playerDayNightSplits(id: 660271).season(2024).fetch()
    public static func playerDayNightSplits(id: Int) -> QueryBuilder<PlayerDayNightSplits> {
        .playerDayNightSplits(id: id, client: client)
    }

    /// Fetch day/night pitching splits for a pitcher.
    ///
    ///     let splits = try await SwiftBaseball.pitcherDayNightSplits(id: 543037).season(2024).fetch()
    public static func pitcherDayNightSplits(id: Int) -> QueryBuilder<PitcherDayNightSplits> {
        .pitcherDayNightSplits(id: id, client: client)
    }

    /// Fetch per-month batting splits for a position player.
    ///
    ///     let splits = try await SwiftBaseball.playerMonthlySplits(id: 660271).season(2024).fetch()
    public static func playerMonthlySplits(id: Int) -> QueryBuilder<PlayerMonthlySplits> {
        .playerMonthlySplits(id: id, client: client)
    }

    /// Fetch per-month pitching splits for a pitcher.
    ///
    ///     let splits = try await SwiftBaseball.pitcherMonthlySplits(id: 543037).season(2024).fetch()
    public static func pitcherMonthlySplits(id: Int) -> QueryBuilder<PitcherMonthlySplits> {
        .pitcherMonthlySplits(id: id, client: client)
    }

    /// Fetch runners-on-base / RISP batting splits for a position player.
    ///
    ///     let splits = try await SwiftBaseball.playerRunnersOnSplits(id: 660271).season(2024).fetch()
    public static func playerRunnersOnSplits(id: Int) -> QueryBuilder<PlayerRunnersOnSplits> {
        .playerRunnersOnSplits(id: id, client: client)
    }

    /// Fetch runners-on-base / RISP pitching splits for a pitcher.
    ///
    ///     let splits = try await SwiftBaseball.pitcherRunnersOnSplits(id: 543037).season(2024).fetch()
    public static func pitcherRunnersOnSplits(id: Int) -> QueryBuilder<PitcherRunnersOnSplits> {
        .pitcherRunnersOnSplits(id: id, client: client)
    }

    /// Fetch leverage batting splits (low / medium / high) for a position player.
    ///
    ///     let splits = try await SwiftBaseball.playerLeverageSplits(id: 660271).season(2024).fetch()
    public static func playerLeverageSplits(id: Int) -> QueryBuilder<PlayerLeverageSplits> {
        .playerLeverageSplits(id: id, client: client)
    }

    /// Fetch leverage pitching splits (low / medium / high) for a pitcher.
    ///
    ///     let splits = try await SwiftBaseball.pitcherLeverageSplits(id: 543037).season(2024).fetch()
    public static func pitcherLeverageSplits(id: Int) -> QueryBuilder<PitcherLeverageSplits> {
        .pitcherLeverageSplits(id: id, client: client)
    }

    /// Fetch platoon batting splits (vs LHP / vs RHP) for a position player.
    ///
    ///     let splits = try await SwiftBaseball.playerPlatoonStats(id: 660271).season(2024).fetch()
    public static func playerPlatoonStats(id: Int) -> QueryBuilder<PlayerPlatoonStats> {
        .playerPlatoonStats(id: id, client: client)
    }

    /// Fetch platoon pitching splits (vs LHB / vs RHB) for a pitcher.
    ///
    ///     let splits = try await SwiftBaseball.pitcherPlatoonStats(id: 660271).season(2023).fetch()
    public static func pitcherPlatoonStats(id: Int) -> QueryBuilder<PitcherPlatoonStats> {
        .pitcherPlatoonStats(id: id, client: client)
    }

    /// Fetch season stats for multiple players concurrently.
    ///
    ///     let stats = try await SwiftBaseball
    ///         .batchStats([660271, 592450], group: .batting)
    ///         .season(2024)
    ///         .fetch()
    public static func batchStats(_ ids: [Int], group: StatGroup) -> BatchStatsQuery {
        BatchStatsQuery(playerIds: ids, group: group, client: client)
    }

    // MARK: - Statcast

    /// Fetch Statcast batted ball data from Baseball Savant.
    ///
    /// Returns aggregated batted ball profile including GB%, FB%, LD%,
    /// exit velocity, launch angle, barrel rate, and expected stats (xBA, xSLG, xwOBA).
    ///
    ///     let statcast = try await SwiftBaseball
    ///         .statcastBatting(playerId: 660271)
    ///         .season(2024)
    ///         .fetch()
    ///     print(statcast.gbPercent)  // 0.397
    public static func statcastBatting(playerId: Int) -> StatcastQuery {
        StatcastQuery(playerId: playerId, client: statcastClient)
    }

    /// Fetch Statcast pitching data from Baseball Savant.
    ///
    /// Returns batted-ball-against metrics and pitch arsenal data including
    /// velocity, spin rate, whiff rate, and pitch-type usage.
    ///
    ///     let statcast = try await SwiftBaseball
    ///         .statcastPitching(playerId: 543037)
    ///         .season(2024)
    ///         .fetch()
    ///     print(statcast.whiffRate)  // 0.25
    public static func statcastPitching(playerId: Int) -> StatcastPitcherQuery {
        StatcastPitcherQuery(playerId: playerId, client: statcastClient)
    }

    /// Fetch Statcast batted ball data for multiple batters in batched requests.
    ///
    /// Player IDs are sent in chunks of ``StatcastBatchBattingQuery/defaultBatchSize`` (8)
    /// per HTTP request, keeping responses under the Savant 25 000-row cap.
    /// Returns a dictionary keyed by MLB player ID.
    ///
    ///     let stats = try await SwiftBaseball
    ///         .statcastBatchBatting(playerIds: [660271, 592450, 665742])
    ///         .dateRange(start: "2025-01-01", end: "2026-03-26")
    ///         .fetch()
    ///     print(stats[660271]?.gbPercent)
    public static func statcastBatchBatting(playerIds: [Int]) -> StatcastBatchBattingQuery {
        StatcastBatchBattingQuery(playerIds: playerIds, client: statcastClient)
    }

    /// Fetch Statcast pitching data for multiple pitchers in batched requests.
    ///
    /// Player IDs are sent in chunks of ``StatcastBatchPitchingQuery/defaultBatchSize`` (8)
    /// per HTTP request, keeping responses under the Savant 25 000-row cap.
    /// Returns a dictionary keyed by MLB player ID.
    ///
    ///     let stats = try await SwiftBaseball
    ///         .statcastBatchPitching(playerIds: [808967, 687717, 641154])
    ///         .dateRange(start: "2025-01-01", end: "2026-03-26")
    ///         .fetch()
    ///     print(stats[808967]?.whiffRate)
    public static func statcastBatchPitching(playerIds: [Int]) -> StatcastBatchPitchingQuery {
        StatcastBatchPitchingQuery(playerIds: playerIds, client: statcastClient)
    }

    // MARK: - Baseball Savant Leaderboards

    /// Fetch the Baseball Savant sprint-speed leaderboard.
    ///
    /// Returns all qualified players for the requested season, ordered by speed descending.
    ///
    ///     let speeds = try await SwiftBaseball.sprintSpeed().season(2024).fetch()
    ///     print(speeds.first?.sprintSpeed)  // fastest player in ft/sec
    public static func sprintSpeed() -> SprintSpeedQuery {
        SprintSpeedQuery(client: statcastClient)
    }

    /// Fetch the Baseball Savant Outs Above Average (OAA) fielding leaderboard.
    ///
    /// Returns all qualified fielders for the requested season, ordered by OAA descending.
    /// Use `.position("SS")` to filter to a specific position.
    ///
    ///     let oaa = try await SwiftBaseball.outsAboveAverage().season(2024).fetch()
    ///     print(oaa.first?.oaa)  // top fielder's OAA
    public static func outsAboveAverage() -> OAAQuery {
        OAAQuery(client: statcastClient)
    }

    /// Fetch the Baseball Savant catcher framing leaderboard.
    ///
    /// Returns all qualified catchers for the requested season. `framingRunsAdded`
    /// is the primary metric — the run value of called strikes earned above average.
    ///
    ///     let framing = try await SwiftBaseball.catcherFraming().season(2024).fetch()
    ///     print(framing.first?.framingRunsAdded)  // top framer's run value
    public static func catcherFraming() -> CatcherFramingQuery {
        CatcherFramingQuery(client: statcastClient)
    }

    /// Fetch the Baseball Savant catcher pop time leaderboard.
    ///
    /// Returns catchers with at least `minAttempts` steal attempts for the requested season.
    /// Pop time is the total elapsed time from pitch receipt to the fielder at 2B or 3B
    /// receiving the throw. Use `.minAttempts(_:)` to adjust the threshold (default: 5).
    ///
    ///     let popTimes = try await SwiftBaseball.catcherPopTime().season(2024).fetch()
    ///     print(popTimes.first?.popTimeTo2B)   // fastest pop time to 2B in seconds
    ///     print(popTimes.first?.exchangeTime)  // reaction + exchange in seconds
    public static func catcherPopTime() -> PopTimeQuery {
        PopTimeQuery(client: statcastClient)
    }

    // MARK: - Venues

    /// Fetch all MLB venues with field dimensions and GPS coordinates.
    ///
    /// Returns both active and historical venues. Use `.season(_:)` to filter
    /// to venues active in a specific year.
    ///
    ///     let venues = try await SwiftBaseball.venues().fetch()
    ///     let yankeeStadium = venues.first { $0.id == 3313 }
    ///     print(yankeeStadium?.dimensions?.center)  // Optional(408)
    public static func venues() -> QueryBuilder<[Venue]> {
        .venues(client: client)
    }

    /// Fetch a single venue by MLB venue ID.
    ///
    ///     let stadium = try await SwiftBaseball.venue(id: 3313).fetch()
    ///     print(stadium.dimensions?.leftLine)   // Optional(318)
    ///     print(stadium.coordinates?.latitude)  // Optional(40.82919482)
    public static func venue(id: Int) -> QueryBuilder<Venue> {
        .venue(id: id, client: client)
    }

    // MARK: - Draft

    /// Fetch MLB draft picks for a given year.
    ///
    /// Returns all picks across all rounds, ordered by overall pick number.
    /// Use `.round(_:)` to narrow to a single round, or `.teamId(_:)` to see
    /// one team's selections.
    ///
    ///     let picks = try await SwiftBaseball.draft(year: 2024).fetch()
    ///     let firstRound = try await SwiftBaseball.draft(year: 2024).round(1).fetch()
    public static func draft(year: Int) -> QueryBuilder<[DraftPick]> {
        .draft(year: year, client: client)
    }

    // MARK: - Awards

    /// Fetch recipients of a specific MLB award, optionally filtered by season.
    ///
    /// Pass any valid MLB award ID (e.g. `"ALMVP"`, `"NLCY"`, `"MLBHOF"`).
    /// Use ``awards()`` to retrieve the full list of award IDs.
    ///
    ///     let winners = try await SwiftBaseball.awardRecipients(awardId: "ALMVP").season(2024).fetch()
    ///     print(winners.first?.player?.fullName)  // Optional("Aaron Judge")
    ///
    /// - SeeAlso: ``Award``, ``AwardRecipient``, ``awards()``
    public static func awardRecipients(awardId: String) -> QueryBuilder<[AwardRecipient]> {
        .awardRecipients(awardId: awardId, client: client)
    }

    /// Fetch all defined MLB award types.
    ///
    /// Returns every award in the MLB Stats API including historical and
    /// inactive awards. Use the returned ``Award/id`` values with
    /// ``awardRecipients(awardId:)`` to fetch winners.
    ///
    ///     let awards = try await SwiftBaseball.awards().fetch()
    ///     let active = awards.filter(\.active)
    ///
    /// - SeeAlso: ``Award``, ``awardRecipients(awardId:)``
    public static func awards() -> QueryBuilder<[Award]> {
        .allAwards(client: client)
    }

    // MARK: - Standings

    /// Fetch division standings.
    ///
    ///     let standing = try await SwiftBaseball.standings(.season(2024)).league(.american).fetch()
    public static func standings(_ query: StandingsQuery) -> QueryBuilder<[DivisionStandings]> {
        .standings(query, client: client)
    }

    // MARK: - Leaders

    /// Fetch league leaders for a stat category.
    ///
    ///     let hrLeaders = try await SwiftBaseball.leaders(.homeRuns).season(2024).limit(10).fetch()
    public static func leaders(_ category: LeaderStatCategory) -> QueryBuilder<[LeaderCategory]> {
        .leaders(category, client: client)
    }
}
