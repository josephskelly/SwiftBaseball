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

    /// Query teams.
    ///
    ///     let teams = try await SwiftBaseball.teams(.all(season: 2024)).fetch()
    public static func teams(_ query: TeamQuery) -> QueryBuilder<[Team]> {
        .teams(query, client: client)
    }

    /// Fetch a single team by MLB ID.
    ///
    ///     let yankees = try await SwiftBaseball.team(id: 147).fetch()
    public static func team(id: Int) -> QueryBuilder<Team> {
        .singleTeam(id: id, client: client)
    }

    /// Fetch a team's roster.
    ///
    /// The default ``RosterType/active`` returns the 26-man active roster, suitable
    /// for regular-season views. Pass ``RosterType/fortyMan`` or
    /// ``RosterType/nonRosterInvitees`` for spring training / exhibition rosters.
    ///
    ///     let roster = try await SwiftBaseball.roster(teamId: 147, season: 2024).fetch()
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
    ///     let stats = try await SwiftBaseball.playerStats(id: 660271).season(2024).group(.batting).fetch()
    public static func playerStats(id: Int) -> QueryBuilder<[PlayerSeasonStats]> {
        .playerStats(id: id, client: client)
    }

    /// Fetch career (lifetime) stats for a player.
    ///
    /// Returns a single ``PlayerSeasonStats`` entry per requested group with
    /// cumulative totals across the player's entire career. Use `.group(_:)` to
    /// request batting, pitching, or fielding. The `season` property on the
    /// returned entry will be empty (`""`).
    ///
    ///     let career = try await SwiftBaseball.playerCareerStats(id: 660271).group(.batting).fetch()
    public static func playerCareerStats(id: Int) -> QueryBuilder<[PlayerSeasonStats]> {
        .playerCareerStats(id: id, client: client)
    }

    /// Fetch year-by-year stats for a player.
    ///
    /// Returns one ``PlayerSeasonStats`` entry per season the player has
    /// appeared in, ordered chronologically. Use `.group(_:)` to request batting,
    /// pitching, or fielding.
    ///
    ///     let history = try await SwiftBaseball.playerYearByYear(id: 660271).group(.batting).fetch()
    public static func playerYearByYear(id: Int) -> QueryBuilder<[PlayerSeasonStats]> {
        .playerYearByYear(id: id, client: client)
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
