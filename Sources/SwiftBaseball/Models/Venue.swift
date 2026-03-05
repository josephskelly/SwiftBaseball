import Foundation

public struct Venue: Codable, Sendable, Equatable, Identifiable {
    public let id: Int
    public let name: String
    public let city: String?
    public let state: String?
    public let stateAbbrev: String?
    public let country: String?
    public let capacity: Int?
    public let surface: String?
    public let roofType: String?
    public let active: Bool?
}
