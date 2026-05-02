import Foundation

/// A prospect (or completed pick) in the MLB Rule 4 amateur draft.
///
/// Returned by ``SwiftBaseball/draftProspects(year:)`` (full pool) and
/// ``SwiftBaseball/draftLatest(year:)`` (the most recent pick during a live draft).
public struct DraftProspect: Codable, Sendable, Equatable, Identifiable {
    /// `bisPlayerId` from the MLB Stats API (the canonical draft-prospect identifier;
    /// distinct from `person.id` until the player signs and joins an MLB org).
    public let id: Int
    /// Round the prospect was selected in (the API returns this as a string,
    /// since some rounds are non-numeric — e.g., compensation picks).
    public let pickRound: String
    /// Overall pick number within the entire draft.
    public let pickNumber: Int
    /// Pick number within the round (1-based). `nil` for prospect listings that
    /// haven't been formally slotted.
    public let roundPickNumber: Int?
    /// Player reference. May be `nil` for un-rostered prospects whose person record
    /// hasn't been created yet.
    public let person: PlayerReference?
    /// Team that selected the prospect, or `nil` for unselected prospects.
    public let team: TeamReference?
    /// School the prospect attended at the time of the draft.
    public let school: DraftSchool?
    /// Hometown of the prospect.
    public let home: DraftLocation?
    /// Type of draft (`JR` Rule 4 / June Amateur, etc.).
    public let draftType: CodeDescription?
    /// Whether the prospect has been selected.
    public let isDrafted: Bool
    /// Whether the team passed on this slot.
    public let isPass: Bool
    /// Draft year.
    public let year: Int

    /// Creates a draft prospect record.
    public init(
        id: Int,
        pickRound: String,
        pickNumber: Int,
        roundPickNumber: Int? = nil,
        person: PlayerReference? = nil,
        team: TeamReference? = nil,
        school: DraftSchool? = nil,
        home: DraftLocation? = nil,
        draftType: CodeDescription? = nil,
        isDrafted: Bool = false,
        isPass: Bool = false,
        year: Int
    ) {
        self.id = id
        self.pickRound = pickRound
        self.pickNumber = pickNumber
        self.roundPickNumber = roundPickNumber
        self.person = person
        self.team = team
        self.school = school
        self.home = home
        self.draftType = draftType
        self.isDrafted = isDrafted
        self.isPass = isPass
        self.year = year
    }
}

/// A school referenced on a ``DraftProspect``.
public struct DraftSchool: Codable, Sendable, Equatable {
    /// School name (e.g. `"Tennessee Tech"`).
    public let name: String?
    /// Class abbreviation (e.g. `"4YR SR"`, `"JC J2"`, `"HS"`).
    public let schoolClass: String?
    /// City the school is located in.
    public let city: String?
    /// State / province the school is located in.
    public let state: String?
    /// Country code.
    public let country: String?
}

/// A geographic location (hometown) referenced on a ``DraftProspect``.
public struct DraftLocation: Codable, Sendable, Equatable {
    /// City.
    public let city: String?
    /// State / province.
    public let state: String?
    /// Country code.
    public let country: String?
}

/// Live in-progress draft snapshot.
///
/// Returned by ``SwiftBaseball/draftLatest(year:)``. Useful only while a draft is
/// actively running — outside the draft window, `pick` reflects the final selection
/// of the most recent draft and `nextUp` is empty.
public struct DraftLatest: Codable, Sendable, Equatable {
    /// The pick the API considers most recent, or `nil` if no picks have been made.
    public let pick: DraftProspect?
    /// The most recent overall pick number.
    public let number: Int
    /// Picks that are next on the clock, in order.
    public let nextUp: [DraftProspect]

    /// Creates a draft snapshot.
    public init(pick: DraftProspect?, number: Int, nextUp: [DraftProspect]) {
        self.pick = pick
        self.number = number
        self.nextUp = nextUp
    }
}
