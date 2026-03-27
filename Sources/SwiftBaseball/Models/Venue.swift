import Foundation

/// An MLB ballpark or venue.
///
/// Returned by ``SwiftBaseball/venues()`` and ``SwiftBaseball/venue(id:)``.
/// Field dimensions and GPS coordinates are populated when the endpoint is
/// called with `hydrate=fieldInfo,location` (the default for both query builders).
public struct Venue: Codable, Sendable, Equatable, Identifiable {
    /// MLB venue ID.
    public let id: Int
    /// Venue name (e.g. `"Yankee Stadium"`).
    public let name: String
    /// City where the venue is located.
    public let city: String?
    /// State or province.
    public let state: String?
    /// State abbreviation (e.g. `"NY"`).
    public let stateAbbrev: String?
    /// Country.
    public let country: String?
    /// Seating capacity.
    public let capacity: Int?
    /// Playing surface type (e.g. `"Grass"`, `"Artificial Turf"`).
    public let surface: String?
    /// Roof type (e.g. `"Open"`, `"Retractable"`, `"Dome"`).
    public let roofType: String?
    /// Whether the venue is currently active.
    public let active: Bool?
    /// Field distances in feet. `nil` when `fieldInfo` hydration is unavailable.
    public let dimensions: FieldDimensions?
    /// GPS coordinates of the venue. `nil` when `location` hydration is unavailable.
    public let coordinates: Coordinates?
}

/// Field distances in feet for an MLB venue.
///
/// Not all parks report every measurement — optional fields are `nil` when the
/// MLB Stats API does not include them.
public struct FieldDimensions: Codable, Sendable, Equatable {
    /// Distance down the left-field foul line.
    public let leftLine: Int?
    /// Distance to left field (between the line and left-center).
    public let left: Int?
    /// Distance to left-center field.
    public let leftCenter: Int?
    /// Distance to straightaway center field.
    public let center: Int?
    /// Distance to right-center field.
    public let rightCenter: Int?
    /// Distance to right field (between right-center and the line).
    public let right: Int?
    /// Distance down the right-field foul line.
    public let rightLine: Int?
}

/// GPS coordinates for an MLB venue.
public struct Coordinates: Codable, Sendable, Equatable {
    /// Latitude in decimal degrees.
    public let latitude: Double
    /// Longitude in decimal degrees.
    public let longitude: Double
}
