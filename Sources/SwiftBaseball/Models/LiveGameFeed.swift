import Foundation

// MARK: - LiveGameFeed

/// Complete live game state returned by the MLB live game feed.
///
/// A single snapshot covering game metadata, all prior plays, the current
/// play, linescore, boxscore, and decisions (winning/losing/save pitchers).
/// During a live game, clients typically poll this endpoint using
/// ``LiveFeedMeta/wait`` as the recommended interval.
///
/// Fetched via ``SwiftBaseball/liveGameFeed(gamePk:)``.
public struct LiveGameFeed: Codable, Sendable, Equatable {
    /// MLB game primary key.
    public let gamePk: Int
    /// Meta information about this snapshot (polling interval, server timestamp).
    public let meta: LiveFeedMeta
    /// Relatively static data about the game (teams, venue, players, status).
    public let gameData: LiveGameData
    /// Dynamic data that changes as the game progresses (plays, linescore, boxscore).
    public let liveData: LiveData
}

/// Metadata from the live feed snapshot.
public struct LiveFeedMeta: Codable, Sendable, Equatable {
    /// Recommended polling interval in seconds, returned by the server.
    public let wait: Int
    /// Server-side timestamp of this snapshot (e.g. `"20240905_222835"`).
    public let timeStamp: String
    /// Game event names that occurred between this and the previous snapshot.
    public let gameEvents: [String]
    /// Logical event names (derived state changes) since the previous snapshot.
    public let logicalEvents: [String]
}

// MARK: - GameData subtree

/// Relatively static information about a game.
public struct LiveGameData: Codable, Sendable, Equatable {
    /// Game identifiers, type, and season.
    public let game: LiveGameInfo
    /// Scheduled date and time information.
    public let datetime: LiveGameDatetime
    /// High-level game state (scheduled/live/final, detailed state).
    public let status: LiveGameStatus
    /// Home and away team references with league records.
    public let teams: LiveGameTeams
    /// All players participating in the game, keyed by MLB player ID.
    ///
    /// The upstream API keys this dictionary with string keys of the form
    /// `"ID660271"`. The converter strips the `"ID"` prefix so callers can
    /// look up by integer player ID.
    public let players: [Int: LivePlayer]
    /// The venue the game is played at.
    public let venue: VenueReference
    /// Weather conditions at first pitch, when reported.
    public let weather: GameWeather?
    /// Attendance, first pitch, and game duration, when reported.
    public let gameInfo: GameInfo?
    /// Noteworthy in-progress flags (no-hitter, perfect game).
    public let flags: GameFlags
    /// Announced probable starting pitchers.
    public let probablePitchers: ProbablePitchers
}

/// Identifiers and classification for a specific game.
public struct LiveGameInfo: Codable, Sendable, Equatable {
    /// MLB game primary key.
    public let pk: Int
    /// Game type (regular season, playoff round, spring training, etc.).
    public let type: GameType
    /// Whether this game is part of a doubleheader (`"N"`, `"Y"`, `"S"`).
    public let doubleHeader: String
    /// Season year as a string (e.g. `"2024"`).
    public let season: String
    /// Display form of the season (e.g. `"2024"`).
    public let seasonDisplay: String
}

/// Scheduled and reported date/time information for a game.
public struct LiveGameDatetime: Codable, Sendable, Equatable {
    /// Scheduled first pitch (UTC), when provided.
    public let dateTime: Date?
    /// The originally scheduled date (calendar day).
    public let originalDate: Date?
    /// The official scored date (may differ from `originalDate` for suspended games).
    public let officialDate: Date?
    /// Whether the game is scheduled during the day or at night.
    public let dayNight: DayNight
    /// Display time string (e.g. `"7:10"`).
    public let time: String
    /// AM/PM indicator.
    public let ampm: String
}

/// Whether a game is scheduled during the day or at night.
public enum DayNight: String, Codable, Sendable, Hashable, CaseIterable {
    /// Day game.
    case day
    /// Night game.
    case night
    /// Unknown or unspecified.
    case unknown

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        self = DayNight(rawValue: raw) ?? .unknown
    }
}

/// Composite game status returned by the live feed.
///
/// Distinct from the lifecycle enum ``GameStatus``: this struct wraps the
/// API's layered status payload (abstract + detailed + status code + flags)
/// so callers can render the right label and branch on coarse phase.
public struct LiveGameStatus: Codable, Sendable, Equatable {
    /// High-level lifecycle phase — preview, live, or final.
    public let abstractGameState: AbstractGameState
    /// Raw API coded game state character (e.g. `"P"`, `"I"`, `"F"`).
    public let codedGameState: String
    /// Detailed human-readable state (e.g. `"In Progress"`, `"Postponed"`).
    public let detailedState: String
    /// Internal API status code string.
    public let statusCode: String
    /// Whether first pitch is TBD.
    public let startTimeTBD: Bool
}

/// Coarse game lifecycle phase.
public enum AbstractGameState: String, Codable, Sendable, Hashable, CaseIterable {
    /// The game has not started — lineups may still be posting.
    case preview = "Preview"
    /// The game is currently in progress.
    case live    = "Live"
    /// The game has completed.
    case final   = "Final"
    /// Unrecognized state returned by the API.
    case unknown = "Unknown"

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        self = AbstractGameState(rawValue: raw) ?? .unknown
    }
}

/// Home and away team summaries in the live feed.
public struct LiveGameTeams: Codable, Sendable, Equatable {
    /// Away team summary.
    public let away: LiveGameTeam
    /// Home team summary.
    public let home: LiveGameTeam
}

/// One team's summary in the live feed — reference, record, and current score.
public struct LiveGameTeam: Codable, Sendable, Equatable {
    /// Team reference (id + name).
    public let team: TeamReference
    /// Team's league record coming into the game.
    public let leagueRecord: LeagueRecord
    /// Current run total. `nil` before the game starts.
    ///
    /// The live feed reports scores in the linescore sub-payload; the
    /// converter pulls them up here so both teams' current scores are
    /// directly accessible alongside the team reference.
    public let score: Int?
}

/// A player participating in a live game, as listed under `gameData.players`.
public struct LivePlayer: Codable, Sendable, Equatable, Identifiable {
    /// MLB player ID.
    public let id: Int
    /// Full display name.
    public let fullName: String
    /// Uniform number, when set.
    public let primaryNumber: String?
    /// Age at the date of the game.
    public let currentAge: Int?
    /// Primary defensive position.
    public let primaryPosition: Position
    /// Batting hand side.
    public let batSide: HandSide
    /// Throwing hand side.
    public let pitchHand: HandSide
    /// Whether the player is currently active on an MLB roster.
    public let active: Bool?
}

/// Weather conditions reported for a game.
public struct GameWeather: Codable, Sendable, Equatable {
    /// Textual condition (e.g. `"Sunny"`, `"Clear"`, `"Dome"`).
    public let condition: String
    /// Temperature in Fahrenheit, as a display string.
    public let temp: String
    /// Wind description (e.g. `"10 mph, Out to CF"`).
    public let wind: String
}

/// Reported game-level facts (attendance, first pitch, duration).
public struct GameInfo: Codable, Sendable, Equatable {
    /// Paid attendance, when reported.
    public let attendance: Int?
    /// First pitch time as returned by the API (ISO 8601 when present).
    public let firstPitch: String?
    /// Game duration in minutes, when reported.
    public let gameDurationMinutes: Int?
}

/// No-hitter / perfect game flags for the overall game and each team.
public struct GameFlags: Codable, Sendable, Equatable {
    /// Whether a no-hitter is currently in progress or was thrown.
    public let noHitter: Bool
    /// Whether a perfect game is currently in progress or was thrown.
    public let perfectGame: Bool
    /// Whether the away team is throwing a no-hitter.
    public let awayTeamNoHitter: Bool
    /// Whether the away team is throwing a perfect game.
    public let awayTeamPerfectGame: Bool
    /// Whether the home team is throwing a no-hitter.
    public let homeTeamNoHitter: Bool
    /// Whether the home team is throwing a perfect game.
    public let homeTeamPerfectGame: Bool
}

/// Announced probable starting pitchers.
public struct ProbablePitchers: Codable, Sendable, Equatable {
    /// Away team probable starter, when posted.
    public let away: PlayerReference?
    /// Home team probable starter, when posted.
    public let home: PlayerReference?
}

// MARK: - LiveData subtree

/// Dynamic in-game data (plays, linescore, boxscore, decisions).
public struct LiveData: Codable, Sendable, Equatable {
    /// Every play and derived play indices.
    public let plays: LivePlays
    /// Full linescore (per-inning scoring and team totals).
    public let linescore: Linescore
    /// Full boxscore (team and player stats).
    public let boxscore: Boxscore
    /// Winning / losing / save pitchers — `nil` before the game is final.
    public let decisions: GameDecisions?
}

/// Plays container for a live game.
public struct LivePlays: Codable, Sendable, Equatable {
    /// All plays in the game, ordered chronologically.
    public let allPlays: [Play]
    /// The at-bat currently in progress, or the most recent one.
    public let currentPlay: Play?
    /// Indices into ``allPlays`` for plays that resulted in runs scoring.
    public let scoringPlays: [Int]
    /// Plays bucketed by inning.
    public let playsByInning: [InningPlays]
}

/// Plays grouped by inning with half-inning breakouts.
public struct InningPlays: Codable, Sendable, Equatable {
    /// 1-based inning number, derived from position in the array.
    public let inning: Int
    /// First index into ``LivePlays/allPlays`` belonging to this inning.
    public let startIndex: Int?
    /// Last index (inclusive) belonging to this inning.
    public let endIndex: Int?
    /// Indices into ``LivePlays/allPlays`` for top-half plays.
    public let top: [Int]
    /// Indices into ``LivePlays/allPlays`` for bottom-half plays.
    public let bottom: [Int]
}

/// Winning, losing, and save pitcher decisions for a completed game.
public struct GameDecisions: Codable, Sendable, Equatable {
    /// Winning pitcher, when assigned.
    public let winner: PlayerReference?
    /// Losing pitcher, when assigned.
    public let loser: PlayerReference?
    /// Save pitcher, when earned.
    public let save: PlayerReference?
}
