import Foundation

// MARK: - Boxscore

public struct Boxscore: Codable, Sendable, Equatable {
    public let teams: BoxscoreTeams
    public let officials: [Official]?
    public let info: [BoxscoreInfoItem]?
}

public struct BoxscoreTeams: Codable, Sendable, Equatable {
    public let away: BoxscoreTeam
    public let home: BoxscoreTeam
}

public struct BoxscoreTeam: Codable, Sendable, Equatable {
    public let team: TeamReference
    public let teamStats: BoxscoreTeamStats
    public let players: [String: BoxscorePlayer]?
    public let batters: [Int]?
    public let pitchers: [Int]?
    public let battingOrder: [Int]?
    public let note: [BoxscoreInfoItem]?
}

public struct BoxscoreTeamStats: Codable, Sendable, Equatable {
    public let batting: BattingStats
    public let pitching: PitchingStats
    public let fielding: FieldingStats
}

public struct BoxscorePlayer: Codable, Sendable, Equatable {
    public let person: PlayerReference
    public let jerseyNumber: String?
    public let position: Position
    public let stats: BoxscorePlayerStats
    public let battingOrder: String?
}

public struct BoxscorePlayerStats: Codable, Sendable, Equatable {
    public let batting: BattingStats
    public let pitching: PitchingStats
    public let fielding: FieldingStats
}

public struct Official: Codable, Sendable, Equatable {
    public let official: PlayerReference
    public let officialType: String
}

public struct BoxscoreInfoItem: Codable, Sendable, Equatable {
    public let label: String
    public let value: String?
}

// MARK: - Linescore

public struct Linescore: Codable, Sendable, Equatable {
    public let currentInning: Int?
    public let currentInningOrdinal: String?
    public let inningHalf: String?
    public let innings: [InningLine]
    public let teams: LinescoreTeams
    public let outs: Int?
    public let balls: Int?
    public let strikes: Int?
    public let offense: LinescoreOffense?
    public let defense: LinescoreDefense?
    public let isTopInning: Bool?
    public let scheduledInnings: Int?
}

public struct InningLine: Codable, Sendable, Equatable {
    public let num: Int
    public let ordinalNum: String
    public let home: InningScore
    public let away: InningScore
}

public struct InningScore: Codable, Sendable, Equatable {
    public let runs: Int?
    public let hits: Int?
    public let errors: Int?
    public let leftOnBase: Int?
}

public struct LinescoreTeams: Codable, Sendable, Equatable {
    public let home: LinescoreTeamTotals
    public let away: LinescoreTeamTotals
}

public struct LinescoreTeamTotals: Codable, Sendable, Equatable {
    public let runs: Int?
    public let hits: Int?
    public let errors: Int?
    public let leftOnBase: Int?
}

public struct LinescoreOffense: Codable, Sendable, Equatable {
    public let batter: PlayerReference?
    public let onDeck: PlayerReference?
    public let inHole: PlayerReference?
    public let pitcher: PlayerReference?
    public let first: PlayerReference?
    public let second: PlayerReference?
    public let third: PlayerReference?
}

public struct LinescoreDefense: Codable, Sendable, Equatable {
    public let pitcher: PlayerReference?
    public let catcher: PlayerReference?
    public let first: PlayerReference?
    public let second: PlayerReference?
    public let third: PlayerReference?
    public let shortstop: PlayerReference?
    public let left: PlayerReference?
    public let center: PlayerReference?
    public let right: PlayerReference?
    public let batter: PlayerReference?
    public let onDeck: PlayerReference?
    public let inHole: PlayerReference?
}
