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
    }

    private static var client: any APIClient { _state.client }

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
    ///     let roster = try await SwiftBaseball.roster(teamId: 147, season: 2024).fetch()
    public static func roster(teamId: Int, season: Int) -> QueryBuilder<[RosterEntry]> {
        .roster(teamId: teamId, season: season, client: client)
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

    /// Fetch a game's line score.
    public static func linescore(gamePk: Int) -> QueryBuilder<Linescore> {
        .linescore(gamePk: gamePk, client: client)
    }

    // MARK: - Stats

    /// Fetch season stats for a player.
    ///
    ///     let stats = try await SwiftBaseball.playerStats(id: 660271).season(2024).group(.batting).fetch()
    public static func playerStats(id: Int) -> QueryBuilder<[PlayerSeasonStats]> {
        .playerStats(id: id, client: client)
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
