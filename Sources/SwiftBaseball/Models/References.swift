import Foundation

/// Lightweight team reference embedded in other models.
public struct TeamReference: Codable, Sendable, Equatable, Identifiable {
    public let id: Int
    public let name: String
}

/// Lightweight league reference embedded in other models.
public struct LeagueReference: Codable, Sendable, Equatable, Identifiable {
    public let id: Int
    public let name: String
}

/// Lightweight division reference embedded in other models.
public struct DivisionReference: Codable, Sendable, Equatable, Identifiable {
    public let id: Int
    public let name: String
}

/// Lightweight venue reference embedded in other models.
public struct VenueReference: Codable, Sendable, Equatable, Identifiable {
    public let id: Int
    public let name: String
}

/// Lightweight player reference embedded in other models (e.g. stats splits).
public struct PlayerReference: Codable, Sendable, Equatable, Identifiable {
    public let id: Int
    public let fullName: String
}
