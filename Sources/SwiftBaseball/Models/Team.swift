import Foundation

public struct Team: Codable, Sendable, Equatable, Identifiable {
    public let id: Int
    public let name: String
    public let teamName: String
    public let locationName: String
    public let abbreviation: String
    public let shortName: String
    public let franchiseName: String?
    public let clubName: String?
    public let season: Int?
    public let firstYearOfPlay: String?
    public let active: Bool
    public let league: LeagueReference
    public let division: DivisionReference
    public let venue: VenueReference
}
