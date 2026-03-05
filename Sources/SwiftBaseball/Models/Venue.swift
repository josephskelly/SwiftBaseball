import Foundation

/// An MLB ballpark or venue.
public struct Venue: Codable, Sendable, Equatable, Identifiable {
    /// MLB venue ID.
    public let id: Int
    /// Venue name (e.g. "Yankee Stadium").
    public let name: String
    /// City where the venue is located.
    public let city: String?
    /// State or province.
    public let state: String?
    /// State abbreviation (e.g. "NY").
    public let stateAbbrev: String?
    /// Country.
    public let country: String?
    /// Seating capacity.
    public let capacity: Int?
    /// Playing surface type (e.g. "Grass", "Artificial").
    public let surface: String?
    /// Roof type (e.g. "Open", "Retractable", "Dome").
    public let roofType: String?
    /// Whether the venue is currently active.
    public let active: Bool?
}
