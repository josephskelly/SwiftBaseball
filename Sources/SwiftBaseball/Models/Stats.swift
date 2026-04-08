import Foundation

// MARK: - Batting

/// Batting statistics for a player or team.
///
/// All counting stats and rate stats are optional to handle partial data from the API.
/// Rate stats (``avg``, ``obp``, ``slg``, ``ops``, ``babip``) are decoded from
/// both string and numeric API formats.
public struct BattingStats: Codable, Sendable, Equatable {
    public let gamesPlayed: Int?
    public let plateAppearances: Int?
    public let atBats: Int?
    public let runs: Int?
    public let hits: Int?
    public let doubles: Int?
    public let triples: Int?
    public let homeRuns: Int?
    public let rbi: Int?
    public let stolenBases: Int?
    public let caughtStealing: Int?
    public let baseOnBalls: Int?
    public let intentionalWalks: Int?
    public let strikeOuts: Int?
    public let hitByPitch: Int?
    public let sacFlies: Int?
    public let sacBunts: Int?
    public let groundIntoDoublePlay: Int?
    public let totalBases: Int?
    public let leftOnBase: Int?

    // MARK: - Computed

    /// wOBA computed from counting stats using FanGraphs linear weights.
    ///
    /// Uses approximate career-era averages (wBB=0.696, wHBP=0.726, w1B=0.883,
    /// w2B=1.244, w3B=1.569, wHR=2.007). Returns `nil` if any required field is `nil`
    /// or the denominator is zero.
    ///
    /// - Note: This is a counting-stat approximation. For contact quality–adjusted
    ///   wOBA from Statcast, use ``StatcastCareerSplits``.
    public var woba: Double? {
        guard let ab = atBats, let h = hits, let d = doubles, let t = triples,
              let hr = homeRuns, let bb = baseOnBalls, let ibb = intentionalWalks,
              let hbp = hitByPitch, let sf = sacFlies else { return nil }
        let singles = h - d - t - hr
        let ubb = bb - ibb
        let num = 0.696 * Double(ubb) + 0.726 * Double(hbp) + 0.883 * Double(singles)
                + 1.244 * Double(d) + 1.569 * Double(t) + 2.007 * Double(hr)
        let den = Double(ab + ubb + sf + hbp)
        guard den > 0 else { return nil }
        return num / den
    }

    // Rate stats — encoded as strings in MLB API ("0.310")
    public let avg: Double?
    public let obp: Double?
    public let slg: Double?
    public let ops: Double?
    public let babip: Double?

    enum CodingKeys: String, CodingKey {
        case gamesPlayed, plateAppearances, atBats, runs, hits
        case doubles, triples, homeRuns, rbi
        case stolenBases, caughtStealing, baseOnBalls, intentionalWalks
        case strikeOuts, hitByPitch, sacFlies, sacBunts
        case groundIntoDoublePlay, totalBases, leftOnBase
        case avg, obp, slg, ops, babip
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        gamesPlayed         = try c.decodeIfPresent(Int.self, forKey: .gamesPlayed)
        plateAppearances    = try c.decodeIfPresent(Int.self, forKey: .plateAppearances)
        atBats              = try c.decodeIfPresent(Int.self, forKey: .atBats)
        runs                = try c.decodeIfPresent(Int.self, forKey: .runs)
        hits                = try c.decodeIfPresent(Int.self, forKey: .hits)
        doubles             = try c.decodeIfPresent(Int.self, forKey: .doubles)
        triples             = try c.decodeIfPresent(Int.self, forKey: .triples)
        homeRuns            = try c.decodeIfPresent(Int.self, forKey: .homeRuns)
        rbi                 = try c.decodeIfPresent(Int.self, forKey: .rbi)
        stolenBases         = try c.decodeIfPresent(Int.self, forKey: .stolenBases)
        caughtStealing      = try c.decodeIfPresent(Int.self, forKey: .caughtStealing)
        baseOnBalls         = try c.decodeIfPresent(Int.self, forKey: .baseOnBalls)
        intentionalWalks    = try c.decodeIfPresent(Int.self, forKey: .intentionalWalks)
        strikeOuts          = try c.decodeIfPresent(Int.self, forKey: .strikeOuts)
        hitByPitch          = try c.decodeIfPresent(Int.self, forKey: .hitByPitch)
        sacFlies            = try c.decodeIfPresent(Int.self, forKey: .sacFlies)
        sacBunts            = try c.decodeIfPresent(Int.self, forKey: .sacBunts)
        groundIntoDoublePlay = try c.decodeIfPresent(Int.self, forKey: .groundIntoDoublePlay)
        totalBases          = try c.decodeIfPresent(Int.self, forKey: .totalBases)
        leftOnBase          = try c.decodeIfPresent(Int.self, forKey: .leftOnBase)

        // MLB API returns rate stats as strings like ".310" or "1.036"
        avg   = try Self.decodeStatString(c, key: .avg)
        obp   = try Self.decodeStatString(c, key: .obp)
        slg   = try Self.decodeStatString(c, key: .slg)
        ops   = try Self.decodeStatString(c, key: .ops)
        babip = try Self.decodeStatString(c, key: .babip)
    }

    private static func decodeStatString(
        _ c: KeyedDecodingContainer<CodingKeys>,
        key: CodingKeys
    ) throws -> Double? {
        if let d = try? c.decodeIfPresent(Double.self, forKey: key) { return d }
        if let s = try? c.decodeIfPresent(String.self, forKey: key) { return Double(s) }
        return nil
    }

    /// An empty batting stats instance with all properties set to `nil`.
    static let empty = BattingStats(
        gamesPlayed: nil, plateAppearances: nil, atBats: nil, runs: nil,
        hits: nil, doubles: nil, triples: nil, homeRuns: nil, rbi: nil,
        stolenBases: nil, caughtStealing: nil, baseOnBalls: nil,
        intentionalWalks: nil, strikeOuts: nil, hitByPitch: nil,
        sacFlies: nil, sacBunts: nil, groundIntoDoublePlay: nil,
        totalBases: nil, leftOnBase: nil,
        avg: nil, obp: nil, slg: nil, ops: nil, babip: nil
    )

    init(
        gamesPlayed: Int?, plateAppearances: Int?, atBats: Int?, runs: Int?,
        hits: Int?, doubles: Int?, triples: Int?, homeRuns: Int?, rbi: Int?,
        stolenBases: Int?, caughtStealing: Int?, baseOnBalls: Int?,
        intentionalWalks: Int?, strikeOuts: Int?, hitByPitch: Int?,
        sacFlies: Int?, sacBunts: Int?, groundIntoDoublePlay: Int?,
        totalBases: Int?, leftOnBase: Int?,
        avg: Double?, obp: Double?, slg: Double?, ops: Double?, babip: Double?
    ) {
        self.gamesPlayed = gamesPlayed
        self.plateAppearances = plateAppearances
        self.atBats = atBats
        self.runs = runs
        self.hits = hits
        self.doubles = doubles
        self.triples = triples
        self.homeRuns = homeRuns
        self.rbi = rbi
        self.stolenBases = stolenBases
        self.caughtStealing = caughtStealing
        self.baseOnBalls = baseOnBalls
        self.intentionalWalks = intentionalWalks
        self.strikeOuts = strikeOuts
        self.hitByPitch = hitByPitch
        self.sacFlies = sacFlies
        self.sacBunts = sacBunts
        self.groundIntoDoublePlay = groundIntoDoublePlay
        self.totalBases = totalBases
        self.leftOnBase = leftOnBase
        self.avg = avg
        self.obp = obp
        self.slg = slg
        self.ops = ops
        self.babip = babip
    }
}

// MARK: - Pitching

/// Pitching statistics for a player or team.
///
/// Rate stats (``era``, ``whip``, ``avg``, ``inningsPitched``) are decoded from
/// both string and numeric API formats.
public struct PitchingStats: Codable, Sendable, Equatable {
    public let gamesPlayed: Int?
    public let gamesStarted: Int?
    public let wins: Int?
    public let losses: Int?
    public let saves: Int?
    public let saveOpportunities: Int?
    public let holds: Int?
    public let blownSaves: Int?
    public let completeGames: Int?
    public let shutouts: Int?
    public let hits: Int?
    public let doubles: Int?
    public let triples: Int?
    public let runs: Int?
    public let earnedRuns: Int?
    public let homeRuns: Int?
    public let atBats: Int?
    public let baseOnBalls: Int?
    public let intentionalWalks: Int?
    public let strikeOuts: Int?
    public let hitByPitch: Int?
    public let sacFlies: Int?
    public let wildPitches: Int?
    public let balks: Int?
    public let battersFaced: Int?
    /// Total pitches thrown. Populated on game-log responses (`gameLog` group `pitching`)
    /// and season totals when the API includes it; `nil` on platoon split rows.
    public let numberOfPitches: Int?

    // MARK: - Computed

    /// wOBA-against computed from counting stats using FanGraphs linear weights.
    ///
    /// Uses the same formula as ``BattingStats/woba`` applied to opposing-batter stats.
    /// Returns `nil` if `atBats`, `doubles`, `triples`, `sacFlies`, or any other
    /// required field is `nil`, or if the denominator is zero.
    ///
    /// - Note: `atBats`, `doubles`, `triples`, and `sacFlies` are only present on
    ///   platoon-split responses (`pitcherCareerPlatoonStats` / `pitcherStatSplits`),
    ///   not on standard season-total pitching lines.
    public var wobaAgainst: Double? {
        guard let ab = atBats, let h = hits, let d = doubles, let t = triples,
              let hr = homeRuns, let bb = baseOnBalls, let ibb = intentionalWalks,
              let hbp = hitByPitch, let sf = sacFlies else { return nil }
        let singles = h - d - t - hr
        let ubb = bb - ibb
        let num = 0.696 * Double(ubb) + 0.726 * Double(hbp) + 0.883 * Double(singles)
                + 1.244 * Double(d) + 1.569 * Double(t) + 2.007 * Double(hr)
        let den = Double(ab + ubb + sf + hbp)
        guard den > 0 else { return nil }
        return num / den
    }

    // Rate stats
    public let era: Double?
    public let whip: Double?
    public let avg: Double?

    /// On-base percentage against.
    public let obp: Double?
    /// Slugging percentage against.
    public let slg: Double?
    /// OPS against.
    public let ops: Double?

    public let inningsPitched: Double?

    enum CodingKeys: String, CodingKey {
        case gamesPlayed, gamesStarted, wins, losses
        case saves, saveOpportunities, holds, blownSaves
        case completeGames, shutouts, hits, doubles, triples, runs, earnedRuns
        case homeRuns, atBats, baseOnBalls, intentionalWalks, strikeOuts
        case hitByPitch, sacFlies, wildPitches, balks, battersFaced
        case numberOfPitches
        case era, whip, avg, obp, slg, ops, inningsPitched
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        gamesPlayed       = try c.decodeIfPresent(Int.self, forKey: .gamesPlayed)
        gamesStarted      = try c.decodeIfPresent(Int.self, forKey: .gamesStarted)
        wins              = try c.decodeIfPresent(Int.self, forKey: .wins)
        losses            = try c.decodeIfPresent(Int.self, forKey: .losses)
        saves             = try c.decodeIfPresent(Int.self, forKey: .saves)
        saveOpportunities = try c.decodeIfPresent(Int.self, forKey: .saveOpportunities)
        holds             = try c.decodeIfPresent(Int.self, forKey: .holds)
        blownSaves        = try c.decodeIfPresent(Int.self, forKey: .blownSaves)
        completeGames     = try c.decodeIfPresent(Int.self, forKey: .completeGames)
        shutouts          = try c.decodeIfPresent(Int.self, forKey: .shutouts)
        hits              = try c.decodeIfPresent(Int.self, forKey: .hits)
        doubles           = try c.decodeIfPresent(Int.self, forKey: .doubles)
        triples           = try c.decodeIfPresent(Int.self, forKey: .triples)
        runs              = try c.decodeIfPresent(Int.self, forKey: .runs)
        earnedRuns        = try c.decodeIfPresent(Int.self, forKey: .earnedRuns)
        homeRuns          = try c.decodeIfPresent(Int.self, forKey: .homeRuns)
        atBats            = try c.decodeIfPresent(Int.self, forKey: .atBats)
        baseOnBalls       = try c.decodeIfPresent(Int.self, forKey: .baseOnBalls)
        intentionalWalks  = try c.decodeIfPresent(Int.self, forKey: .intentionalWalks)
        strikeOuts        = try c.decodeIfPresent(Int.self, forKey: .strikeOuts)
        hitByPitch        = try c.decodeIfPresent(Int.self, forKey: .hitByPitch)
        sacFlies          = try c.decodeIfPresent(Int.self, forKey: .sacFlies)
        wildPitches       = try c.decodeIfPresent(Int.self, forKey: .wildPitches)
        balks             = try c.decodeIfPresent(Int.self, forKey: .balks)
        battersFaced      = try c.decodeIfPresent(Int.self, forKey: .battersFaced)
        numberOfPitches   = try c.decodeIfPresent(Int.self, forKey: .numberOfPitches)

        era             = try Self.decodeStatString(c, key: .era)
        whip            = try Self.decodeStatString(c, key: .whip)
        avg             = try Self.decodeStatString(c, key: .avg)
        obp             = try Self.decodeStatString(c, key: .obp)
        slg             = try Self.decodeStatString(c, key: .slg)
        ops             = try Self.decodeStatString(c, key: .ops)
        inningsPitched  = try Self.decodeStatString(c, key: .inningsPitched)
    }

    private static func decodeStatString(
        _ c: KeyedDecodingContainer<CodingKeys>,
        key: CodingKeys
    ) throws -> Double? {
        if let d = try? c.decodeIfPresent(Double.self, forKey: key) { return d }
        if let s = try? c.decodeIfPresent(String.self, forKey: key) { return Double(s) }
        return nil
    }

    /// An empty pitching stats instance with all properties set to `nil`.
    static let empty = PitchingStats(
        gamesPlayed: nil, gamesStarted: nil, wins: nil, losses: nil,
        saves: nil, saveOpportunities: nil, holds: nil, blownSaves: nil,
        completeGames: nil, shutouts: nil, hits: nil, doubles: nil, triples: nil,
        runs: nil, earnedRuns: nil, homeRuns: nil, atBats: nil, baseOnBalls: nil,
        intentionalWalks: nil, strikeOuts: nil, hitByPitch: nil, sacFlies: nil,
        wildPitches: nil, balks: nil, battersFaced: nil,
        numberOfPitches: nil,
        era: nil, whip: nil, avg: nil,
        obp: nil, slg: nil, ops: nil, inningsPitched: nil
    )

    init(
        gamesPlayed: Int?, gamesStarted: Int?, wins: Int?, losses: Int?,
        saves: Int?, saveOpportunities: Int?, holds: Int?, blownSaves: Int?,
        completeGames: Int?, shutouts: Int?, hits: Int?, doubles: Int?, triples: Int?,
        runs: Int?, earnedRuns: Int?, homeRuns: Int?, atBats: Int?, baseOnBalls: Int?,
        intentionalWalks: Int?, strikeOuts: Int?, hitByPitch: Int?, sacFlies: Int?,
        wildPitches: Int?, balks: Int?, battersFaced: Int?,
        numberOfPitches: Int?,
        era: Double?, whip: Double?, avg: Double?,
        obp: Double?, slg: Double?, ops: Double?,
        inningsPitched: Double?
    ) {
        self.gamesPlayed = gamesPlayed
        self.gamesStarted = gamesStarted
        self.wins = wins
        self.losses = losses
        self.saves = saves
        self.saveOpportunities = saveOpportunities
        self.holds = holds
        self.blownSaves = blownSaves
        self.completeGames = completeGames
        self.shutouts = shutouts
        self.hits = hits
        self.doubles = doubles
        self.triples = triples
        self.runs = runs
        self.earnedRuns = earnedRuns
        self.homeRuns = homeRuns
        self.atBats = atBats
        self.baseOnBalls = baseOnBalls
        self.intentionalWalks = intentionalWalks
        self.strikeOuts = strikeOuts
        self.hitByPitch = hitByPitch
        self.sacFlies = sacFlies
        self.wildPitches = wildPitches
        self.balks = balks
        self.battersFaced = battersFaced
        self.numberOfPitches = numberOfPitches
        self.era = era
        self.whip = whip
        self.avg = avg
        self.obp = obp
        self.slg = slg
        self.ops = ops
        self.inningsPitched = inningsPitched
    }
}

// MARK: - Fielding

/// Fielding/defensive statistics for a player or team.
public struct FieldingStats: Codable, Sendable, Equatable {
    public let gamesPlayed: Int?
    public let gamesStarted: Int?
    public let assists: Int?
    public let putOuts: Int?
    public let errors: Int?
    public let chances: Int?
    public let doublePlays: Int?
    public let triplePlays: Int?
    public let passedBalls: Int?
    public let innings: Double?
    public let fielding: Double?

    enum CodingKeys: String, CodingKey {
        case gamesPlayed, gamesStarted, assists, putOuts, errors
        case chances, doublePlays, triplePlays, passedBalls
        case innings, fielding
    }

    public init(from decoder: any Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        gamesPlayed  = try c.decodeIfPresent(Int.self, forKey: .gamesPlayed)
        gamesStarted = try c.decodeIfPresent(Int.self, forKey: .gamesStarted)
        assists      = try c.decodeIfPresent(Int.self, forKey: .assists)
        putOuts      = try c.decodeIfPresent(Int.self, forKey: .putOuts)
        errors       = try c.decodeIfPresent(Int.self, forKey: .errors)
        chances      = try c.decodeIfPresent(Int.self, forKey: .chances)
        doublePlays  = try c.decodeIfPresent(Int.self, forKey: .doublePlays)
        triplePlays  = try c.decodeIfPresent(Int.self, forKey: .triplePlays)
        passedBalls  = try c.decodeIfPresent(Int.self, forKey: .passedBalls)

        if let d = try? c.decodeIfPresent(Double.self, forKey: .innings) { innings = d }
        else if let s = try? c.decodeIfPresent(String.self, forKey: .innings) { innings = Double(s) }
        else { innings = nil }

        if let d = try? c.decodeIfPresent(Double.self, forKey: .fielding) { fielding = d }
        else if let s = try? c.decodeIfPresent(String.self, forKey: .fielding) { fielding = Double(s) }
        else { fielding = nil }
    }

    /// An empty fielding stats instance with all properties set to `nil`.
    static let empty = FieldingStats(
        gamesPlayed: nil, gamesStarted: nil, assists: nil, putOuts: nil,
        errors: nil, chances: nil, doublePlays: nil, triplePlays: nil,
        passedBalls: nil, innings: nil, fielding: nil
    )

    init(
        gamesPlayed: Int?, gamesStarted: Int?, assists: Int?, putOuts: Int?,
        errors: Int?, chances: Int?, doublePlays: Int?, triplePlays: Int?,
        passedBalls: Int?, innings: Double?, fielding: Double?
    ) {
        self.gamesPlayed = gamesPlayed
        self.gamesStarted = gamesStarted
        self.assists = assists
        self.putOuts = putOuts
        self.errors = errors
        self.chances = chances
        self.doublePlays = doublePlays
        self.triplePlays = triplePlays
        self.passedBalls = passedBalls
        self.innings = innings
        self.fielding = fielding
    }
}

// MARK: - Sabermetrics

/// Advanced sabermetric statistics from the MLB Stats API.
///
/// Includes WAR components (offensive, defensive, baserunning, positional adjustment)
/// and other derived metrics like wOBA, wRC+, and speed score.
public struct SabermetricStats: Codable, Sendable, Equatable {
    /// Weighted on-base average.
    public let woba: Double?
    /// Weighted runs above average.
    public let wRaa: Double?
    /// Weighted runs created.
    public let wRc: Double?
    /// Weighted runs created plus (league-adjusted, 100 = average).
    public let wRcPlus: Double?
    /// Runs above replacement.
    public let rar: Double?
    /// Wins above replacement.
    public let war: Double?
    /// Batting runs (offensive component of WAR).
    public let batting: Double?
    /// Fielding runs (defensive component of WAR).
    public let fielding: Double?
    /// Baserunning runs (baserunning component of WAR).
    public let baseRunning: Double?
    /// Positional adjustment runs.
    public let positional: Double?
    /// League adjustment runs.
    public let wLeague: Double?
    /// Replacement-level runs.
    public let replacement: Double?
    /// Speed score.
    public let spd: Double?
    /// Ultimate base running (non-SB component).
    public let ubr: Double?
    /// Weighted grounded-into-double-play runs.
    public let wGdp: Double?
    /// Weighted stolen base runs.
    public let wSb: Double?

    /// An empty sabermetric stats instance with all properties set to `nil`.
    static let empty = SabermetricStats(
        woba: nil, wRaa: nil, wRc: nil, wRcPlus: nil,
        rar: nil, war: nil, batting: nil, fielding: nil,
        baseRunning: nil, positional: nil, wLeague: nil,
        replacement: nil, spd: nil, ubr: nil, wGdp: nil, wSb: nil
    )

    init(
        woba: Double?, wRaa: Double?, wRc: Double?, wRcPlus: Double?,
        rar: Double?, war: Double?, batting: Double?, fielding: Double?,
        baseRunning: Double?, positional: Double?, wLeague: Double?,
        replacement: Double?, spd: Double?, ubr: Double?, wGdp: Double?,
        wSb: Double?
    ) {
        self.woba = woba
        self.wRaa = wRaa
        self.wRc = wRc
        self.wRcPlus = wRcPlus
        self.rar = rar
        self.war = war
        self.batting = batting
        self.fielding = fielding
        self.baseRunning = baseRunning
        self.positional = positional
        self.wLeague = wLeague
        self.replacement = replacement
        self.spd = spd
        self.ubr = ubr
        self.wGdp = wGdp
        self.wSb = wSb
    }
}

// MARK: - Player season stats wrapper

/// Aggregated stats for a player in a single season, broken down by stat group.
/// Aggregated statistics for a player for a single season (or career/projected).
///
/// Returned by ``SwiftBaseball/playerStats(id:)``, ``SwiftBaseball/playerCareerStats(id:)``,
/// ``SwiftBaseball/playerYearByYear(id:)``, and related queries.
///
/// For minor league stats, chain `.sport(_:)` on the query:
///
///     let aaaStats = try await SwiftBaseball.playerStats(id: 605141)
///         .season(2024).group(.batting).sport(.tripleA).fetch()
///
/// ``sport`` and ``league`` identify the competition level when a result set
/// mixes entries from multiple levels (e.g. a `yearByYear` query scoped to
/// a specific sport).
public struct PlayerSeasonStats: Codable, Sendable, Equatable {
    /// The player these stats belong to.
    public let player: PlayerReference
    /// The team the player was on when these stats were accumulated.
    public let team: TeamReference?
    /// The season year string (e.g. `"2024"`), or `""` for career totals.
    public let season: String
    /// The stat category group (batting, pitching, or fielding).
    public let group: StatGroup
    public let batting: BattingStats?
    public let pitching: PitchingStats?
    public let fielding: FieldingStats?
    public let sabermetrics: SabermetricStats?
    /// The competition level for these stats (e.g. ``Sport/tripleA``).
    /// `nil` when the API response does not include a sport field (MLB default).
    public let sport: Sport?
    /// The league these stats were accumulated in (e.g. International League).
    /// `nil` when the API response does not include a league field.
    public let league: LeagueReference?
}

// MARK: - Platoon splits

/// Batting stats split by handedness of the opposing pitcher.
public struct PlayerPlatoonStats: Sendable, Equatable {
    /// Stats vs left-handed pitchers.
    public let vsLeft: BattingStats?
    /// Stats vs right-handed pitchers.
    public let vsRight: BattingStats?

    public init(vsLeft: BattingStats?, vsRight: BattingStats?) {
        self.vsLeft = vsLeft
        self.vsRight = vsRight
    }
}

/// Pitching stats split by handedness of the opposing batter.
public struct PitcherPlatoonStats: Sendable, Equatable {
    /// Stats vs left-handed batters.
    public let vsLeft: PitchingStats?
    /// Stats vs right-handed batters.
    public let vsRight: PitchingStats?

    public init(vsLeft: PitchingStats?, vsRight: PitchingStats?) {
        self.vsLeft = vsLeft
        self.vsRight = vsRight
    }
}

// MARK: - Career platoon splits

/// Career-aggregated batting splits by opposing pitcher handedness.
///
/// Returned by ``SwiftBaseball/playerCareerPlatoonStats(id:)`` using the
/// `careerStatSplits` MLB Stats API endpoint, which pre-aggregates all plate
/// appearances across a player's entire MLB career into a single `vl` and `vr`
/// row — no client-side season aggregation required.
public struct PlayerCareerPlatoonStats: Sendable, Equatable {
    /// Career stats vs left-handed pitchers.
    public let vsLeft: BattingStats?
    /// Career stats vs right-handed pitchers.
    public let vsRight: BattingStats?

    public init(vsLeft: BattingStats?, vsRight: BattingStats?) {
        self.vsLeft = vsLeft
        self.vsRight = vsRight
    }
}

/// Career-aggregated pitching splits by opposing batter handedness.
///
/// Returned by ``SwiftBaseball/pitcherCareerPlatoonStats(id:)`` using the
/// `careerStatSplits` MLB Stats API endpoint, which pre-aggregates all batters
/// faced across a pitcher's entire MLB career into a single `vl` and `vr` row.
public struct PitcherCareerPlatoonStats: Sendable, Equatable {
    /// Career stats vs left-handed batters.
    public let vsLeft: PitchingStats?
    /// Career stats vs right-handed batters.
    public let vsRight: PitchingStats?

    public init(vsLeft: PitchingStats?, vsRight: PitchingStats?) {
        self.vsLeft = vsLeft
        self.vsRight = vsRight
    }
}

// MARK: - Home/Away splits

/// Batting stats split by home vs away games.
public struct PlayerHomeAwaySplits: Sendable, Equatable {
    /// Stats in home games.
    public let home: BattingStats?
    /// Stats in away games.
    public let away: BattingStats?

    public init(home: BattingStats?, away: BattingStats?) {
        self.home = home
        self.away = away
    }
}

/// Pitching stats split by home vs away games.
public struct PitcherHomeAwaySplits: Sendable, Equatable {
    /// Stats in home games.
    public let home: PitchingStats?
    /// Stats in away games.
    public let away: PitchingStats?

    public init(home: PitchingStats?, away: PitchingStats?) {
        self.home = home
        self.away = away
    }
}

// MARK: - Day/Night splits

/// Batting stats split by day vs night games.
public struct PlayerDayNightSplits: Sendable, Equatable {
    /// Stats in day games.
    public let day: BattingStats?
    /// Stats in night games.
    public let night: BattingStats?

    public init(day: BattingStats?, night: BattingStats?) {
        self.day = day
        self.night = night
    }
}

/// Pitching stats split by day vs night games.
public struct PitcherDayNightSplits: Sendable, Equatable {
    /// Stats in day games.
    public let day: PitchingStats?
    /// Stats in night games.
    public let night: PitchingStats?

    public init(day: PitchingStats?, night: PitchingStats?) {
        self.day = day
        self.night = night
    }
}

// MARK: - Monthly Splits

/// Batting stats broken down by calendar month across the season.
public struct PlayerMonthlySplits: Sendable, Equatable {
    /// Stats in March (and any March games).
    public let march: BattingStats?
    /// Stats in April.
    public let april: BattingStats?
    /// Stats in May.
    public let may: BattingStats?
    /// Stats in June.
    public let june: BattingStats?
    /// Stats in July.
    public let july: BattingStats?
    /// Stats in August.
    public let august: BattingStats?
    /// Stats in September.
    public let september: BattingStats?
    /// Stats in October (postseason / late-season games).
    public let october: BattingStats?

    public init(
        march: BattingStats?,
        april: BattingStats?,
        may: BattingStats?,
        june: BattingStats?,
        july: BattingStats?,
        august: BattingStats?,
        september: BattingStats?,
        october: BattingStats?
    ) {
        self.march = march
        self.april = april
        self.may = may
        self.june = june
        self.july = july
        self.august = august
        self.september = september
        self.october = october
    }
}

/// Pitching stats broken down by calendar month across the season.
public struct PitcherMonthlySplits: Sendable, Equatable {
    /// Stats in March.
    public let march: PitchingStats?
    /// Stats in April.
    public let april: PitchingStats?
    /// Stats in May.
    public let may: PitchingStats?
    /// Stats in June.
    public let june: PitchingStats?
    /// Stats in July.
    public let july: PitchingStats?
    /// Stats in August.
    public let august: PitchingStats?
    /// Stats in September.
    public let september: PitchingStats?
    /// Stats in October.
    public let october: PitchingStats?

    public init(
        march: PitchingStats?,
        april: PitchingStats?,
        may: PitchingStats?,
        june: PitchingStats?,
        july: PitchingStats?,
        august: PitchingStats?,
        september: PitchingStats?,
        october: PitchingStats?
    ) {
        self.march = march
        self.april = april
        self.may = may
        self.june = june
        self.july = july
        self.august = august
        self.september = september
        self.october = october
    }
}

// MARK: - Runners On Base / RISP Splits

/// Batting stats split by baserunner situation.
public struct PlayerRunnersOnSplits: Sendable, Equatable {
    /// Stats with bases empty.
    public let basesEmpty: BattingStats?
    /// Stats with at least one runner on base.
    public let runnersOn: BattingStats?
    /// Stats with runners in scoring position (2nd or 3rd).
    public let risp: BattingStats?
    /// Stats with runners in scoring position and two outs.
    public let rispTwoOut: BattingStats?

    public init(
        basesEmpty: BattingStats?,
        runnersOn: BattingStats?,
        risp: BattingStats?,
        rispTwoOut: BattingStats?
    ) {
        self.basesEmpty = basesEmpty
        self.runnersOn = runnersOn
        self.risp = risp
        self.rispTwoOut = rispTwoOut
    }
}

/// Pitching stats split by baserunner situation.
public struct PitcherRunnersOnSplits: Sendable, Equatable {
    /// Stats with bases empty.
    public let basesEmpty: PitchingStats?
    /// Stats with at least one runner on base.
    public let runnersOn: PitchingStats?
    /// Stats with runners in scoring position (2nd or 3rd).
    public let risp: PitchingStats?
    /// Stats with runners in scoring position and two outs.
    public let rispTwoOut: PitchingStats?

    public init(
        basesEmpty: PitchingStats?,
        runnersOn: PitchingStats?,
        risp: PitchingStats?,
        rispTwoOut: PitchingStats?
    ) {
        self.basesEmpty = basesEmpty
        self.runnersOn = runnersOn
        self.risp = risp
        self.rispTwoOut = rispTwoOut
    }
}

// MARK: - Leverage Splits

/// Batting stats split by leverage index (game situation pressure).
public struct PlayerLeverageSplits: Sendable, Equatable {
    /// Stats in low-leverage situations.
    public let low: BattingStats?
    /// Stats in medium-leverage situations.
    public let medium: BattingStats?
    /// Stats in high-leverage situations.
    public let high: BattingStats?

    public init(low: BattingStats?, medium: BattingStats?, high: BattingStats?) {
        self.low = low
        self.medium = medium
        self.high = high
    }
}

/// Pitching stats split by leverage index (game situation pressure).
public struct PitcherLeverageSplits: Sendable, Equatable {
    /// Stats in low-leverage situations.
    public let low: PitchingStats?
    /// Stats in medium-leverage situations.
    public let medium: PitchingStats?
    /// Stats in high-leverage situations.
    public let high: PitchingStats?

    public init(low: PitchingStats?, medium: PitchingStats?, high: PitchingStats?) {
        self.low = low
        self.medium = medium
        self.high = high
    }
}
