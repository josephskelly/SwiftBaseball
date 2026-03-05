import Foundation

public struct StandingsRecord: Codable, Sendable, Equatable {
    public let team: TeamReference
    public let wins: Int
    public let losses: Int
    public let winningPercentage: Double
    public let gamesBack: Double?
    public let wildCardGamesBack: Double?
    public let divisionRank: Int
    public let leagueRank: Int
    public let wildCardRank: Int?
    public let divisionChamp: Bool
    public let divisionLeader: Bool
    public let hasWildCard: Bool
    public let clinched: Bool
    public let eliminationNumber: String?
    public let streak: Streak
    public let lastTen: LastTen
    public let runsAllowed: Int?
    public let runsScored: Int?
    public let runDifferential: Int?

    public var gamesPlayed: Int { wins + losses }
}

public struct Streak: Codable, Sendable, Equatable {
    public let streakType: String?
    public let streakNumber: Int?
    public let streakCode: String?
}

public struct LastTen: Codable, Sendable, Equatable {
    public let wins: Int
    public let losses: Int
    public let pct: String
}

public struct DivisionStandings: Codable, Sendable, Equatable {
    public let division: DivisionReference
    public let teamRecords: [StandingsRecord]
}
