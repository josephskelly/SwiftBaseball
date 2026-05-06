import Foundation

// MARK: - Stat catalogs

/// One entry in the `statTypes` catalog (e.g. `season`, `career`, `byMonth`).
public struct MetaStatType: Codable, Sendable, Equatable {
    /// Display name (e.g. `"season"`).
    public let displayName: String
}

/// One entry in the `statGroups` catalog (e.g. `hitting`, `pitching`, `fielding`).
public struct MetaStatGroup: Codable, Sendable, Equatable {
    public let displayName: String
}

/// One entry in the `statFields` catalog (e.g. `standard`, `advanced`).
public struct MetaStatField: Codable, Sendable, Equatable {
    public let name: String
}

/// One entry in the `leagueLeaderTypes` catalog (e.g. `homeRuns`, `battingAverage`).
public struct MetaLeagueLeaderType: Codable, Sendable, Equatable {
    public let displayName: String
}

/// One entry in the `baseballStats` catalog — the canonical list of every stat
/// the MLB Stats API recognizes, with metadata describing which stat groups,
/// org types, and high/low view it appears in.
public struct MetaBaseballStat: Codable, Sendable, Equatable {
    /// Internal stat name (e.g. `"airOuts"`).
    public let name: String
    /// Short query parameter alias used in older MLB endpoints (e.g. `"ao"`).
    public let lookupParam: String?
    /// `true` for counting stats (HR, AB), `false` for rate stats (AVG, OBP).
    public let isCounting: Bool?
    /// Human-readable label for display (e.g. `"Airouts"`).
    public let label: String?
    /// Stat groups this stat appears in (`hitting`, `pitching`, `fielding`).
    public let statGroups: [MetaStatGroup]?
}

// MARK: - Game / roster / standings

/// One entry in the `gameTypes` catalog. Distinct from the SwiftBaseball ``GameType``
/// enum used for query parameters — this captures the upstream metadata verbatim.
public struct MetaGameType: Codable, Sendable, Equatable {
    public let id: String
    public let description: String?
}

/// One entry in the `rosterTypes` catalog (e.g. `40Man`, `active`, `depthChart`).
public struct MetaRosterType: Codable, Sendable, Equatable {
    /// Free-form description of the roster type.
    public let description: String
    /// Internal lookup name (e.g. `"40man"`).
    public let lookupName: String
    /// Query-parameter form used by the standings/roster endpoints (e.g. `"40Man"`).
    public let parameter: String
}

/// One entry in the `standingsTypes` catalog (e.g. `regularSeason`, `wildCard`).
public struct MetaStandingsType: Codable, Sendable, Equatable {
    public let name: String
    public let description: String?
}

// MARK: - Pitch / event / situation

/// One entry in the `pitchTypes` catalog (`FA`/Fastball, `SL`/Slider, etc.).
public struct MetaPitchType: Codable, Sendable, Equatable {
    public let code: String
    public let description: String?
}

/// One entry in the `pitchCodes` catalog — every pitch-call code with its
/// strike/ball/swing/contact attributes (e.g. `S` = Strike – Swinging).
public struct MetaPitchCode: Codable, Sendable, Equatable {
    public let code: String
    public let description: String?
    public let swingStatus: Bool?
    public let swingMissStatus: Bool?
    public let swingContactStatus: Bool?
    public let strikeStatus: Bool?
    public let ballStatus: Bool?
    public let pitchStatus: Bool?
    public let sortOrder: Int?
}

/// One entry in the `eventTypes` catalog — every event code recorded by the
/// MLB scoring system (`single`, `double`, `pickoff_1b`, `defensive_substitution`,
/// etc.) along with whether it's a plate appearance, a hit, or a base-running event.
public struct MetaEventType: Codable, Sendable, Equatable {
    public let code: String
    public let description: String?
    public let plateAppearance: Bool?
    public let hit: Bool?
    public let baseRunningEvent: Bool?
}

/// One entry in the `situationCodes` catalog — the 600+ split situations the MLB
/// API can break stats out by (e.g. `vsR`, `risp`, `late_inning_pressure`).
public struct MetaSituationCode: Codable, Sendable, Equatable {
    public let code: String
    public let description: String?
    public let sortOrder: Int?
    public let navigationMenu: String?
    public let team: Bool?
    public let batting: Bool?
    public let fielding: Bool?
    public let pitching: Bool?
}

// MARK: - Misc

/// One entry in the `positions` catalog. Distinct from the SwiftBaseball ``Position``
/// enum — captures the upstream metadata verbatim including `formalName` and `type`.
public struct MetaPosition: Codable, Sendable, Equatable {
    public let code: String
    public let abbrev: String?
    public let shortName: String?
    public let fullName: String?
    public let formalName: String?
    public let displayName: String?
    public let type: String?
}

/// One entry in the `reviewReasons` catalog (e.g. `A` = Tag play).
public struct MetaReviewReason: Codable, Sendable, Equatable {
    public let code: String
    public let description: String?
}

/// One entry in the `hitTrajectories` catalog (e.g. `bunt_grounder`, `fly_ball`).
public struct MetaHitTrajectory: Codable, Sendable, Equatable {
    public let code: String
    public let description: String?
}

/// One entry in the `logicalEvents` catalog — internal scoring-engine event codes.
public struct MetaLogicalEvent: Codable, Sendable, Equatable {
    public let code: String
}

/// One entry in the `jobTypes` catalog (`UMPR`/Umpire, `SCOR`/Official Scorer, etc.).
public struct MetaJobType: Codable, Sendable, Equatable {
    public let code: String
    public let job: String
    public let sortOrder: Int?
}

/// One entry in the `languages` catalog used by the MLB localization layer.
public struct MetaLanguage: Codable, Sendable, Equatable {
    public let languageId: Int
    public let languageCode: String
    public let name: String
    public let locale: String?
}
