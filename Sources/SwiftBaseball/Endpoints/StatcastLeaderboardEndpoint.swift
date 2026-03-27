import Foundation

// MARK: - Sprint Speed Query

/// Query builder for the Baseball Savant sprint-speed leaderboard.
///
/// Returns all qualified players for a given season, ordered by sprint speed descending.
/// Sprint speed requires a minimum number of competitive runs; use ``minAttempts(_:)``
/// to adjust the threshold (default 10).
///
/// ```swift
/// let speeds = try await SwiftBaseball
///     .sprintSpeed()
///     .season(2024)
///     .fetch()
/// print(speeds.first?.sprintSpeed)  // fastest player in ft/sec
/// ```
public struct SprintSpeedQuery: Sendable {
    let client: StatcastAPIClient
    private var seasonYear: Int?
    private var _minAttempts: Int

    static let defaultMinAttempts = 10

    init(client: StatcastAPIClient, minAttempts: Int = defaultMinAttempts) {
        self.client = client
        self._minAttempts = minAttempts
    }

    /// Filters to a specific season year.
    public func season(_ year: Int) -> SprintSpeedQuery {
        var copy = self
        copy.seasonYear = year
        return copy
    }

    /// Sets the minimum number of competitive sprint attempts required for inclusion
    /// (default: ``defaultMinAttempts``).
    public func minAttempts(_ count: Int) -> SprintSpeedQuery {
        var copy = self
        copy._minAttempts = count
        return copy
    }

    /// Executes the query and returns sprint speed entries sorted by speed descending.
    ///
    /// - Returns: An array of ``SprintSpeedEntry`` for all qualified players.
    /// - Throws: ``SwiftBaseballError`` if the request or parsing fails.
    public func fetch() async throws -> [SprintSpeedEntry] {
        let csv = try await client.fetchSavantCSV(
            path: "leaderboard/sprint-speed",
            queryItems: buildQueryItems()
        )
        return SprintSpeedParser.parse(csv, season: seasonYear ?? Calendar.current.component(.year, from: Date()))
    }

    private func buildQueryItems() -> [URLQueryItem] {
        var items: [URLQueryItem] = [
            URLQueryItem(name: "min_opp", value: String(_minAttempts)),
            URLQueryItem(name: "position", value: ""),
            URLQueryItem(name: "team", value: ""),
            URLQueryItem(name: "csv", value: "true"),
        ]
        if let year = seasonYear {
            items.append(URLQueryItem(name: "year", value: String(year)))
        }
        return items
    }
}

// MARK: - OAA Query

/// Query builder for the Baseball Savant Outs Above Average (OAA) fielding leaderboard.
///
/// Returns all qualified fielders for a given season, ordered by OAA descending.
/// Use ``position(_:)`` to filter by a specific fielding position.
///
/// ```swift
/// let oaa = try await SwiftBaseball
///     .outsAboveAverage()
///     .season(2024)
///     .fetch()
/// print(oaa.first?.oaa)  // top fielder's OAA
/// ```
public struct OAAQuery: Sendable {
    let client: StatcastAPIClient
    private var seasonYear: Int?
    private var _position: String

    init(client: StatcastAPIClient) {
        self.client = client
        self._position = "all"
    }

    /// Filters to a specific season year.
    public func season(_ year: Int) -> OAAQuery {
        var copy = self
        copy.seasonYear = year
        return copy
    }

    /// Filters to a specific fielding position (e.g. `"SS"`, `"CF"`, `"3B"`).
    /// Pass `"all"` (the default) to include all positions.
    public func position(_ pos: String) -> OAAQuery {
        var copy = self
        copy._position = pos
        return copy
    }

    /// Executes the query and returns OAA entries sorted by OAA descending.
    ///
    /// - Returns: An array of ``OutsAboveAverageEntry`` for all qualified fielders.
    /// - Throws: ``SwiftBaseballError`` if the request or parsing fails.
    public func fetch() async throws -> [OutsAboveAverageEntry] {
        let year = seasonYear ?? Calendar.current.component(.year, from: Date())
        let csv = try await client.fetchSavantCSV(
            path: "leaderboard/outs-above-average",
            queryItems: buildQueryItems(year: year)
        )
        return OAAParser.parse(csv, season: year)
    }

    private func buildQueryItems(year: Int) -> [URLQueryItem] {
        [
            URLQueryItem(name: "type", value: "Fielder"),
            URLQueryItem(name: "startYear", value: String(year)),
            URLQueryItem(name: "endYear", value: String(year)),
            URLQueryItem(name: "split", value: "no"),
            URLQueryItem(name: "team", value: "0"),
            URLQueryItem(name: "range", value: "year"),
            URLQueryItem(name: "min", value: "q"),
            URLQueryItem(name: "pos", value: _position),
            URLQueryItem(name: "csv", value: "true"),
        ]
    }
}

// MARK: - Sprint Speed Parser

/// Parses Baseball Savant sprint-speed leaderboard CSV into ``SprintSpeedEntry`` values.
enum SprintSpeedParser {
    static func parse(_ csv: String, season: Int) -> [SprintSpeedEntry] {
        let rows = CSVParser.parse(csv)
        return rows.compactMap { row -> SprintSpeedEntry? in
            guard
                let idStr = row["player_id"], let playerId = Int(idStr),
                let name = row["player_name"],
                let team = row["team"],
                let speedStr = row["sprint_speed"], let speed = Double(speedStr)
            else { return nil }

            let attempts = row["attempts"].flatMap(Int.init) ?? 0
            let percentile = row["percentile"].flatMap(Int.init)
            let homeToFirst = row["hp_to_1b"].flatMap(Double.init)

            return SprintSpeedEntry(
                playerId: playerId,
                playerName: name,
                team: team,
                season: season,
                sprintSpeed: speed,
                sprintAttempts: attempts,
                percentile: percentile,
                homeToFirst: homeToFirst
            )
        }
    }
}

// MARK: - OAA Parser

/// Parses Baseball Savant OAA leaderboard CSV into ``OutsAboveAverageEntry`` values.
enum OAAParser {
    static func parse(_ csv: String, season: Int) -> [OutsAboveAverageEntry] {
        let rows = CSVParser.parse(csv)
        return rows.compactMap { row -> OutsAboveAverageEntry? in
            guard
                let idStr = row["player_id"], let playerId = Int(idStr),
                let name = row["player_name"],
                let team = row["team"],
                let oaaStr = row["outs_above_average"], let oaa = Double(oaaStr)
            else { return nil }

            let fielderAttempts = row["att_outs_above_avg"].flatMap(Int.init)
            let percentile = row["percentile"].flatMap(Int.init)
            let position = row["pos"].flatMap { $0.isEmpty ? nil : $0 }

            return OutsAboveAverageEntry(
                playerId: playerId,
                playerName: name,
                team: team,
                season: season,
                oaa: oaa,
                fielderAttempts: fielderAttempts,
                percentile: percentile,
                position: position
            )
        }
    }
}
