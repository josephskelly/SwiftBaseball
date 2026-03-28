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

// MARK: - Catcher Framing Query

/// Query builder for the Baseball Savant catcher framing leaderboard.
///
/// Returns qualified catchers for a given season with their framing runs added above average.
/// Framing value is the primary metric — positive values indicate a catcher who converts
/// borderline pitches into called strikes at an above-average rate.
///
/// ```swift
/// let framing = try await SwiftBaseball
///     .catcherFraming()
///     .season(2024)
///     .fetch()
/// print(framing.first?.framingRunsAdded)  // top framer's run value
/// ```
public struct CatcherFramingQuery: Sendable {
    let client: StatcastAPIClient
    private var seasonYear: Int?
    private var _minPitches: String

    static let defaultMinPitches = "q"

    init(client: StatcastAPIClient) {
        self.client = client
        self._minPitches = Self.defaultMinPitches
    }

    /// Filters to a specific season year.
    public func season(_ year: Int) -> CatcherFramingQuery {
        var copy = self
        copy.seasonYear = year
        return copy
    }

    /// Sets the minimum number of pitches received for inclusion.
    ///
    /// Defaults to qualified (`"q"`). Pass a specific count to include catchers
    /// below the qualified threshold (e.g. `.minPitches(500)`).
    public func minPitches(_ count: Int) -> CatcherFramingQuery {
        var copy = self
        copy._minPitches = String(count)
        return copy
    }

    /// Executes the query and returns catcher framing entries.
    ///
    /// - Returns: An array of ``CatcherFramingEntry`` for all qualified catchers.
    /// - Throws: ``SwiftBaseballError`` if the request or parsing fails.
    public func fetch() async throws -> [CatcherFramingEntry] {
        let year = seasonYear ?? Calendar.current.component(.year, from: Date())
        let csv = try await client.fetchSavantCSV(
            path: "leaderboard/catcher-framing",
            queryItems: buildQueryItems(year: year)
        )
        return CatcherFramingParser.parse(csv, season: year)
    }

    private func buildQueryItems(year: Int) -> [URLQueryItem] {
        [
            URLQueryItem(name: "type", value: "catcher"),
            URLQueryItem(name: "min", value: _minPitches),
            URLQueryItem(name: "year", value: String(year)),
            URLQueryItem(name: "csv", value: "true"),
        ]
    }
}

// MARK: - Catcher Framing Parser

/// Parses Baseball Savant catcher framing leaderboard CSV into ``CatcherFramingEntry`` values.
enum CatcherFramingParser {
    static func parse(_ csv: String, season: Int) -> [CatcherFramingEntry] {
        let rows = CSVParser.parse(csv)
        return rows.compactMap { row -> CatcherFramingEntry? in
            guard
                let idValue = row["id"], let playerId = Int(idValue),
                let name = row["name"], !name.isEmpty,
                let pitchesStr = row["pitches"], let pitches = Int(pitchesStr),
                let rvStr = row["rv_tot"], let framingRuns = Double(rvStr),
                let pctStr = row["pct_tot"], let strikeRate = Double(pctStr)
            else { return nil }

            return CatcherFramingEntry(
                playerId: playerId,
                playerName: name,
                season: season,
                framingRunsAdded: framingRuns,
                calledStrikeRate: strikeRate,
                pitchesSeen: pitches
            )
        }
    }
}

// MARK: - Pop Time Query

/// Query builder for the Baseball Savant catcher pop time leaderboard.
///
/// Returns catchers with a minimum number of steal attempts for a given season.
/// Pop time measures the total elapsed time from pitch receipt to the fielder
/// at 2B (or 3B) receiving the throw.
///
/// ```swift
/// let popTimes = try await SwiftBaseball
///     .catcherPopTime()
///     .season(2024)
///     .fetch()
/// print(popTimes.first?.popTimeTo2B)   // fastest pop time to 2B in seconds
/// print(popTimes.first?.exchangeTime)  // reaction + exchange time in seconds
/// ```
public struct PopTimeQuery: Sendable {
    let client: StatcastAPIClient
    private var seasonYear: Int?
    private var _minAttempts: Int

    static let defaultMinAttempts = 5

    init(client: StatcastAPIClient) {
        self.client = client
        self._minAttempts = Self.defaultMinAttempts
    }

    /// Filters to a specific season year.
    public func season(_ year: Int) -> PopTimeQuery {
        var copy = self
        copy.seasonYear = year
        return copy
    }

    /// Sets the minimum number of steal attempts required for inclusion (default: 5).
    public func minAttempts(_ count: Int) -> PopTimeQuery {
        var copy = self
        copy._minAttempts = count
        return copy
    }

    /// Executes the query and returns pop time entries.
    ///
    /// - Returns: An array of ``PopTimeEntry`` for all catchers meeting the attempt threshold.
    /// - Throws: ``SwiftBaseballError`` if the request or parsing fails.
    public func fetch() async throws -> [PopTimeEntry] {
        let year = seasonYear ?? Calendar.current.component(.year, from: Date())
        let csv = try await client.fetchSavantCSV(
            path: "leaderboard/poptime",
            queryItems: buildQueryItems(year: year)
        )
        return PopTimeParser.parse(csv, season: year)
    }

    private func buildQueryItems(year: Int) -> [URLQueryItem] {
        [
            URLQueryItem(name: "min", value: String(_minAttempts)),
            URLQueryItem(name: "year", value: String(year)),
            URLQueryItem(name: "csv", value: "true"),
        ]
    }
}

// MARK: - Pop Time Parser

/// Parses Baseball Savant pop time leaderboard CSV into ``PopTimeEntry`` values.
enum PopTimeParser {
    static func parse(_ csv: String, season: Int) -> [PopTimeEntry] {
        let rows = CSVParser.parse(csv)
        return rows.compactMap { row -> PopTimeEntry? in
            guard
                let idStr = row["entity_id"], let playerId = Int(idStr),
                let name = row["entity_name"], !name.isEmpty,
                let countStr = row["pop_2b_sba_count"], let throwsTo2B = Int(countStr),
                let popStr = row["pop_2b_sba"], let popTimeTo2B = Double(popStr),
                let exchStr = row["exchange_2b_3b_sba"], let exchangeTime = Double(exchStr),
                let armStr = row["maxeff_arm_2b_3b_sba"], let armStrength = Double(armStr)
            else { return nil }

            let popTimeTo2BOnCS = row["pop_2b_cs"].flatMap(Double.init)
            let popTimeTo2BOnSB = row["pop_2b_sb"].flatMap(Double.init)
            let throwsTo3B = row["pop_3b_sba_count"].flatMap(Int.init)
            let popTimeTo3B = row["pop_3b_sba"].flatMap(Double.init)

            return PopTimeEntry(
                playerId: playerId,
                playerName: name,
                season: season,
                popTimeTo2B: popTimeTo2B,
                throwsTo2B: throwsTo2B,
                exchangeTime: exchangeTime,
                armStrength: armStrength,
                popTimeTo2BOnCS: popTimeTo2BOnCS,
                popTimeTo2BOnSB: popTimeTo2BOnSB,
                popTimeTo3B: popTimeTo3B,
                throwsTo3B: throwsTo3B
            )
        }
    }
}
