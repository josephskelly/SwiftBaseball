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

    /// Thread-safe holder for the library's shared state. All reads and writes
    /// are serialized through `NSLock`, which is why `@unchecked Sendable` is
    /// sound here — the lock supplies the synchronization that the compiler
    /// cannot prove on its own. Keeping the holder as a class (not an actor)
    /// lets ``configure(_:)`` remain synchronous, which consumers rely on
    /// during app launch before any `await` is reachable.
    private final class State: @unchecked Sendable {
        private let lock = NSLock()
        private var _client: any APIClient = URLSessionAPIClient()
        private var _statcastClient: StatcastAPIClient = .init()
        private var _configuration: Configuration = .default

        var client: any APIClient {
            lock.lock()
            defer { lock.unlock() }
            return _client
        }

        var statcastClient: StatcastAPIClient {
            lock.lock()
            defer { lock.unlock() }
            return _statcastClient
        }

        var configuration: Configuration {
            lock.lock()
            defer { lock.unlock() }
            return _configuration
        }

        func apply(_ configuration: Configuration) {
            let base = URLSessionAPIClient(configuration: configuration)
            let newClient: any APIClient
            if configuration.cacheEnabled {
                let cache = CacheManager(defaultTTL: configuration.cacheTTL)
                newClient = CachingAPIClient(wrapped: base, cache: cache, ttl: configuration.cacheTTL)
            } else {
                newClient = base
            }
            let newStatcast = StatcastAPIClient(configuration: configuration)

            lock.lock()
            defer { lock.unlock() }
            _configuration = configuration
            _client = newClient
            _statcastClient = newStatcast
        }
    }

    private static let _state = State()

    /// Replaces the library's shared configuration.
    ///
    /// Safe to call concurrently; access is serialized internally. Typically
    /// invoked once during app launch before any queries are started.
    public static func configure(_ configuration: Configuration) {
        _state.apply(configuration)
    }

    private static var client: any APIClient {
        _state.client
    }

    private static var statcastClient: StatcastAPIClient {
        _state.statcastClient
    }

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

    /// Fetch every player active at a given level for a season.
    ///
    /// Returns the bulk player roster for an entire sport (e.g. all 1,400+ MLB
    /// players who appeared in 2024). Useful for league-wide aggregation,
    /// minor-league scouting, and bulk player-ID enumeration without paging
    /// through individual team rosters.
    ///
    ///     let mlb2024  = try await SwiftBaseball.sportPlayers(season: 2024).fetch()
    ///     let aaa2024  = try await SwiftBaseball.sportPlayers(sport: .tripleA, season: 2024).fetch()
    ///
    /// - Parameters:
    ///   - sport: The sport / minor-league level. Defaults to ``Sport/mlb``.
    ///   - season: The season to filter by. Required by the upstream API.
    public static func sportPlayers(sport: Sport = .mlb, season: Int) -> QueryBuilder<[Player]> {
        .sportPlayers(sport: sport, season: season, client: client)
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

    /// Fetch venue-change history for one or more franchises.
    ///
    /// Each returned ``Team`` is a snapshot of the franchise at a season when
    /// its home venue or location changed — useful for reconstructing a club's
    /// stadium timeline (e.g. the Yankees moved Hilltop → Polo Grounds → Yankee
    /// Stadium I → Shea Stadium → Yankee Stadium). ``Team/season`` carries the
    /// year of each snapshot. Pass multiple `teamIds` to fetch comparable
    /// histories for several franchises in one call.
    ///
    ///     let yankeesHistory = try await SwiftBaseball.teamHistory(teamIds: [147]).fetch()
    ///     for snapshot in yankeesHistory {
    ///         print(snapshot.season ?? 0, snapshot.venue.name)
    ///     }
    ///
    /// - Parameter teamIds: One or more MLB team identifiers.
    public static func teamHistory(teamIds: [Int]) -> QueryBuilder<[Team]> {
        .teamHistory(teamIds: teamIds, client: client)
    }

    /// Fetch the coaching staff for a team.
    ///
    /// Returns the manager plus every listed field coach (bench, pitching,
    /// hitting, base coaches, etc.) on the team's current coaching roster.
    /// Filter by ``TeamStaff/jobId`` for stable role-based lookups —
    /// e.g. `"MNGR"` for manager, `"COAB"` for bench coach.
    ///
    ///     let staff = try await SwiftBaseball.teamCoaches(teamId: 147).fetch()
    ///     let manager = staff.first { $0.jobId == "MNGR" }
    ///     print(manager?.person.fullName ?? "")
    ///
    /// - Parameter teamId: The MLB team identifier.
    public static func teamCoaches(teamId: Int) -> QueryBuilder<[TeamStaff]> {
        .teamCoaches(teamId: teamId, client: client)
    }

    /// Fetch the off-field personnel roster for a team.
    ///
    /// Returns support staff not listed on the coaching roster — athletic
    /// trainers, team physicians, strength and conditioning coaches,
    /// dietitians, massage therapists, equipment and clubhouse managers,
    /// team travel, team security, and media relations. Use
    /// ``TeamStaff/jobId`` for stable role-based lookups — e.g. `"HATR"`
    /// (head athletic trainer), `"DRPH"` (director of player health),
    /// `"EQUP"` (equipment manager).
    ///
    ///     let personnel = try await SwiftBaseball.teamPersonnel(teamId: 147).fetch()
    ///     let trainers = personnel.filter { $0.jobId == "HATR" || $0.jobId == "AATR" }
    ///     for p in trainers {
    ///         print(p.title ?? p.job, "-", p.person.fullName)
    ///     }
    ///
    /// - SeeAlso: ``teamCoaches(teamId:)`` for on-field staff.
    /// - Parameter teamId: The MLB team identifier.
    public static func teamPersonnel(teamId: Int) -> QueryBuilder<[TeamStaff]> {
        .teamPersonnel(teamId: teamId, client: client)
    }

    /// Fetch team alumni for a given season.
    ///
    /// Returns every former player who appeared with the team at any point
    /// in the team's history and played in the given `season` with any
    /// organization. The returned ``Player`` values carry
    /// ``Player/alumniLastSeason`` indicating the last season each player
    /// appeared with *this* team.
    ///
    ///     let alumni = try await SwiftBaseball.teamAlumni(teamId: 147, season: 2024).fetch()
    ///     let recentlyDeparted = alumni.filter { $0.alumniLastSeason == "2023" }
    ///
    /// - Parameters:
    ///   - teamId: The MLB team identifier.
    ///   - season: The season to filter by. Required by the upstream API.
    public static func teamAlumni(teamId: Int, season: Int) -> QueryBuilder<[Player]> {
        .teamAlumni(teamId: teamId, season: season, client: client)
    }

    /// Fetch season attendance totals for a team.
    ///
    /// Returns one ``TeamAttendance`` per (season, gameType) record — in
    /// practice one entry for the regular season, and sometimes additional
    /// entries if the team played postseason or spring games counted
    /// separately by the upstream API. Figures are paid-gate attendance,
    /// matching MLB's public numbers.
    ///
    ///     let records = try await SwiftBaseball.attendance(teamId: 147, season: 2024).fetch()
    ///     let regular = records.first { $0.gameType == .regularSeason }
    ///     print(regular?.attendanceAverageHome ?? 0)    // 41897
    ///     print(regular?.attendanceHigh ?? 0)           // 48760
    ///
    /// - Parameters:
    ///   - teamId: The MLB team identifier.
    ///   - season: The season to report on.
    public static func attendance(teamId: Int, season: Int) -> QueryBuilder<[TeamAttendance]> {
        .attendance(teamId: teamId, season: season, client: client)
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
    /// Pass a `date` string (`"YYYY-MM-DD"`) to fetch the roster as of a
    /// specific date — useful for viewing historical active rosters.
    ///
    ///     // MLB active 26-man
    ///     let roster = try await SwiftBaseball.roster(teamId: 147, season: 2024).fetch()
    ///     // Historical roster on a specific date
    ///     let historical = try await SwiftBaseball.roster(teamId: 147, season: 2024, date: "2024-07-04").fetch()
    ///     // Minor league full-season roster
    ///     let mibRoster = try await SwiftBaseball.roster(teamId: 531, season: 2024, rosterType: .fullSeason).fetch()
    ///     // Spring training 40-man
    ///     let spring = try await SwiftBaseball.roster(teamId: 147, season: 2025, rosterType: .fortyMan).fetch()
    public static func roster(
        teamId: Int,
        season: Int,
        rosterType: RosterType = .active,
        date: String? = nil
    ) -> QueryBuilder<[RosterEntry]> {
        .roster(teamId: teamId, season: season, rosterType: rosterType, date: date, client: client)
    }

    // MARK: - Schedule

    /// Query game schedule.
    ///
    ///     let games  = try await SwiftBaseball.schedule(.date("2024-07-04")).fetch()
    ///     let season = try await SwiftBaseball.schedule(.season(2024)).teamId(147).fetch()
    ///
    /// Pass ``ScheduleHydration`` values to embed additional data in the response:
    ///
    ///     let games = try await SwiftBaseball.schedule(.date("2024-07-04"), hydrate: [.probablePitcher]).fetch()
    ///
    /// - Parameters:
    ///   - query: The date, range, or season to fetch.
    ///   - hydrate: Additional data to embed. Defaults to none.
    public static func schedule(
        _ query: ScheduleQuery,
        hydrate: [ScheduleHydration] = []
    ) -> QueryBuilder<[ScheduleEntry]> {
        .schedule(query, hydrate: hydrate, client: client)
    }

    /// Query the dedicated postseason schedule endpoint.
    ///
    ///     let games = try await SwiftBaseball.postseasonSchedule(season: 2024).fetch()
    ///
    /// Returns every postseason game (Wild Card, Division, League Championship, World Series)
    /// for the requested season as a flat list. Use ``postseasonSeries(season:)`` to receive
    /// the games grouped by series instead.
    public static func postseasonSchedule(season: Int) -> QueryBuilder<[ScheduleEntry]> {
        .postseasonSchedule(season: season, client: client)
    }

    /// Query the postseason series endpoint.
    ///
    ///     let series = try await SwiftBaseball.postseasonSeries(season: 2024).fetch()
    ///     let worldSeries = series.first(where: { $0.gameType == .worldSeries })
    ///
    /// Each ``PostseasonSeries`` groups the games played in a single matchup, so consumers
    /// can step round by round (Wild Card → Division → LCS → World Series).
    public static func postseasonSeries(season: Int) -> QueryBuilder<[PostseasonSeries]> {
        .postseasonSeries(season: season, client: client)
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

    /// Fetch the complete live game feed for a game.
    ///
    /// The live feed is MLB's real-time composite payload — a single snapshot
    /// covering game metadata, every play, the current at-bat, linescore,
    /// boxscore, and decisions (winning/losing/save pitchers). This is the
    /// same feed the MLB app polls during live games.
    ///
    ///     let feed = try await SwiftBaseball.liveGameFeed(gamePk: 745612).fetch()
    ///     print(feed.gameData.status.abstractGameState)   // e.g. .final
    ///     print(feed.liveData.plays.currentPlay?.result.event ?? "No current play")
    ///
    /// During an active game, clients typically poll this endpoint using
    /// ``LiveFeedMeta/wait`` (seconds) as the recommended interval.
    ///
    /// - Parameter gamePk: The MLB game primary key.
    /// - Returns: A ``QueryBuilder`` producing a ``LiveGameFeed``.
    public static func liveGameFeed(gamePk: Int) -> QueryBuilder<LiveGameFeed> {
        .liveGameFeed(gamePk: gamePk, client: client)
    }

    /// Fetch per-at-bat win-probability snapshots for a game.
    ///
    /// Returns one ``PlayWinProbability`` per completed plate appearance,
    /// each carrying the home and away team win-probability percentages
    /// after the play plus the change attributable to the play
    /// (``PlayWinProbability/homeTeamWinProbabilityAdded``, a.k.a. WPA under
    /// the home-team convention).
    ///
    ///     let wp = try await SwiftBaseball.winProbability(gamePk: 745612).fetch()
    ///     let topWPA = wp.max { abs($0.homeTeamWinProbabilityAdded) < abs($1.homeTeamWinProbabilityAdded) }
    ///     print(topWPA?.result.event ?? "")         // biggest swing of the game
    ///     print(topWPA?.homeTeamWinProbabilityAdded ?? 0)
    ///
    /// - Parameter gamePk: The MLB game primary key.
    public static func winProbability(gamePk: Int) -> QueryBuilder<[PlayWinProbability]> {
        .winProbability(gamePk: gamePk, client: client)
    }

    /// Fetch current-state context metrics for a game.
    ///
    /// Returns a single ``GameContextMetrics`` snapshot — home/away win
    /// probabilities as of the most recent play. For completed games this
    /// reflects the final state; for live games it reflects the in-flight
    /// situation and updates as the game progresses.
    ///
    ///     let ctx = try await SwiftBaseball.contextMetrics(gamePk: 745612).fetch()
    ///     print("Home WP: \(ctx.homeWinProbability)%")
    ///
    /// - Parameter gamePk: The MLB game primary key.
    public static func contextMetrics(gamePk: Int) -> QueryBuilder<GameContextMetrics> {
        .contextMetrics(gamePk: gamePk, client: client)
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

    // MARK: - Umpires

    /// Fetch the MLB umpire roster eligible to work on a given date.
    ///
    /// Returns the full pool of umpires on duty for that day — not a per-game
    /// crew assignment. Most entries carry ``Umpire/jobId`` of `"UMPR"`; crew
    /// chiefs and umpire-desk staff use distinct codes.
    ///
    ///     let ump = try await SwiftBaseball.umpires(date: "2024-07-04").fetch()
    ///     let crewChiefs = ump.filter { $0.jobId != "UMPR" }
    ///
    /// - Parameter date: Calendar date in `YYYY-MM-DD` format.
    public static func umpires(date: String) -> QueryBuilder<[Umpire]> {
        .umpires(date: date, client: client)
    }

    /// Fetch the MLB umpire roster eligible to work on a given date.
    ///
    /// `Date`-accepting overload of ``umpires(date:)-(String)``. The date is
    /// formatted as `"yyyy-MM-dd"` UTC, the canonical wire format.
    ///
    /// - Parameter date: Calendar date.
    public static func umpires(date: Date) -> QueryBuilder<[Umpire]> {
        umpires(date: MLBDateFormatter.string(from: date))
    }

    // MARK: - Official Scorers

    /// Fetch the MLB official-scorer roster eligible to work on a given date.
    ///
    /// Returns the full pool of official scorers on duty for that day — not a per-game
    /// assignment. Entries carry ``OfficialScorer/jobId`` of `"SCOR"`.
    ///
    ///     let scorers = try await SwiftBaseball.officialScorers(date: "2024-07-04").fetch()
    ///
    /// - Parameter date: Calendar date in `YYYY-MM-DD` format.
    public static func officialScorers(date: String) -> QueryBuilder<[OfficialScorer]> {
        .officialScorers(date: date, client: client)
    }

    /// Fetch the MLB official-scorer roster eligible to work on a given date.
    ///
    /// `Date`-accepting overload of ``officialScorers(date:)-(String)``. The
    /// date is formatted as `"yyyy-MM-dd"` UTC, the canonical wire format.
    ///
    /// - Parameter date: Calendar date.
    public static func officialScorers(date: Date) -> QueryBuilder<[OfficialScorer]> {
        officialScorers(date: MLBDateFormatter.string(from: date))
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

    /// Fetch sabermetric stats (wOBA, wRC+, WAR) for every player on a team in one call.
    ///
    /// Uses the top-level `/stats?teamId` endpoint, which returns all players in a single
    /// response instead of requiring one request per player. Chain `.season(_:)` for the year.
    ///
    ///     let stats = try await SwiftBaseball.teamSabermetrics(teamId: 147).season(2025).fetch()
    public static func teamSabermetrics(teamId: Int) -> QueryBuilder<[PlayerSeasonStats]> {
        .teamSabermetrics(teamId: teamId, client: client)
    }

    /// Fetch season stats for every player on a team in one call.
    ///
    /// Uses the top-level `/stats?teamId` endpoint. Chain `.season(_:)` and `.gameType(_:)`.
    /// Use `gameType("R")` to restrict to regular season (recommended for sabermetric context).
    ///
    ///     let batting = try await SwiftBaseball.teamStats(teamId: 147, group: .batting)
    ///         .season(2025).gameType("R").fetch()
    public static func teamStats(teamId: Int, group: StatGroup) -> QueryBuilder<[PlayerSeasonStats]> {
        .teamStats(teamId: teamId, group: group, client: client)
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

    /// Fetch career platoon batting splits (vs LHP / vs RHP) for a position player.
    ///
    /// Uses `stats=careerStatSplits`, which returns pre-aggregated career totals per
    /// split code. No season filter is needed or applicable.
    ///
    ///     let career = try await SwiftBaseball.playerCareerPlatoonStats(id: 660271).fetch()
    ///     print(career.vsLeft?.homeRuns)   // career HRs vs LHP
    ///     print(career.vsRight?.ops)       // career OPS vs RHP
    public static func playerCareerPlatoonStats(id: Int) -> QueryBuilder<PlayerCareerPlatoonStats> {
        .playerCareerPlatoonStats(id: id, client: client)
    }

    /// Fetch career platoon pitching splits (vs LHB / vs RHB) for a pitcher.
    ///
    /// Uses `stats=careerStatSplits`, which returns pre-aggregated career totals per
    /// split code. No season filter is needed or applicable.
    ///
    ///     let career = try await SwiftBaseball.pitcherCareerPlatoonStats(id: 543037).fetch()
    ///     print(career.vsLeft?.strikeOuts)  // career Ks vs LHB
    public static func pitcherCareerPlatoonStats(id: Int) -> QueryBuilder<PitcherCareerPlatoonStats> {
        .pitcherCareerPlatoonStats(id: id, client: client)
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

    /// Fetch career Statcast batting splits vs LHP and RHP from Baseball Savant.
    ///
    /// Fires two concurrent requests — one for `p_throws=L` and one for `p_throws=R` —
    /// with no date filter, covering the full Statcast era (2015–present).
    ///
    ///     let splits = try await SwiftBaseball
    ///         .statcastCareerSplits(playerId: 660271)
    ///         .fetch()
    ///     print(splits.vsLHP.xwOBA)   // career xwOBA vs LHP
    ///     print(splits.vsRHP.pa)      // career PA vs RHP
    public static func statcastCareerSplits(playerId: Int) -> StatcastCareerSplitBattingQuery {
        StatcastCareerSplitBattingQuery(playerId: playerId, client: statcastClient)
    }

    /// Fetch career Statcast batting splits for multiple batters in batched requests.
    ///
    /// Player IDs are sent in chunks of ``StatcastBatchCareerSplitBattingQuery/defaultBatchSize`` (4)
    /// per request pair, keeping each response under the Savant 25,000-row cap.
    /// Returns a dictionary keyed by MLB player ID.
    ///
    ///     let splits = try await SwiftBaseball
    ///         .statcastBatchCareerSplits([660271, 592450, 665742])
    ///         .fetch()
    ///     print(splits[660271]?.vsLHP.xwOBA)
    public static func statcastBatchCareerSplits(_ ids: [Int]) -> StatcastBatchCareerSplitBattingQuery {
        StatcastBatchCareerSplitBattingQuery(playerIds: ids, client: statcastClient)
    }

    // MARK: - Raw Statcast

    /// Fetch raw Baseball Savant pitch-level data across a date range, with no aggregation.
    ///
    /// Returns one ``StatcastPitch`` per pitch in the window. The range is split
    /// into 7-day chunks internally so each request stays under the Savant
    /// 25 000-row cap; chunks are dispatched concurrently.
    ///
    ///     let pitches = try await SwiftBaseball
    ///         .statcastRaw(start: "2024-05-21", end: "2024-05-21")
    ///         .fetch()
    ///     print(pitches.count)
    ///
    /// - Parameters:
    ///   - start: Inclusive start date in `"YYYY-MM-DD"` form.
    ///   - end: Inclusive end date in `"YYYY-MM-DD"` form.
    public static func statcastRaw(start: String, end: String) -> StatcastRawQuery {
        StatcastRawQuery(client: statcastClient, start: start, end: end)
    }

    /// Fetch raw Baseball Savant pitch-level data across a date range, with no aggregation.
    ///
    /// `Date`-accepting overload of ``statcastRaw(start:end:)-(String,_)``.
    ///
    /// - Parameters:
    ///   - start: Inclusive start date.
    ///   - end: Inclusive end date.
    public static func statcastRaw(start: Date, end: Date) -> StatcastRawQuery {
        statcastRaw(
            start: MLBDateFormatter.string(from: start),
            end: MLBDateFormatter.string(from: end)
        )
    }

    /// Fetch raw Baseball Savant pitch-level data filtered to a single batter.
    ///
    /// Returns one ``StatcastPitch`` per pitch the batter saw in the requested window.
    ///
    ///     let pitches = try await SwiftBaseball
    ///         .statcastBatterRaw(playerId: 660271)
    ///         .season(2024)
    ///         .fetch()
    public static func statcastBatterRaw(playerId: Int) -> StatcastBatterRawQuery {
        StatcastBatterRawQuery(client: statcastClient, playerId: playerId)
    }

    /// Fetch raw Baseball Savant pitch-level data filtered to a single pitcher.
    ///
    /// Returns one ``StatcastPitch`` per pitch the pitcher threw in the requested window.
    ///
    ///     let pitches = try await SwiftBaseball
    ///         .statcastPitcherRaw(playerId: 543037)
    ///         .season(2024)
    ///         .fetch()
    public static func statcastPitcherRaw(playerId: Int) -> StatcastPitcherRawQuery {
        StatcastPitcherRawQuery(client: statcastClient, playerId: playerId)
    }

    /// Fetch every pitch from a single game by `game_pk`.
    ///
    ///     let pitches = try await SwiftBaseball.statcastGame(gamePk: 746309).fetch()
    public static func statcastGame(gamePk: Int) -> StatcastGameRawQuery {
        StatcastGameRawQuery(client: statcastClient, gamePk: gamePk)
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

    /// Build a query for the Baseball Savant batter expected-statistics leaderboard.
    ///
    /// Returns each qualified hitter's actual vs expected slash line (BA / SLG / wOBA)
    /// for the requested season. Positive `expected*Diff` fields indicate a hitter
    /// outperforming their batted-ball profile.
    ///
    ///     let xstats = try await SwiftBaseball.expectedStatsBatter().season(2024).fetch()
    ///     print(xstats.first?.expectedWOBA)  // qualified leader's xwOBA
    public static func expectedStatsBatter() -> ExpectedStatsBatterQuery {
        ExpectedStatsBatterQuery(client: statcastClient)
    }

    /// Build a query for the Baseball Savant pitcher expected-statistics leaderboard.
    ///
    /// Mirrors ``expectedStatsBatter()`` but reports stats _allowed_, plus actual ERA
    /// vs xERA. Negative `expected*Diff` values indicate a pitcher suppressing
    /// outcomes below what their contact profile would predict.
    ///
    ///     let xstats = try await SwiftBaseball.expectedStatsPitcher().season(2024).fetch()
    ///     print(xstats.first?.expectedERA)
    public static func expectedStatsPitcher() -> ExpectedStatsPitcherQuery {
        ExpectedStatsPitcherQuery(client: statcastClient)
    }

    /// Build a query for the Baseball Savant batter percentile-rankings leaderboard.
    ///
    /// Returns each player's 1–99 percentile rank for every tracked metric (xwOBA,
    /// xBA, exit velocity, hard-hit rate, sprint speed, OAA, bat speed, etc.) within
    /// the qualifying batter pool. Empty cells become `nil`.
    ///
    ///     let pct = try await SwiftBaseball.percentileRanksBatter().season(2024).fetch()
    ///     print(pct.first?.exitVelocityPercentile)
    public static func percentileRanksBatter() -> PercentileRanksBatterQuery {
        PercentileRanksBatterQuery(client: statcastClient)
    }

    /// Build a query for the Baseball Savant pitcher percentile-rankings leaderboard.
    ///
    /// Returns 1–99 percentile ranks for each tracked pitcher metric (xwOBA-against,
    /// xERA, fastball velocity / spin, curve spin, K%, BB%, chase, whiff, etc.).
    ///
    ///     let pct = try await SwiftBaseball.percentileRanksPitcher().season(2024).fetch()
    ///     print(pct.first?.fastballVelocityPercentile)
    public static func percentileRanksPitcher() -> PercentileRanksPitcherQuery {
        PercentileRanksPitcherQuery(client: statcastClient)
    }

    /// Build a query for the Baseball Savant batter exit-velocity & barrels leaderboard.
    ///
    /// Returns the contact-quality summary for qualified hitters: average and max EV,
    /// hard-hit rate (95+ mph), sweet-spot rate, barrels, and barrel rates per BBE / PA.
    ///
    ///     let ev = try await SwiftBaseball.exitVeloBarrelsBatter().season(2024).fetch()
    ///     print(ev.first?.avgExitVelocity)
    public static func exitVeloBarrelsBatter() -> ExitVeloBarrelsBatterQuery {
        ExitVeloBarrelsBatterQuery(client: statcastClient)
    }

    /// Build a query for the Baseball Savant pitcher exit-velocity & barrels leaderboard.
    ///
    /// Mirrors ``exitVeloBarrelsBatter()`` but reports the contact a pitcher allows.
    ///
    ///     let ev = try await SwiftBaseball.exitVeloBarrelsPitcher().season(2024).fetch()
    ///     print(ev.first?.barrelRate)  // barrel% allowed by the qualifying leader
    public static func exitVeloBarrelsPitcher() -> ExitVeloBarrelsPitcherQuery {
        ExitVeloBarrelsPitcherQuery(client: statcastClient)
    }

    /// Build a query for the Baseball Savant `pitch-arsenals` leaderboard.
    ///
    /// Returns one entry per (pitcher × pitch type) with a single metric
    /// (velocity, spin rate, or pitch count). Chain ``PitchArsenalQuery/metric(_:)``
    /// to choose which view; the default is ``PitchArsenalMetric/velocity``.
    ///
    ///     let velos = try await SwiftBaseball.pitchArsenal().season(2024).metric(.velocity).fetch()
    ///     print(velos.first?.value)  // top average fastball mph
    public static func pitchArsenal() -> PitchArsenalQuery {
        PitchArsenalQuery(client: statcastClient)
    }

    /// Build a query for the Baseball Savant `pitch-arsenal-stats` leaderboard.
    ///
    /// Returns per-pitch outcomes for every pitcher × pitch-type combination meeting
    /// the minimum-PA threshold: run value, swings & misses, BA / SLG / wOBA actual
    /// vs expected, and hard-hit rate. Use
    /// ``PitchArsenalStatsQuery/minPlateAppearances(_:)`` to relax the default 25-PA cutoff.
    ///
    ///     let stats = try await SwiftBaseball.pitchArsenalStats().season(2024).fetch()
    ///     print(stats.first?.runValuePer100)
    public static func pitchArsenalStats() -> PitchArsenalStatsQuery {
        PitchArsenalStatsQuery(client: statcastClient)
    }

    /// Build a query for the Baseball Savant `pitch-movement` leaderboard.
    ///
    /// Returns one row per (pitcher × pitch type) with raw vertical and horizontal
    /// break (gravity-included and induced) plus differentials versus league average
    /// for the same pitch type and velocity, and percentile ranks of those diffs.
    ///
    ///     let movement = try await SwiftBaseball.pitchMovement().season(2024).fetch()
    ///     print(movement.first?.diffZ)  // most rise above league
    public static func pitchMovement() -> PitchMovementQuery {
        PitchMovementQuery(client: statcastClient)
    }

    /// Build a query for the Baseball Savant `active-spin` leaderboard.
    ///
    /// Returns one entry per (pitcher × pitch type) with the active-spin percentage
    /// — the share of total spin contributing to movement (vs gyro spin). Values are
    /// reported on the **0–100 scale**.
    ///
    ///     let entries = try await SwiftBaseball.activeSpin().season(2024).fetch()
    ///     print(entries.first?.activeSpinPercent)
    public static func activeSpin() -> ActiveSpinQuery {
        ActiveSpinQuery(client: statcastClient)
    }

    /// Build a query for the Baseball Savant `running_splits` leaderboard.
    ///
    /// Returns one entry per (player × bat side) with cumulative seconds at every
    /// 5-foot mark from 0 to 90 ft (home-to-first). Useful for reconstructing
    /// acceleration profiles and surfacing both reaction time and top-end speed.
    ///
    ///     let splits = try await SwiftBaseball.runningSplits().season(2024).fetch()
    ///     print(splits.first?.secondsTo90ft)
    public static func runningSplits() -> RunningSplitsQuery {
        RunningSplitsQuery(client: statcastClient)
    }

    /// Build a query for the Baseball Savant `bat-tracking` leaderboard (2024+).
    ///
    /// Returns one entry per batter with bat speed, swing length, fast-swing rate,
    /// squared-up rate, blast rate, and run value. Rate fields are reported on the
    /// **0–1 fraction scale**, unlike most other Savant boards.
    ///
    ///     let tracking = try await SwiftBaseball.batTracking().season(2024).fetch()
    ///     print(tracking.first?.avgBatSpeed)
    public static func batTracking() -> BatTrackingQuery {
        BatTrackingQuery(client: statcastClient)
    }

    /// Build a query for the Baseball Savant `catch_probability` leaderboard.
    ///
    /// Returns one entry per outfielder with a per-star-bucket breakdown
    /// (1-star = easiest, 5-star = hardest) of opportunities, outs, and catch
    /// percentage. Catch percentages are reported on the **0–100 scale**;
    /// a bucket's percentage is `nil` when the fielder had zero opportunities.
    ///
    ///     let catches = try await SwiftBaseball.outfieldCatchProbability().season(2024).fetch()
    ///     print(catches.first?.fiveStarCatchPercent)
    public static func outfieldCatchProbability() -> OutfieldCatchProbabilityQuery {
        OutfieldCatchProbabilityQuery(client: statcastClient)
    }

    /// Build a query for the Baseball Savant `outfield_jump` leaderboard.
    ///
    /// Returns one entry per outfielder with reaction, burst, and routing distances
    /// measured against league average (signed feet, positive = better than average),
    /// plus absolute bootup distance covered in the first 3 seconds of pursuit.
    ///
    ///     let jumps = try await SwiftBaseball.outfielderJumps().season(2024).fetch()
    ///     print(jumps.first?.relLeagueBurstDistance)
    public static func outfielderJumps() -> OutfielderJumpsQuery {
        OutfielderJumpsQuery(client: statcastClient)
    }

    /// Build a query for the Baseball Savant `fielding-run-value` leaderboard
    /// (pitcher-centric view).
    ///
    /// The Savant CSV export of this board is **pitcher-centric** — it credits each
    /// pitcher with the cumulative team-defense run value accrued during their
    /// innings (range, arm, double-play, framing, blocking, throwing) rather than
    /// returning each individual fielder's defensive contribution. The method name
    /// reflects this: results describe pitcher contexts, not fielder seasons.
    ///
    ///     let frv = try await SwiftBaseball.pitcherFieldingRunValue().season(2024).fetch()
    ///     print(frv.first?.totalRuns)
    public static func pitcherFieldingRunValue() -> PitcherFieldingRunValueQuery {
        PitcherFieldingRunValueQuery(client: statcastClient)
    }

    /// Build a query for the Baseball Savant `baserunning-run-value` leaderboard.
    ///
    /// Returns one entry per player decomposing baserunning value into extra-base
    /// taking and stolen-base components. Each component carries opportunity counts
    /// and run-value totals. All values are in runs (positive = added value).
    ///
    ///     let brv = try await SwiftBaseball.baserunningRunValue().season(2024).fetch()
    ///     print(brv.first?.runnerRunsTotal)
    ///
    /// - Important: The Savant CSV export defaults to the current season; results
    ///   may not honor `season(_:)` until the upstream filter is fixed.
    public static func baserunningRunValue() -> BaserunningRunValueQuery {
        BaserunningRunValueQuery(client: statcastClient)
    }

    /// Build a query for the Baseball Savant `swing-take` leaderboard.
    ///
    /// Returns one entry per batter with swing-decision run value broken down
    /// across four pitch-location zones — heart (middle), shadow (edges), chase
    /// (just outside), and waste (far outside). Positive values indicate better
    /// decisions than league average.
    ///
    ///     let swing = try await SwiftBaseball.swingTake().season(2024).fetch()
    ///     print(swing.first?.runsHeart, swing.first?.runsChase)
    public static func swingTake() -> SwingTakeQuery {
        SwingTakeQuery(client: statcastClient)
    }

    /// Build a query for the Baseball Savant `spin-direction-pitches` (pitch tilt) leaderboard.
    ///
    /// Returns one entry per (pitcher × pitch type) with both the Hawk-Eye measured
    /// spin axis and the movement-inferred spin axis, expressed as both degrees and
    /// clock-face labels (e.g. `"12:45"`). The gap between the two reveals how much
    /// of a pitch's spin is gyro (non-Magnus).
    ///
    ///     let tilt = try await SwiftBaseball.pitchTilt().season(2024).fetch()
    ///     print(tilt.first?.hawkeyeMeasuredClockLabel, tilt.first?.activeSpinPercent)
    public static func pitchTilt() -> PitchTiltQuery {
        PitchTiltQuery(client: statcastClient)
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

    /// Fetch the full pool of entered prospects for a draft year.
    ///
    ///     let pool = try await SwiftBaseball.draftProspects(year: 2023).fetch()
    ///
    /// Includes both selected and unselected prospects. Earlier drafts return several
    /// thousand entries — iterate the result lazily where possible.
    public static func draftProspects(year: Int) -> QueryBuilder<[DraftProspect]> {
        .draftProspects(year: year, client: client)
    }

    /// Fetch the live in-progress snapshot of a draft.
    ///
    ///     let snapshot = try await SwiftBaseball.draftLatest(year: 2024).fetch()
    ///     print(snapshot.pick?.person?.fullName)
    ///
    /// Useful only while a draft is actively running. Outside the window, `pick` reflects
    /// the final selection of the most recent draft and ``DraftLatest/nextUp`` is empty.
    public static func draftLatest(year: Int) -> QueryBuilder<DraftLatest> {
        .draftLatest(year: year, client: client)
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

    // MARK: - Catalogs (sports / leagues / divisions)

    /// Fetch the MLB Stats API sport catalog.
    ///
    /// Returns every sport the API tracks — Major League Baseball (`id: 1`),
    /// every minor league level, foreign professional leagues (KBO, NPB),
    /// international/Olympic competition, and the Negro Leagues historical
    /// catalog. Use the returned identifiers with ``leagues(sportId:)``,
    /// ``divisions(sportId:)``, or the ``Sport`` enum for query chains.
    ///
    ///     let sports = try await SwiftBaseball.sports().fetch()
    ///     let mlb = sports.first { $0.id == 1 }
    ///     print(mlb?.abbreviation ?? "")   // "MLB"
    ///
    /// - SeeAlso: ``SportCatalog``, ``Sport``, ``leagues(sportId:)``,
    ///   ``divisions(sportId:)``
    public static func sports() -> QueryBuilder<[SportCatalog]> {
        .sports(client: client)
    }

    /// Fetch the league catalog, optionally scoped to a single sport.
    ///
    /// With no argument, returns every league the API tracks across every
    /// sport. Pass `sportId` to scope to one sport — e.g. `1` for MLB
    /// leagues (AL/NL), `11` for Triple-A leagues, etc.
    ///
    ///     let mlbLeagues = try await SwiftBaseball.leagues(sportId: 1).fetch()
    ///     let al = mlbLeagues.first { $0.id == 103 }
    ///     print(al?.seasonDates?.regularSeasonStart ?? Date())
    ///
    /// - Parameter sportId: Optional sport identifier to filter by.
    ///   Use IDs from ``sports()`` or the ``Sport`` enum's `rawValue`.
    /// - SeeAlso: ``LeagueCatalog``, ``League``, ``sports()``
    public static func leagues(sportId: Int? = nil) -> QueryBuilder<[LeagueCatalog]> {
        .leagues(sportId: sportId, client: client)
    }

    /// Fetch the division catalog, optionally scoped to a single sport.
    ///
    /// With no argument, returns every division the API tracks across every
    /// sport. Pass `sportId` to scope to one sport — e.g. `1` for MLB's six
    /// divisions, `11` for Triple-A divisions, etc.
    ///
    ///     let mlbDivisions = try await SwiftBaseball.divisions(sportId: 1).fetch()
    ///     let alEast = mlbDivisions.first { $0.id == 201 }
    ///     print(alEast?.abbreviation ?? "")
    ///
    /// - Parameter sportId: Optional sport identifier to filter by.
    ///   Use IDs from ``sports()`` or the ``Sport`` enum's `rawValue`.
    /// - SeeAlso: ``DivisionCatalog``, ``Division``, ``sports()``
    public static func divisions(sportId: Int? = nil) -> QueryBuilder<[DivisionCatalog]> {
        .divisions(sportId: sportId, client: client)
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

    /// Fetch a team's leaders for a single stat category.
    ///
    /// Returns one ``TeamLeaderCategory`` per (category, stat group) pair.
    /// For stats that exist in both hitting and pitching (home runs,
    /// strikeouts, etc.) the response includes two entries — inspect
    /// ``TeamLeaderCategory/statGroup`` to tell them apart. Chain
    /// `.season(_:)` to restrict to a single year.
    ///
    ///     let hr = try await SwiftBaseball
    ///         .teamLeaders(teamId: 147, category: .homeRuns)
    ///         .season(2024)
    ///         .fetch()
    ///     let batters = hr.first { $0.statGroup == .batting }
    ///     print(batters?.leaders.first?.player.fullName ?? "")   // "Aaron Judge"
    ///
    /// - Parameters:
    ///   - teamId: The MLB team identifier.
    ///   - category: The leader stat category.
    public static func teamLeaders(teamId: Int, category: LeaderStatCategory) -> QueryBuilder<[TeamLeaderCategory]> {
        .teamLeaders(teamId: teamId, category: category, client: client)
    }

    /// Fetch single-game peaks (or troughs) for any player in a season.
    ///
    /// Each ``HighLowSplit`` represents a single game in which a player
    /// posted the n-th highest (or lowest) value of `sortStat`. Use
    /// `direction` to switch between top-of-leaderboard and
    /// bottom-of-leaderboard views.
    ///
    ///     let peaks = try await SwiftBaseball
    ///         .highLowPlayer(group: .batting, sortStat: .homeRuns, season: 2024)
    ///         .limit(10)
    ///         .fetch()
    ///     // peaks.first?.player?.fullName  == "Yordan Alvarez"
    ///     // peaks.first?.statValue         == 3
    ///     // peaks.first?.opponent.name     == "Philadelphia Phillies"
    ///
    /// - Parameters:
    ///   - group: The stat group (`.batting`, `.pitching`, or `.fielding`).
    ///   - sortStat: The leaderboard stat to sort by.
    ///   - season: The season year.
    ///   - direction: `.high` for peaks (default), `.low` for troughs.
    public static func highLowPlayer(
        group: StatGroup,
        sortStat: LeaderStatCategory,
        season: Int,
        direction: HighLowDirection = .high
    ) -> QueryBuilder<[HighLowSplit]> {
        .highLowPlayer(group: group, sortStat: sortStat, season: season, direction: direction, client: client)
    }

    /// Fetch single-game team peaks (or troughs) for a season.
    ///
    /// Each ``HighLowSplit`` represents a single game in which a team posted
    /// the n-th highest (or lowest) value of `sortStat`. Player splits are
    /// `nil` on team-level entries.
    ///
    ///     let teamHRs = try await SwiftBaseball
    ///         .highLowTeam(group: .batting, sortStat: .homeRuns, season: 2024)
    ///         .limit(5)
    ///         .fetch()
    ///     // teamHRs.first?.team.name  == "Oakland Athletics"
    ///     // teamHRs.first?.statValue  == 8   // most HR in any single game in 2024
    ///
    /// - Parameters:
    ///   - group: The stat group (`.batting`, `.pitching`, or `.fielding`).
    ///   - sortStat: The leaderboard stat to sort by.
    ///   - season: The season year.
    ///   - direction: `.high` for peaks (default), `.low` for troughs.
    public static func highLowTeam(
        group: StatGroup,
        sortStat: LeaderStatCategory,
        season: Int,
        direction: HighLowDirection = .high
    ) -> QueryBuilder<[HighLowSplit]> {
        .highLowTeam(group: group, sortStat: sortStat, season: season, direction: direction, client: client)
    }

    // MARK: - Game Pace

    /// Fetch a team's pace-of-play metrics for a season.
    ///
    /// Returns time-per-game, time-per-pitch, plate-appearance counts, and
    /// ancillary pace figures. Time values are ``TimeInterval`` (seconds),
    /// parsed from the upstream API's `H:MM:SS` duration strings.
    ///
    ///     let pace = try await SwiftBaseball.gamePace(teamId: 147, season: 2024).fetch()
    ///     print(pace.timePerGame ?? 0)   // 10173 (i.e. 2h 49m 33s)
    ///     print(pace.pitchesPerGame ?? 0) // 307.67
    ///
    /// - Parameters:
    ///   - teamId: The MLB team identifier.
    ///   - season: The season to aggregate.
    /// - Throws: ``SwiftBaseballError/notFound(_:)`` if no record exists for
    ///   the requested team and season.
    public static func gamePace(teamId: Int, season: Int) -> QueryBuilder<GamePace> {
        .teamGamePace(teamId: teamId, season: season, client: client)
    }

    /// Fetch league-wide MLB pace-of-play metrics for a season.
    ///
    /// Covers every MLB game for the requested year, so per-game averages
    /// here are the natural baseline for comparing a team's pace.
    ///
    ///     let league = try await SwiftBaseball.leagueGamePace(season: 2024).fetch()
    ///     let team = try await SwiftBaseball.gamePace(teamId: 147, season: 2024).fetch()
    ///     let gap = (team.timePerGame ?? 0) - (league.timePerGame ?? 0)
    ///     print("Yankees play \(Int(gap / 60))m longer than the league average")
    ///
    /// - Parameter season: The season to aggregate.
    /// - Throws: ``SwiftBaseballError/notFound(_:)`` if the upstream response
    ///   is missing the expected sport record.
    public static func leagueGamePace(season: Int) -> QueryBuilder<GamePace> {
        .leagueGamePace(season: season, client: client)
    }

    // MARK: - Meta (catalog endpoints)

    /// Catalog/metadata endpoints. Each method returns a top-level array of typed
    /// entries served by `https://statsapi.mlb.com/api/v1/{path}`.
    ///
    ///     let groups = try await SwiftBaseball.meta.statGroups().fetch()
    ///     // [hitting, pitching, fielding, catching, running, ...]
    ///
    ///     let pitches = try await SwiftBaseball.meta.pitchTypes().fetch()
    ///     // [(FA, "Fastball"), (SL, "Slider"), ...]
    ///
    /// These endpoints are static-ish — content rarely changes — and are useful
    /// for power users who need to enumerate everything the upstream API knows
    /// about (situation codes, pitch codes, event types, etc.). Library consumers
    /// targeting only the canonical surface can rely on the typed enums on
    /// SwiftBaseball directly (``GameType``, ``Position``, ``StatGroup``, …).
    public enum Meta {
        public static func statTypes() -> QueryBuilder<[MetaStatType]> {
            .metaCatalog(path: "statTypes", client: SwiftBaseball.client)
        }

        public static func statGroups() -> QueryBuilder<[MetaStatGroup]> {
            .metaCatalog(path: "statGroups", client: SwiftBaseball.client)
        }

        public static func statFields() -> QueryBuilder<[MetaStatField]> {
            .metaCatalog(path: "statFields", client: SwiftBaseball.client)
        }

        public static func leagueLeaderTypes() -> QueryBuilder<[MetaLeagueLeaderType]> {
            .metaCatalog(path: "leagueLeaderTypes", client: SwiftBaseball.client)
        }

        public static func baseballStats() -> QueryBuilder<[MetaBaseballStat]> {
            .metaCatalog(path: "baseballStats", client: SwiftBaseball.client)
        }

        public static func gameTypes() -> QueryBuilder<[MetaGameType]> {
            .metaCatalog(path: "gameTypes", client: SwiftBaseball.client)
        }

        public static func rosterTypes() -> QueryBuilder<[MetaRosterType]> {
            .metaCatalog(path: "rosterTypes", client: SwiftBaseball.client)
        }

        public static func standingsTypes() -> QueryBuilder<[MetaStandingsType]> {
            .metaCatalog(path: "standingsTypes", client: SwiftBaseball.client)
        }

        public static func pitchTypes() -> QueryBuilder<[MetaPitchType]> {
            .metaCatalog(path: "pitchTypes", client: SwiftBaseball.client)
        }

        public static func pitchCodes() -> QueryBuilder<[MetaPitchCode]> {
            .metaCatalog(path: "pitchCodes", client: SwiftBaseball.client)
        }

        public static func eventTypes() -> QueryBuilder<[MetaEventType]> {
            .metaCatalog(path: "eventTypes", client: SwiftBaseball.client)
        }

        public static func situationCodes() -> QueryBuilder<[MetaSituationCode]> {
            .metaCatalog(path: "situationCodes", client: SwiftBaseball.client)
        }

        public static func positions() -> QueryBuilder<[MetaPosition]> {
            .metaCatalog(path: "positions", client: SwiftBaseball.client)
        }

        public static func reviewReasons() -> QueryBuilder<[MetaReviewReason]> {
            .metaCatalog(path: "reviewReasons", client: SwiftBaseball.client)
        }

        public static func hitTrajectories() -> QueryBuilder<[MetaHitTrajectory]> {
            .metaCatalog(path: "hitTrajectories", client: SwiftBaseball.client)
        }

        public static func logicalEvents() -> QueryBuilder<[MetaLogicalEvent]> {
            .metaCatalog(path: "logicalEvents", client: SwiftBaseball.client)
        }

        public static func jobTypes() -> QueryBuilder<[MetaJobType]> {
            .metaCatalog(path: "jobTypes", client: SwiftBaseball.client)
        }

        public static func languages() -> QueryBuilder<[MetaLanguage]> {
            .metaCatalog(path: "languages", client: SwiftBaseball.client)
        }
    }

    /// Entry point for catalog/metadata endpoints. Returns the ``Meta`` namespace,
    /// which exposes one method per upstream catalog (`statTypes`, `pitchCodes`, etc.).
    public static var meta: Meta.Type { Meta.self }
}
