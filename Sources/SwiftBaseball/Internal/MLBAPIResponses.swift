import Foundation

// MARK: - People

struct MLBPeopleResponse: Decodable {
    let people: [MLBPerson]
}

struct MLBPerson: Decodable {
    let id: Int
    let fullName: String
    let firstName: String?
    let lastName: String?
    let primaryNumber: String?
    let birthDate: String?
    let currentAge: Int?
    let birthCity: String?
    let birthCountry: String?
    let height: String?
    let weight: Int?
    let active: Bool?
    let primaryPosition: MLBPositionObject?
    let batSide: MLBCodeDescription?
    let pitchHand: MLBCodeDescription?
    let currentTeam: MLBEntityRef?
    let mlbDebutDate: String?
}

struct MLBPositionObject: Decodable {
    let code: String
    let name: String?
    let type: String?
    let abbreviation: String?
}

struct MLBCodeDescription: Decodable {
    let code: String
    let description: String?
}

// MARK: - Teams

struct MLBTeamsResponse: Decodable {
    let teams: [MLBTeam]
}

struct MLBTeamResponse: Decodable {
    let teams: [MLBTeam]
}

struct MLBTeam: Decodable {
    let id: Int
    let name: String
    let teamName: String?
    let locationName: String?
    let abbreviation: String?
    let shortName: String?
    let franchiseName: String?
    let clubName: String?
    let season: Int?
    let firstYearOfPlay: String?
    let active: Bool?
    let league: MLBEntityRef?
    let division: MLBEntityRef?
    let venue: MLBEntityRef?
}

struct MLBRosterResponse: Decodable {
    let roster: [MLBRosterEntry]
}

struct MLBRosterEntry: Decodable {
    let person: MLBEntityRef
    let jerseyNumber: String?
    let position: MLBPositionObject?
    let status: MLBCodeDescription?
}

// MARK: - Schedule

struct MLBScheduleResponse: Decodable {
    let dates: [MLBScheduleDate]
}

struct MLBScheduleDate: Decodable {
    let date: String
    let games: [MLBGame]
}

struct MLBGame: Decodable {
    let gamePk: Int
    let gameDate: String
    let status: MLBGameStatus?
    let teams: MLBGameTeams?
    let venue: MLBEntityRef?
    let gameType: String?
    let season: String?
    let seriesDescription: String?
    let gamesInSeries: Int?
    let seriesGameNumber: Int?
}

struct MLBGameStatus: Decodable {
    let abstractGameState: String?
    let codedGameState: String?
    let detailedState: String?
    let statusCode: String?
    let reason: String?
    let abstractGameCode: String?
}

struct MLBGameTeams: Decodable {
    let away: MLBGameTeamEntry
    let home: MLBGameTeamEntry
}

struct MLBGameTeamEntry: Decodable {
    let team: MLBEntityRef?
    let score: Int?
    let isWinner: Bool?
    let splitSquad: Bool?
    let leagueRecord: MLBLeagueRecord?
}

struct MLBLeagueRecord: Decodable {
    let wins: Int
    let losses: Int
    let pct: String
}

// MARK: - Standings

struct MLBStandingsResponse: Decodable {
    let records: [MLBStandingsRecord]
}

struct MLBStandingsRecord: Decodable {
    let division: MLBEntityRef?
    let teamRecords: [MLBTeamRecord]
}

struct MLBTeamRecord: Decodable {
    let team: MLBEntityRef?
    let wins: Int
    let losses: Int
    let winningPercentage: String
    let gamesBack: String?
    let wildCardGamesBack: String?
    let divisionRank: String?
    let leagueRank: String?
    let wildCardRank: String?
    let divisionChamp: Bool?
    let divisionLeader: Bool?
    let hasWildCard: Bool?
    let clinched: Bool?
    let eliminationNumber: String?
    let streak: MLBStreak?
    let records: MLBTeamRecordBreakdown?
    let runsAllowed: Int?
    let runsScored: Int?
    let runDifferential: Int?
}

struct MLBStreak: Decodable {
    let streakType: String?
    let streakNumber: Int?
    let streakCode: String?
}

struct MLBTeamRecordBreakdown: Decodable {
    let splitRecords: [MLBSplitRecord]?
}

struct MLBSplitRecord: Decodable {
    let wins: Int
    let losses: Int
    let type: String?
    let pct: String
}

// MARK: - Leaders

struct MLBLeadersResponse: Decodable {
    let leagueLeaders: [MLBLeaderCategory]
}

struct MLBLeaderCategory: Decodable {
    let leaderCategory: String?
    let leaders: [MLBLeaderEntry]
}

struct MLBLeaderEntry: Decodable {
    let rank: Int?
    let value: String?
    let person: MLBEntityRef?
    let team: MLBEntityRef?
    let season: String?
    let leagueRank: Int?
}

// MARK: - Boxscore

struct MLBBoxscoreResponse: Decodable {
    let teams: MLBBoxscoreTeams?
    let officials: [MLBOfficial]?
    let info: [MLBBoxscoreInfo]?
}

struct MLBBoxscoreTeams: Decodable {
    let away: MLBBoxscoreTeam
    let home: MLBBoxscoreTeam
}

struct MLBBoxscoreTeam: Decodable {
    let team: MLBEntityRef?
    let teamStats: MLBBoxscoreTeamStats?
    let players: [String: MLBBoxscorePlayer]?
    let batters: [Int]?
    let pitchers: [Int]?
    let battingOrder: [Int]?
    let note: [MLBBoxscoreInfo]?
}

struct MLBBoxscoreTeamStats: Decodable {
    let batting: BattingStats?
    let pitching: PitchingStats?
    let fielding: FieldingStats?
}

struct MLBBoxscorePlayer: Decodable {
    let person: MLBEntityRef?
    let jerseyNumber: String?
    let position: MLBPositionObject?
    let stats: MLBBoxscorePlayerStats?
    let battingOrder: String?
}

struct MLBBoxscorePlayerStats: Decodable {
    let batting: BattingStats?
    let pitching: PitchingStats?
    let fielding: FieldingStats?
}

struct MLBOfficial: Decodable {
    let official: MLBEntityRef?
    let officialType: String?
}

struct MLBBoxscoreInfo: Decodable {
    let label: String?
    let value: String?
}

// MARK: - Player stats

struct MLBPlayerStatsResponse: Decodable {
    let stats: [MLBStatGroup]
}

struct MLBStatGroup: Decodable {
    let type: MLBCodeDescription?
    let group: MLBCodeDescription?
    let splits: [MLBStatSplit]
}

struct MLBStatSplit: Decodable {
    let season: String?
    let stat: MLBStatPayload
    let player: MLBEntityRef?
    let team: MLBEntityRef?
}

struct MLBStatPayload: Decodable {
    // Shared
    let gamesPlayed: Int?
    let gamesStarted: Int?
    // Batting
    let plateAppearances: Int?
    let atBats: Int?
    let runs: Int?
    let hits: Int?
    let doubles: Int?
    let triples: Int?
    let homeRuns: Int?
    let rbi: Int?
    let stolenBases: Int?
    let caughtStealing: Int?
    let baseOnBalls: Int?
    let intentionalWalks: Int?
    let strikeOuts: Int?
    let hitByPitch: Int?
    let sacFlies: Int?
    let sacBunts: Int?
    let groundIntoDoublePlay: Int?
    let totalBases: Int?
    let leftOnBase: Int?
    let avg: String?
    let obp: String?
    let slg: String?
    let ops: String?
    let babip: String?
    // Pitching
    let wins: Int?
    let losses: Int?
    let saves: Int?
    let saveOpportunities: Int?
    let holds: Int?
    let blownSaves: Int?
    let completeGames: Int?
    let shutouts: Int?
    let earnedRuns: Int?
    let homeRunsAllowed: Int?
    let wildPitches: Int?
    let balks: Int?
    let battersFaced: Int?
    let era: String?
    let whip: String?
    let inningsPitched: String?
    // Fielding
    let assists: Int?
    let putOuts: Int?
    let errors: Int?
    let chances: Int?
    let doublePlays: Int?
    let triplePlays: Int?
    let passedBalls: Int?
    let fielding: String?
    let innings: String?
}

// MARK: - Shared

struct MLBEntityRef: Decodable {
    let id: Int
    let name: String?
    let fullName: String?
    let link: String?

    var displayName: String { name ?? fullName ?? "" }
}
