import Foundation

// MARK: - Position

public enum Position: String, Codable, Sendable, Hashable, CaseIterable {
    case pitcher          = "1"
    case catcher          = "2"
    case firstBase        = "3"
    case secondBase       = "4"
    case thirdBase        = "5"
    case shortstop        = "6"
    case leftField        = "7"
    case centerField      = "8"
    case rightField       = "9"
    case designatedHitter = "10"
    case outfield         = "OF"
    case infield          = "IF"
    case pinchHitter      = "PH"
    case pinchRunner      = "PR"
    case twoWayPlayer     = "Y"
    case unknown          = "U"

    public var displayName: String {
        switch self {
        case .pitcher:          return "Pitcher"
        case .catcher:          return "Catcher"
        case .firstBase:        return "First Base"
        case .secondBase:       return "Second Base"
        case .thirdBase:        return "Third Base"
        case .shortstop:        return "Shortstop"
        case .leftField:        return "Left Field"
        case .centerField:      return "Center Field"
        case .rightField:       return "Right Field"
        case .designatedHitter: return "Designated Hitter"
        case .outfield:         return "Outfield"
        case .infield:          return "Infield"
        case .pinchHitter:      return "Pinch Hitter"
        case .pinchRunner:      return "Pinch Runner"
        case .twoWayPlayer:     return "Two-Way Player"
        case .unknown:          return "Unknown"
        }
    }

    /// Decode leniently — falls back to `.unknown` for unrecognized codes.
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        self = Position(rawValue: raw) ?? .unknown
    }
}

// MARK: - HandSide

public enum HandSide: String, Codable, Sendable, Hashable, CaseIterable {
    case left    = "L"
    case right   = "R"
    case both    = "S"   // Switch hitter / ambidextrous
    case unknown = "U"

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        self = HandSide(rawValue: raw) ?? .unknown
    }
}

// MARK: - League

public enum League: String, Codable, Sendable, Hashable, CaseIterable {
    case american = "AL"
    case national = "NL"

    /// MLB Stats API numeric league ID.
    var leagueId: Int {
        switch self {
        case .american: return 103
        case .national: return 104
        }
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        if let value = League(rawValue: raw) {
            self = value
        } else if raw == "103" {
            self = .american
        } else if raw == "104" {
            self = .national
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Unknown league: \(raw)"
            )
        }
    }
}

// MARK: - Division

public enum Division: Int, Codable, Sendable, Hashable, CaseIterable {
    case alEast    = 201
    case alCentral = 202
    case alWest    = 200
    case nlEast    = 204
    case nlCentral = 205
    case nlWest    = 203

    public var league: League {
        switch self {
        case .alEast, .alCentral, .alWest: return .american
        case .nlEast, .nlCentral, .nlWest: return .national
        }
    }

    public var displayName: String {
        switch self {
        case .alEast:    return "AL East"
        case .alCentral: return "AL Central"
        case .alWest:    return "AL West"
        case .nlEast:    return "NL East"
        case .nlCentral: return "NL Central"
        case .nlWest:    return "NL West"
        }
    }
}

// MARK: - GameType

public enum GameType: String, Codable, Sendable, Hashable, CaseIterable {
    case springTraining      = "S"
    case regularSeason       = "R"
    case wildCard            = "F"
    case divisionSeries      = "D"
    case leagueChampionship  = "L"
    case worldSeries         = "W"
    case allStar             = "A"

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        self = GameType(rawValue: raw) ?? .regularSeason
    }
}

// MARK: - StatGroup

public enum StatGroup: String, Codable, Sendable, Hashable, CaseIterable {
    case batting
    case pitching
    case fielding

    /// MLB Stats API `group` parameter value.
    var apiValue: String {
        switch self {
        case .batting:  return "hitting"
        case .pitching: return "pitching"
        case .fielding: return "fielding"
        }
    }
}

// MARK: - StatType

public enum StatType: String, Codable, Sendable, Hashable, CaseIterable {
    case season
    case career
    case yearByYear
}

// MARK: - GameStatus

public enum GameStatus: String, Codable, Sendable, Hashable {
    case scheduled   = "Scheduled"
    case warmup      = "Warmup"
    case inProgress  = "In Progress"
    case final       = "Final"
    case postponed   = "Postponed"
    case cancelled   = "Cancelled"
    case suspended   = "Suspended"

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        self = GameStatus(rawValue: raw) ?? .scheduled
    }
}
