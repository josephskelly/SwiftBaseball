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
    public let runs: Int?
    public let earnedRuns: Int?
    public let homeRuns: Int?
    public let baseOnBalls: Int?
    public let intentionalWalks: Int?
    public let strikeOuts: Int?
    public let hitByPitch: Int?
    public let wildPitches: Int?
    public let balks: Int?
    public let battersFaced: Int?

    // Rate stats
    public let era: Double?
    public let whip: Double?
    public let avg: Double?
    public let inningsPitched: Double?

    enum CodingKeys: String, CodingKey {
        case gamesPlayed, gamesStarted, wins, losses
        case saves, saveOpportunities, holds, blownSaves
        case completeGames, shutouts, hits, runs, earnedRuns
        case homeRuns, baseOnBalls, intentionalWalks, strikeOuts
        case hitByPitch, wildPitches, balks, battersFaced
        case era, whip, avg, inningsPitched
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
        runs              = try c.decodeIfPresent(Int.self, forKey: .runs)
        earnedRuns        = try c.decodeIfPresent(Int.self, forKey: .earnedRuns)
        homeRuns          = try c.decodeIfPresent(Int.self, forKey: .homeRuns)
        baseOnBalls       = try c.decodeIfPresent(Int.self, forKey: .baseOnBalls)
        intentionalWalks  = try c.decodeIfPresent(Int.self, forKey: .intentionalWalks)
        strikeOuts        = try c.decodeIfPresent(Int.self, forKey: .strikeOuts)
        hitByPitch        = try c.decodeIfPresent(Int.self, forKey: .hitByPitch)
        wildPitches       = try c.decodeIfPresent(Int.self, forKey: .wildPitches)
        balks             = try c.decodeIfPresent(Int.self, forKey: .balks)
        battersFaced      = try c.decodeIfPresent(Int.self, forKey: .battersFaced)

        era             = try Self.decodeStatString(c, key: .era)
        whip            = try Self.decodeStatString(c, key: .whip)
        avg             = try Self.decodeStatString(c, key: .avg)
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
        completeGames: nil, shutouts: nil, hits: nil, runs: nil,
        earnedRuns: nil, homeRuns: nil, baseOnBalls: nil,
        intentionalWalks: nil, strikeOuts: nil, hitByPitch: nil,
        wildPitches: nil, balks: nil, battersFaced: nil,
        era: nil, whip: nil, avg: nil, inningsPitched: nil
    )

    init(
        gamesPlayed: Int?, gamesStarted: Int?, wins: Int?, losses: Int?,
        saves: Int?, saveOpportunities: Int?, holds: Int?, blownSaves: Int?,
        completeGames: Int?, shutouts: Int?, hits: Int?, runs: Int?,
        earnedRuns: Int?, homeRuns: Int?, baseOnBalls: Int?,
        intentionalWalks: Int?, strikeOuts: Int?, hitByPitch: Int?,
        wildPitches: Int?, balks: Int?, battersFaced: Int?,
        era: Double?, whip: Double?, avg: Double?, inningsPitched: Double?
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
        self.runs = runs
        self.earnedRuns = earnedRuns
        self.homeRuns = homeRuns
        self.baseOnBalls = baseOnBalls
        self.intentionalWalks = intentionalWalks
        self.strikeOuts = strikeOuts
        self.hitByPitch = hitByPitch
        self.wildPitches = wildPitches
        self.balks = balks
        self.battersFaced = battersFaced
        self.era = era
        self.whip = whip
        self.avg = avg
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

// MARK: - Player season stats wrapper

/// Aggregated stats for a player in a single season, broken down by stat group.
public struct PlayerSeasonStats: Codable, Sendable, Equatable {
    public let player: PlayerReference
    public let team: TeamReference?
    public let season: String
    public let group: StatGroup
    public let batting: BattingStats?
    public let pitching: PitchingStats?
    public let fielding: FieldingStats?
}
