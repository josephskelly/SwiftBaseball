import Foundation

public struct ScheduleEntry: Codable, Sendable, Equatable, Identifiable {
    public let id: Int          // gamePk
    public let gameDate: Date
    public let status: GameStatus
    public let teams: ScheduleTeams
    public let venue: VenueReference
    public let gameType: GameType
    public let season: String
    public let seriesDescription: String?
    public let gamesInSeries: Int?
    public let seriesGameNumber: Int?

    enum CodingKeys: String, CodingKey {
        case id = "gamePk"
        case gameDate, status, teams, venue, gameType, season
        case seriesDescription, gamesInSeries, seriesGameNumber
    }
}

public struct ScheduleTeams: Codable, Sendable, Equatable {
    public let away: ScheduleTeamEntry
    public let home: ScheduleTeamEntry
}

public struct ScheduleTeamEntry: Codable, Sendable, Equatable {
    public let team: TeamReference
    public let score: Int?
    public let isWinner: Bool?
    public let splitSquad: Bool?
    public let leagueRecord: LeagueRecord?
}

public struct LeagueRecord: Codable, Sendable, Equatable {
    public let wins: Int
    public let losses: Int
    public let pct: String
}
