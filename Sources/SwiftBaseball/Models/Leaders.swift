import Foundation

public struct LeaderEntry: Codable, Sendable, Equatable {
    public let rank: Int
    public let value: String
    public let player: PlayerReference
    public let team: TeamReference?
    public let season: String?
    public let leagueRank: Int?
}

public struct LeaderCategory: Codable, Sendable, Equatable {
    public let leaderCategory: String
    public let leaders: [LeaderEntry]
}

// MARK: - Common stat categories

public enum LeaderStatCategory: String, Codable, Sendable, CaseIterable {
    // Batting
    case homeRuns             = "homeRuns"
    case battingAverage       = "battingAverage"
    case onBasePlusSlugging   = "onBasePlusSlugging"
    case rbi                  = "rbi"
    case hits                 = "hits"
    case stolenBases          = "stolenBases"
    case runs                 = "runs"
    case doubles              = "doubles"
    case triples              = "triples"
    case strikeoutsPer9Inn    = "strikeoutsPer9Inn"

    // Pitching
    case earnedRunAverage     = "earnedRunAverage"
    case wins                 = "wins"
    case strikeouts           = "strikeouts"
    case saves                = "saves"
    case whip                 = "whip"
    case inningsPitched       = "inningsPitched"
    case walksAndHitsPerInningPitched = "walksAndHitsPerInningPitched"
}
