import Foundation

/// Complete play-by-play data for a game.
public struct PlayByPlay: Codable, Sendable, Equatable {
    /// All plays in the game, in chronological order.
    public let allPlays: [Play]
    /// Indices into ``allPlays`` for plays that resulted in runs scoring.
    public let scoringPlays: [Int]?
}

/// A single play (at-bat or other game event).
public struct Play: Codable, Sendable, Equatable {
    /// The outcome of the play.
    public let result: PlayResult
    /// Context about when this play occurred.
    public let about: PlayAbout
    /// The ball-strike-out count at the end of the play.
    public let count: Count
    /// The batter-pitcher matchup.
    public let matchup: PlayMatchup
    /// Base runner movements during this play.
    public let runners: [Runner]?
    /// Individual pitch events within this play.
    public let playEvents: [PlayEvent]?
}

/// The result of a play.
public struct PlayResult: Codable, Sendable, Equatable {
    /// The type of result (e.g. `"atBat"`).
    public let type: String?
    /// The event name (e.g. `"Single"`, `"Home Run"`, `"Strikeout"`).
    public let event: String?
    /// Machine-readable event type (e.g. `"single"`, `"home_run"`).
    public let eventType: String?
    /// Human-readable description of the play.
    public let description: String?
    /// Runs batted in on this play.
    public let rbi: Int?
    /// Away team score after this play.
    public let awayScore: Int?
    /// Home team score after this play.
    public let homeScore: Int?
}

/// Contextual information about a play.
public struct PlayAbout: Codable, Sendable, Equatable {
    /// Zero-based index of this at-bat in the game.
    public let atBatIndex: Int
    /// Half of the inning (`"top"` or `"bottom"`).
    public let halfInning: String?
    /// The inning number.
    public let inning: Int
    /// Whether this play has completed.
    public let isComplete: Bool
    /// Whether this play resulted in a run scoring.
    public let isScoringPlay: Bool
    /// Whether an out was recorded on this play.
    public let hasOut: Bool
}

/// Ball-strike-out count.
public struct Count: Codable, Sendable, Equatable {
    /// Number of balls.
    public let balls: Int
    /// Number of strikes.
    public let strikes: Int
    /// Number of outs.
    public let outs: Int
}

/// The batter-pitcher matchup for a play.
public struct PlayMatchup: Codable, Sendable, Equatable {
    /// The batter.
    public let batter: PlayerReference
    /// The batter's hitting side.
    public let batSide: HandSide
    /// The pitcher.
    public let pitcher: PlayerReference
    /// The pitcher's throwing hand.
    public let pitchHand: HandSide
}

/// A base runner's movement during a play.
public struct Runner: Codable, Sendable, Equatable {
    /// The runner's base movement.
    public let movement: RunnerMovement?
    /// Details about the runner event.
    public let details: RunnerDetails?
}

/// Base movement information for a runner.
public struct RunnerMovement: Codable, Sendable, Equatable {
    /// The base the runner started at before the pitch.
    public let originBase: String?
    /// The base the runner was on when the ball was put in play.
    public let start: String?
    /// The base the runner ended up at (or `"score"`).
    public let end: String?
    /// The base where the runner was tagged out, if applicable.
    public let outBase: String?
    /// Whether the runner was out.
    public let isOut: Bool
}

/// Details about a runner's involvement in a play.
public struct RunnerDetails: Codable, Sendable, Equatable {
    /// The event type for this runner.
    public let event: String?
    /// The runner.
    public let runner: PlayerReference?
}

/// A single event within a play, typically a pitch.
public struct PlayEvent: Codable, Sendable, Equatable {
    /// Details about this event.
    public let details: PlayEventDetails?
    /// The count at this point in the at-bat.
    public let count: Count?
    /// Pitch tracking data.
    public let pitchData: PitchData?
    /// The pitch number within this at-bat.
    public let pitchNumber: Int?
    /// Whether this event is a pitch.
    public let isPitch: Bool?
    /// The event type (e.g. `"pitch"`).
    public let type: String?
}

/// Details about a play event.
public struct PlayEventDetails: Codable, Sendable, Equatable {
    /// The umpire's call for this pitch.
    public let call: CodeDescription?
    /// Human-readable description.
    public let description: String?
}

/// A code-description pair used throughout the MLB API.
public struct CodeDescription: Codable, Sendable, Equatable {
    /// Short code (e.g. `"S"`, `"B"`).
    public let code: String
    /// Human-readable description.
    public let description: String?
}

/// Pitch tracking data from Statcast.
public struct PitchData: Codable, Sendable, Equatable {
    /// Pitch velocity at release (mph).
    public let startSpeed: Double?
    /// Pitch velocity at the plate (mph).
    public let endSpeed: Double?
    /// Strike zone grid number.
    public let zone: Int?
    /// Top of the strike zone (feet).
    public let strikeZoneTop: Double?
    /// Bottom of the strike zone (feet).
    public let strikeZoneBottom: Double?
}
