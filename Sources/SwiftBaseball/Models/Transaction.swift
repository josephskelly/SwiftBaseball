import Foundation

/// An MLB transaction such as a trade, signing, or roster move.
public struct Transaction: Codable, Sendable, Equatable, Identifiable {
    /// The transaction's unique MLB identifier.
    public let id: Int
    /// The player involved in the transaction.
    public let person: PlayerReference?
    /// The team the player is leaving.
    public let fromTeam: TeamReference?
    /// The team the player is joining.
    public let toTeam: TeamReference?
    /// The date the transaction was announced.
    public let date: Date?
    /// The date the transaction takes effect.
    public let effectiveDate: Date?
    /// The transaction type code (e.g. `"TR"`, `"SGN"`, `"DFA"`).
    public let typeCode: String?
    /// Human-readable transaction type (e.g. `"Trade"`, `"Signing"`).
    public let typeDesc: String?
    /// Full description of the transaction.
    public let description: String?
}
