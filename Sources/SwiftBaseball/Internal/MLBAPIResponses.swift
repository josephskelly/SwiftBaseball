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
    let alumniLastSeason: String?
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
    let sport: MLBEntityRef?
    let parentOrgId: Int?
    let parentOrgName: String?
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

// MARK: - Team coaches

struct MLBCoachesResponse: Decodable {
    let roster: [MLBCoach]
}

struct MLBCoach: Decodable {
    let person: MLBEntityRef
    let jerseyNumber: String?
    let job: String?
    let jobId: String?
    let title: String?
}

// MARK: - Umpires

struct MLBUmpiresResponse: Decodable {
    let roster: [MLBUmpire]
}

struct MLBUmpire: Decodable {
    let person: MLBEntityRef
    let jerseyNumber: String?
    let job: String?
    let jobId: String?
    let title: String?
}

// MARK: - Attendance

struct MLBAttendanceResponse: Decodable {
    let records: [MLBAttendanceRecord]
}

struct MLBAttendanceRecord: Decodable {
    let team: MLBEntityRef?
    let year: String?
    let gameType: MLBCodeDescriptionId?

    let openingsTotal: Int?
    let openingsTotalHome: Int?
    let openingsTotalAway: Int?
    let openingsTotalLost: Int?

    let gamesTotal: Int?
    let gamesHomeTotal: Int?
    let gamesAwayTotal: Int?

    let attendanceTotal: Int?
    let attendanceTotalHome: Int?
    let attendanceTotalAway: Int?

    let attendanceAverageYtd: Int?
    let attendanceAverageHome: Int?
    let attendanceAverageAway: Int?
    let attendanceOpeningAverage: Int?

    let attendanceHigh: Int?
    let attendanceHighDate: String?
    let attendanceHighGame: MLBAttendanceGameRef?

    let attendanceLow: Int?
    let attendanceLowDate: String?
    let attendanceLowGame: MLBAttendanceGameRef?
}

struct MLBAttendanceGameRef: Decodable {
    let gamePk: Int?
}

struct MLBCodeDescriptionId: Decodable {
    let id: String?
    let description: String?
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
    let probablePitcher: MLBEntityRef?
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

// MARK: - Game pace

struct MLBGamePaceResponse: Decodable {
    let teams: [MLBGamePaceEntry]?
    let leagues: [MLBGamePaceEntry]?
    let sports: [MLBGamePaceEntry]?
}

struct MLBGamePaceEntry: Decodable {
    let season: String?
    let team: MLBEntityRef?
    let league: MLBEntityRef?
    let sport: MLBGamePaceSportRef?

    let totalGames: Int?
    let total9InnGames: Int?
    let total7InnGames: Int?
    let totalExtraInnGames: Int?
    let total9InnGamesScheduled: Int?
    let total9InnGamesCompletedEarly: Int?
    let total9InnGamesWithoutExtraInn: Int?

    let totalInningsPlayed: Double?
    let totalHits: Int?
    let totalRuns: Int?
    let totalPlateAppearances: Int?
    let totalPitchers: Int?
    let totalPitches: Int?

    let hitsPer9Inn: Double?
    let runsPer9Inn: Double?
    let pitchesPer9Inn: Double?
    let plateAppearancesPer9Inn: Double?
    let hitsPerGame: Double?
    let runsPerGame: Double?
    let inningsPlayedPerGame: Double?
    let pitchesPerGame: Double?
    let pitchersPerGame: Double?
    let plateAppearancesPerGame: Double?
    let hitsPerRun: Double?
    let pitchesPerPitcher: Double?

    let totalGameTime: String?
    let timePerGame: String?
    let timePerPitch: String?
    let timePerHit: String?
    let timePerRun: String?
    let timePerPlateAppearance: String?
    let timePer9Inn: String?
    let timePer77PlateAppearances: String?
    let totalExtraInnTime: String?

    let prPortalCalculatedFields: MLBGamePacePortalFields?
}

struct MLBGamePaceSportRef: Decodable {
    let id: Int?
    let name: String?
}

struct MLBGamePacePortalFields: Decodable {
    let timePer7InnGame: String?
    let timePer9InnGame: String?
    let timePerExtraInnGame: String?
}

// MARK: - Team Leaders

struct MLBTeamLeadersResponse: Decodable {
    let teamLeaders: [MLBTeamLeaderCategory]
}

struct MLBTeamLeaderCategory: Decodable {
    let leaderCategory: String?
    let statGroup: String?
    let season: String?
    let gameType: MLBCodeDescriptionId?
    let team: MLBEntityRef?
    let totalSplits: Int?
    let leaders: [MLBLeaderEntry]
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
    let type: MLBDisplayName?
    let group: MLBDisplayName?
    let splits: [MLBStatSplit]
}

struct MLBStatSplit: Decodable {
    let season: String?
    let stat: MLBStatPayload
    let player: MLBEntityRef?
    let team: MLBEntityRef?
    let split: MLBCodeDescription?
    let gameType: String?
    /// Present on minor league stat splits; contains `id` and `name`.
    let league: MLBEntityRef?
    /// Present on minor league stat splits; contains `id` and `abbreviation`.
    let sport: MLBSportRef?
}

/// Minimal sport reference returned inside stat splits.
///
/// Unlike ``MLBEntityRef``, this type uses `abbreviation` instead of `name`
/// (e.g. `"AAA"` for Triple-A) because the API does not return a display name
/// in stat-split sport objects.
struct MLBSportRef: Decodable {
    let id: Int
    let abbreviation: String?
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
    let numberOfPitches: Int?
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

// MARK: - Game Log

struct MLBGameLogResponse: Decodable {
    let stats: [MLBGameLogGroup]
}

struct MLBGameLogGroup: Decodable {
    let type: MLBDisplayName?
    let group: MLBDisplayName?
    let splits: [MLBGameLogSplit]
}

struct MLBDisplayName: Decodable {
    let displayName: String
}

struct MLBGameLogSplit: Decodable {
    let season: String?
    let stat: MLBStatPayload
    let player: MLBEntityRef?
    let team: MLBEntityRef?
    let opponent: MLBEntityRef?
    let date: String?
    let gameType: String?
    let isHome: Bool?
    let isWin: Bool?
    let game: MLBGameReference?
}

struct MLBGameReference: Decodable {
    let gamePk: Int
}

// MARK: - Play-by-Play

struct MLBPlayByPlayResponse: Decodable {
    let allPlays: [MLBPlay]
    let scoringPlays: [Int]?
}

struct MLBPlay: Decodable {
    let result: MLBPlayResult?
    let about: MLBPlayAbout?
    let count: MLBCount?
    let matchup: MLBPlayMatchup?
    let runners: [MLBRunner]?
    let playEvents: [MLBPlayEvent]?
}

struct MLBPlayResult: Decodable {
    let type: String?
    let event: String?
    let eventType: String?
    let description: String?
    let rbi: Int?
    let awayScore: Int?
    let homeScore: Int?
}

struct MLBPlayAbout: Decodable {
    let atBatIndex: Int
    let halfInning: String?
    let inning: Int
    let isComplete: Bool
    let isScoringPlay: Bool
    let hasOut: Bool
}

struct MLBCount: Decodable {
    let balls: Int
    let strikes: Int
    let outs: Int
}

struct MLBPlayMatchup: Decodable {
    let batter: MLBEntityRef?
    let batSide: MLBCodeDescription?
    let pitcher: MLBEntityRef?
    let pitchHand: MLBCodeDescription?
}

struct MLBRunner: Decodable {
    let movement: MLBRunnerMovement?
    let details: MLBRunnerDetails?
}

struct MLBRunnerMovement: Decodable {
    let originBase: String?
    let start: String?
    let end: String?
    let outBase: String?
    let isOut: Bool?
}

struct MLBRunnerDetails: Decodable {
    let event: String?
    let runner: MLBEntityRef?
}

struct MLBPlayEvent: Decodable {
    let details: MLBPlayEventDetails?
    let count: MLBCount?
    let pitchData: MLBPitchData?
    let pitchNumber: Int?
    let isPitch: Bool?
    let type: String?
}

struct MLBPlayEventDetails: Decodable {
    let call: MLBCodeDescription?
    let description: String?
}

struct MLBPitchData: Decodable {
    let startSpeed: Double?
    let endSpeed: Double?
    let zone: Int?
    let strikeZoneTop: Double?
    let strikeZoneBottom: Double?
}

// MARK: - Transactions

struct MLBTransactionsResponse: Decodable {
    let transactions: [MLBTransaction]
}

struct MLBTransaction: Decodable {
    let id: Int
    let person: MLBEntityRef?
    let fromTeam: MLBEntityRef?
    let toTeam: MLBEntityRef?
    let date: String?
    let effectiveDate: String?
    let typeCode: String?
    let typeDesc: String?
    let description: String?
}

// MARK: - Sabermetrics

struct MLBSabermetricResponse: Decodable {
    let stats: [MLBSabermetricGroup]
}

struct MLBSabermetricGroup: Decodable {
    let type: MLBDisplayName?
    let group: MLBDisplayName?
    let splits: [MLBSabermetricSplit]
}

struct MLBSabermetricSplit: Decodable {
    let season: String?
    let stat: MLBSabermetricPayload
    let player: MLBEntityRef?
    let team: MLBEntityRef?
}

struct MLBSabermetricPayload: Decodable {
    let woba: Double?
    let wRaa: Double?
    let wRc: Double?
    let wRcPlus: Double?
    let rar: Double?
    let war: Double?
    let batting: Double?
    let fielding: Double?
    let baseRunning: Double?
    let positional: Double?
    let wLeague: Double?
    let replacement: Double?
    let spd: Double?
    let ubr: Double?
    let wGdp: Double?
    let wSb: Double?
}

// MARK: - Venues

struct MLBVenuesResponse: Decodable {
    let venues: [MLBVenueDetail]
}

struct MLBVenueDetail: Decodable {
    let id: Int
    let name: String
    let location: MLBVenueLocation?
    let fieldInfo: MLBFieldInfo?
    let active: Bool?
}

struct MLBVenueLocation: Decodable {
    let city: String?
    let state: String?
    let stateAbbrev: String?
    let country: String?
    let defaultCoordinates: MLBCoordinates?
}

struct MLBCoordinates: Decodable {
    let latitude: Double
    let longitude: Double
}

struct MLBFieldInfo: Decodable {
    let capacity: Int?
    let turfType: String?
    let roofType: String?
    let leftLine: Int?
    let left: Int?
    let leftCenter: Int?
    let center: Int?
    let rightCenter: Int?
    let right: Int?
    let rightLine: Int?
}

// MARK: - Draft

struct MLBDraftResponse: Decodable {
    let drafts: MLBDraftContainer
}

struct MLBDraftContainer: Decodable {
    let draftYear: Int
    let rounds: [MLBDraftRound]
}

struct MLBDraftRound: Decodable {
    let round: String
    let picks: [MLBDraftPickPayload]
}

struct MLBDraftPickPayload: Decodable {
    let bisPlayerId: Int?
    let pickRound: String?
    let pickNumber: Int?
    let roundPickNumber: Int?
    let signingBonus: String?
    let blurb: String?
    let scoutingReport: String?
    let team: MLBEntityRef?
    let person: MLBEntityRef?
    let school: MLBDraftSchool?
    let isDrafted: Bool?
    let isPass: Bool?
}

struct MLBDraftSchool: Decodable {
    let name: String?
    let schoolClass: String?
    let city: String?
    let state: String?
    let country: String?
}

// MARK: - Awards

struct MLBAwardsListResponse: Decodable {
    let awards: [MLBAwardPayload]
}

struct MLBAwardPayload: Decodable {
    let id: String
    let name: String?
    let description: String?
    let active: Bool?
    let league: MLBEntityRef?
    let sport: MLBEntityRef?
}

struct MLBAwardRecipientsResponse: Decodable {
    let awards: [MLBAwardRecipientPayload]
}

struct MLBAwardRecipientPayload: Decodable {
    let id: String
    let name: String?
    let date: String?
    let season: String?
    let team: MLBEntityRef?
    let player: MLBAwardPlayerRef?
}

struct MLBAwardPlayerRef: Decodable {
    let id: Int
    let nameFirstLast: String?
}

// MARK: - Game Content / Highlights

struct MLBGameContentResponse: Decodable {
    let highlights: MLBGameHighlightsSection?
}

struct MLBGameHighlightsSection: Decodable {
    let gameCenter: MLBHighlightCollection?
    let scoreboard: MLBHighlightCollection?
}

struct MLBHighlightCollection: Decodable {
    let items: [MLBHighlightItem]?
}

struct MLBHighlightItem: Decodable {
    let id: String?
    let date: String?
    let title: String?
    let headline: String?
    let blurb: String?
    let duration: String?
    let playbacks: [MLBVideoPlayback]?
    let image: MLBHighlightImage?
}

/// Width and height are serialised as strings in the MLB content API (e.g. `"1280"`).
struct MLBVideoPlayback: Decodable {
    let name: String?
    let url: String?
    let width: String?
    let height: String?
}

struct MLBHighlightImage: Decodable {
    let altText: String?
    let cuts: [MLBImageCut]?
}

struct MLBImageCut: Decodable {
    let aspectRatio: String?
    let width: Int?
    let height: Int?
    let src: String?
}

// MARK: - Shared

struct MLBEntityRef: Decodable {
    let id: Int
    let name: String?
    let fullName: String?
    let link: String?

    var displayName: String {
        name ?? fullName ?? ""
    }
}

// MARK: - Live Game Feed

struct MLBLiveGameFeedResponse: Decodable {
    let gamePk: Int
    let metaData: MLBLiveFeedMeta
    let gameData: MLBLiveGameData
    let liveData: MLBLiveData
}

struct MLBLiveFeedMeta: Decodable {
    let wait: Int?
    let timeStamp: String?
    let gameEvents: [String]?
    let logicalEvents: [String]?
}

struct MLBLiveGameData: Decodable {
    let game: MLBLiveGameInfo
    let datetime: MLBLiveGameDatetime
    let status: MLBLiveGameStatus
    let teams: MLBLiveTeams
    let players: [String: MLBLivePlayer]?
    let venue: MLBEntityRef?
    let weather: MLBGameWeather?
    let gameInfo: MLBGameInfo?
    let flags: MLBGameFlags?
    let probablePitchers: MLBProbablePitchers?
}

struct MLBLiveGameInfo: Decodable {
    let pk: Int
    let type: String?
    let doubleHeader: String?
    let season: String?
    let seasonDisplay: String?
}

struct MLBLiveGameDatetime: Decodable {
    let dateTime: String?
    let originalDate: String?
    let officialDate: String?
    let dayNight: String?
    let time: String?
    let ampm: String?
}

struct MLBLiveGameStatus: Decodable {
    let abstractGameState: String?
    let codedGameState: String?
    let detailedState: String?
    let statusCode: String?
    let startTimeTBD: Bool?
    let abstractGameCode: String?
}

struct MLBLiveTeams: Decodable {
    let away: MLBLiveTeam
    let home: MLBLiveTeam
}

struct MLBLiveTeam: Decodable {
    let id: Int
    let name: String?
    let teamName: String?
    let abbreviation: String?
    let locationName: String?
    let record: MLBLiveTeamRecord?
}

struct MLBLiveTeamRecord: Decodable {
    let wins: Int?
    let losses: Int?
    let winningPercentage: String?
    let leagueRecord: MLBLiveLeagueRecord?
}

struct MLBLiveLeagueRecord: Decodable {
    let wins: Int?
    let losses: Int?
    let ties: Int?
    let pct: String?
}

struct MLBLivePlayer: Decodable {
    let id: Int
    let fullName: String?
    let firstName: String?
    let lastName: String?
    let primaryNumber: String?
    let currentAge: Int?
    let birthDate: String?
    let primaryPosition: MLBPositionObject?
    let batSide: MLBCodeDescription?
    let pitchHand: MLBCodeDescription?
    let active: Bool?
    let mlbDebutDate: String?
}

struct MLBGameWeather: Decodable {
    let condition: String?
    let temp: String?
    let wind: String?
}

struct MLBGameInfo: Decodable {
    let attendance: Int?
    let firstPitch: String?
    let gameDurationMinutes: Int?
}

struct MLBGameFlags: Decodable {
    let noHitter: Bool?
    let perfectGame: Bool?
    let awayTeamNoHitter: Bool?
    let awayTeamPerfectGame: Bool?
    let homeTeamNoHitter: Bool?
    let homeTeamPerfectGame: Bool?
}

struct MLBProbablePitchers: Decodable {
    let away: MLBEntityRef?
    let home: MLBEntityRef?
}

struct MLBLiveData: Decodable {
    let plays: MLBLivePlays
    let linescore: Linescore
    let boxscore: MLBBoxscoreResponse
    let decisions: MLBGameDecisions?
}

struct MLBLivePlays: Decodable {
    let allPlays: [MLBPlay]
    let currentPlay: MLBPlay?
    let scoringPlays: [Int]?
    let playsByInning: [MLBInningPlays]?
}

struct MLBInningPlays: Decodable {
    let startIndex: Int?
    let endIndex: Int?
    let top: [Int]?
    let bottom: [Int]?
}

struct MLBGameDecisions: Decodable {
    let winner: MLBEntityRef?
    let loser: MLBEntityRef?
    let save: MLBEntityRef?
}

// MARK: - Win Probability

struct MLBWinProbabilityPlay: Decodable {
    let atBatIndex: Int?
    let homeTeamWinProbability: Double?
    let awayTeamWinProbability: Double?
    let homeTeamWinProbabilityAdded: Double?
    let result: MLBPlayResult?
    let about: MLBPlayAbout?
    let matchup: MLBPlayMatchup?
}

// MARK: - Context Metrics

struct MLBContextMetricsResponse: Decodable {
    let game: MLBGameReference
    let homeWinProbability: Double?
    let awayWinProbability: Double?
}
