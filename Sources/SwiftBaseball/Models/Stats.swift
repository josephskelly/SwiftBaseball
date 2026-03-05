import Foundation

// MARK: - Batting

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
}

// MARK: - Pitching

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
}

// MARK: - Fielding

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
}

// MARK: - Player season stats wrapper

public struct PlayerSeasonStats: Codable, Sendable, Equatable {
    public let player: PlayerReference
    public let team: TeamReference?
    public let season: String
    public let group: StatGroup
    public let batting: BattingStats?
    public let pitching: PitchingStats?
    public let fielding: FieldingStats?
}
