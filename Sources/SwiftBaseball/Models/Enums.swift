import Foundation

// MARK: - Position

/// Defensive position codes used by the MLB Stats API.
///
/// Positions are identified by their scorecard number (1–10) or special codes.
public enum Position: String, Codable, Sendable, Hashable, CaseIterable {
    /// Pitcher (1).
    case pitcher          = "1"
    /// Catcher (2).
    case catcher          = "2"
    /// First base (3).
    case firstBase        = "3"
    /// Second base (4).
    case secondBase       = "4"
    /// Third base (5).
    case thirdBase        = "5"
    /// Shortstop (6).
    case shortstop        = "6"
    /// Left field (7).
    case leftField        = "7"
    /// Center field (8).
    case centerField      = "8"
    /// Right field (9).
    case rightField       = "9"
    /// Designated hitter (10).
    case designatedHitter = "10"
    /// Generic outfield.
    case outfield         = "OF"
    /// Generic infield.
    case infield          = "IF"
    /// Pinch hitter.
    case pinchHitter      = "PH"
    /// Pinch runner.
    case pinchRunner      = "PR"
    /// Two-way player.
    case twoWayPlayer     = "Y"
    /// Unrecognized or missing position.
    case unknown          = "U"

    /// Human-readable display name.
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

/// Batting or throwing hand side.
public enum HandSide: String, Codable, Sendable, Hashable, CaseIterable {
    /// Left-handed.
    case left    = "L"
    /// Right-handed.
    case right   = "R"
    /// Switch hitter or ambidextrous.
    case both    = "S"
    /// Unknown or unspecified.
    case unknown = "U"

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        self = HandSide(rawValue: raw) ?? .unknown
    }
}

// MARK: - League

/// MLB league identifier.
public enum League: String, Codable, Sendable, Hashable, CaseIterable {
    /// American League.
    case american = "AL"
    /// National League.
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

/// MLB division identifier, using the API's numeric IDs as raw values.
public enum Division: Int, Codable, Sendable, Hashable, CaseIterable {
    /// American League East.
    case alEast    = 201
    /// American League Central.
    case alCentral = 202
    /// American League West.
    case alWest    = 200
    /// National League East.
    case nlEast    = 204
    /// National League Central.
    case nlCentral = 205
    /// National League West.
    case nlWest    = 203

    /// The league this division belongs to.
    public var league: League {
        switch self {
        case .alEast, .alCentral, .alWest: return .american
        case .nlEast, .nlCentral, .nlWest: return .national
        }
    }

    /// Human-readable display name (e.g. "AL East").
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

/// Type of MLB game.
public enum GameType: String, Codable, Sendable, Hashable, CaseIterable {
    /// Spring training.
    case springTraining      = "S"
    /// Regular season.
    case regularSeason       = "R"
    /// Wild card round.
    case wildCard            = "F"
    /// Division series (ALDS/NLDS).
    case divisionSeries      = "D"
    /// League championship series (ALCS/NLCS).
    case leagueChampionship  = "L"
    /// World Series.
    case worldSeries         = "W"
    /// All-Star Game.
    case allStar             = "A"
    /// Exhibition game (e.g. MLB team vs minor-league affiliate).
    case exhibition          = "E"
    /// Unrecognized game type returned by the API.
    case unknown             = "U"

    /// Human-readable label for display in UI (e.g. "Spring Training").
    public var displayName: String {
        switch self {
        case .springTraining:     return "Spring Training"
        case .regularSeason:      return "Regular Season"
        case .wildCard:           return "Wild Card"
        case .divisionSeries:     return "Division Series"
        case .leagueChampionship: return "League Championship"
        case .worldSeries:        return "World Series"
        case .allStar:            return "All-Star Game"
        case .exhibition:         return "Exhibition"
        case .unknown:            return "Unknown"
        }
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        self = GameType(rawValue: raw) ?? .unknown
    }
}

// MARK: - RosterType

/// The type of team roster to fetch from the MLB Stats API.
///
/// Use ``active`` for the regular-season 26-man roster. Use ``fortyMan``
/// and ``nonRosterInvitees`` together for spring training or exhibition
/// rosters, where expanded participation rules apply. Use ``fullSeason``
/// for minor league teams to retrieve every player who appeared on the
/// roster at any point during the season.
public enum RosterType: String, Sendable, Hashable, CaseIterable {
    /// The active 26-man roster (default for MLB regular season).
    case active
    /// The 40-man roster — includes players on the IL, optional list, and
    /// other controlled players beyond the active 26.
    case fortyMan = "40Man"
    /// Non-roster spring training invitees (NRIs) who are not on the 40-man.
    case nonRosterInvitees
    /// Full-season roster — every player who appeared for the team during
    /// the season. This is the default roster type for minor league teams.
    case fullSeason
}

// MARK: - StatGroup

/// Category of player statistics.
public enum StatGroup: String, Codable, Sendable, Hashable, CaseIterable {
    /// Batting/hitting statistics.
    case batting
    /// Pitching statistics.
    case pitching
    /// Fielding/defensive statistics.
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

/// Type of statistical aggregation.
public enum StatType: String, Codable, Sendable, Hashable, CaseIterable {
    /// Single season stats.
    case season
    /// Career totals.
    case career
    /// Season-by-season breakdown.
    case yearByYear
    /// Advanced sabermetric stats (wOBA, wRC+, WAR, etc.).
    case sabermetrics
    /// Full-season projected stats (available mid-season for active players).
    case projected
}

// MARK: - Sport

/// MLB and affiliated minor league sport levels.
///
/// Pass to ``QueryBuilder/sport(_:)`` to scope any query to a specific league level.
/// Omitting `.sport()` defaults to MLB (``Sport/mlb``) for all endpoints.
///
///     let stats = try await SwiftBaseball.playerStats(id: 605141)
///         .season(2024)
///         .group(.batting)
///         .sport(.tripleA)
///         .fetch()
public enum Sport: Int, Codable, Sendable, Hashable, CaseIterable {
    /// Major League Baseball (default for all queries).
    case mlb            = 1
    /// Triple-A (AAA) — highest minor league level.
    case tripleA        = 11
    /// Double-A (AA).
    case doubleA        = 12
    /// High-A.
    case highA          = 13
    /// Single-A.
    case singleA        = 14
    /// Rookie level.
    case rookie         = 16
    /// Complex League (ACL / FCL).
    case complexLeague  = 17

    /// Human-readable display name.
    public var displayName: String {
        switch self {
        case .mlb:           return "MLB"
        case .tripleA:       return "Triple-A"
        case .doubleA:       return "Double-A"
        case .highA:         return "High-A"
        case .singleA:       return "Single-A"
        case .rookie:        return "Rookie"
        case .complexLeague: return "Complex League"
        }
    }
}

// MARK: - GameStatus

/// Current status of a game.
public enum GameStatus: String, Codable, Sendable, Hashable, CaseIterable {
    /// Game is scheduled but has not started.
    case scheduled   = "Scheduled"
    /// Teams are warming up.
    case warmup      = "Warmup"
    /// Game is currently being played.
    case inProgress  = "In Progress"
    /// Game has completed.
    case final       = "Final"
    /// Game has been postponed.
    case postponed   = "Postponed"
    /// Game has been cancelled.
    case cancelled   = "Cancelled"
    /// Game has been suspended.
    case suspended      = "Suspended"
    /// Game was completed early (e.g. weather-shortened).
    case completedEarly = "Completed Early"
    /// Game is over; alternative MLB term for a final state.
    case gameOver       = "Game Over"
    /// Game is delayed due to rain or another condition during play.
    case rainDelay      = "Rain Delay"
    /// Game is delayed (generic mid-game delay).
    case delayed        = "Delayed"
    /// Game has a delayed start before first pitch.
    case delayedStart   = "Delayed Start"

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = try container.decode(String.self)
        self = GameStatus(rawValue: raw) ?? .scheduled
    }
}
