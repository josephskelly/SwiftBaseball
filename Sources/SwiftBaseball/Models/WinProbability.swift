import Foundation

// MARK: - Win Probability

/// A single at-bat's win-probability snapshot.
///
/// Returned by the MLB `/game/{gamePk}/winProbability` endpoint as one entry per
/// completed plate appearance. Each entry carries the team win-probability
/// percentages *after* the play, plus the change attributable to the play
/// (``homeTeamWinProbabilityAdded`` — publicly known as *WPA* under the
/// home-team convention).
///
/// Fetched via ``SwiftBaseball/winProbability(gamePk:)``.
public struct PlayWinProbability: Codable, Sendable, Equatable {
    /// Zero-based index of this at-bat in the game.
    public let atBatIndex: Int
    /// Home team's win probability after this at-bat, as a percentage (0–100).
    public let homeTeamWinProbability: Double
    /// Away team's win probability after this at-bat, as a percentage (0–100).
    public let awayTeamWinProbability: Double
    /// Change in home-team win probability attributable to this at-bat, in
    /// percentage points.
    ///
    /// Positive values favor the home team; negative favor the away team.
    /// This is the *home-team* convention of Win Probability Added (WPA);
    /// flip the sign to get the batter-oriented WPA for an away-team batter.
    public let homeTeamWinProbabilityAdded: Double
    /// Play outcome (event, description, score).
    public let result: PlayResult
    /// Contextual information (inning, half-inning, complete/scoring flags).
    public let about: PlayAbout
    /// Batter–pitcher matchup.
    public let matchup: PlayMatchup
}

// MARK: - Context Metrics

/// Current-state context metrics for a single game.
///
/// Returned by the MLB `/game/{gamePk}/contextMetrics` endpoint as one snapshot
/// of the current game situation. For a completed game this reflects the final
/// state (the winner at 100%); for a live game it reflects the in-flight
/// situation and updates as the game progresses.
///
/// Fetched via ``SwiftBaseball/contextMetrics(gamePk:)``.
public struct GameContextMetrics: Codable, Sendable, Equatable {
    /// MLB game primary key.
    public let gamePk: Int
    /// Home team's current win probability, as a percentage (0–100).
    public let homeWinProbability: Double
    /// Away team's current win probability, as a percentage (0–100).
    public let awayWinProbability: Double
}
