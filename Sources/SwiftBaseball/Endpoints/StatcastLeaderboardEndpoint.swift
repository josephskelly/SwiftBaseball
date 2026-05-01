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
            path: "leaderboard/sprint_speed",
            queryItems: buildQueryItems()
        )
        return SprintSpeedParser.parse(csv, season: seasonYear ?? Calendar.current.component(.year, from: Date()))
    }

    private func buildQueryItems() -> [URLQueryItem] {
        var items: [URLQueryItem] = [
            URLQueryItem(name: "min_opp", value: String(_minAttempts)),
            URLQueryItem(name: "position", value: ""),
            URLQueryItem(name: "team", value: ""),
            URLQueryItem(name: "csv", value: "true")
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
            URLQueryItem(name: "csv", value: "true")
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
                let team = row["team"],
                let speedStr = row["sprint_speed"], let speed = Double(speedStr)
            else { return nil }

            // CSV header is the quoted string "last_name, first_name"
            let name = row["last_name, first_name"] ?? ""
            let attempts = row["competitive_runs"].flatMap(Int.init) ?? 0
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
            URLQueryItem(name: "csv", value: "true")
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
            URLQueryItem(name: "csv", value: "true")
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

// MARK: - Expected Stats — Batter

/// Query builder for the Baseball Savant batter expected-statistics leaderboard.
///
/// Returns qualified hitters for a given season with actual and expected slash-line
/// metrics (BA / SLG / wOBA) plus the diff between them.
///
/// ```swift
/// let xstats = try await SwiftBaseball
///     .expectedStatsBatter()
///     .season(2024)
///     .fetch()
/// print(xstats.first?.expectedWOBA)
/// ```
public struct ExpectedStatsBatterQuery: Sendable {
    let client: StatcastAPIClient
    private var seasonYear: Int?

    init(client: StatcastAPIClient) {
        self.client = client
    }

    /// Filters to a specific season year.
    public func season(_ year: Int) -> ExpectedStatsBatterQuery {
        var copy = self
        copy.seasonYear = year
        return copy
    }

    /// Executes the query and returns batter expected-stats entries.
    ///
    /// - Returns: An array of ``ExpectedStatsBatterEntry`` for all qualified batters.
    /// - Throws: ``SwiftBaseballError`` if the request or parsing fails.
    public func fetch() async throws -> [ExpectedStatsBatterEntry] {
        let year = seasonYear ?? Calendar.current.component(.year, from: Date())
        let csv = try await client.fetchSavantCSV(
            path: "leaderboard/expected_statistics",
            queryItems: [
                URLQueryItem(name: "type", value: "batter"),
                URLQueryItem(name: "year", value: String(year)),
                URLQueryItem(name: "min", value: "q"),
                URLQueryItem(name: "csv", value: "true")
            ]
        )
        return ExpectedStatsBatterParser.parse(csv, season: year)
    }
}

/// Parses Baseball Savant batter expected-stats CSV into ``ExpectedStatsBatterEntry`` values.
enum ExpectedStatsBatterParser {
    static func parse(_ csv: String, season: Int) -> [ExpectedStatsBatterEntry] {
        let rows = CSVParser.parse(csv)
        return rows.compactMap { row -> ExpectedStatsBatterEntry? in
            guard
                let idStr = row["player_id"], let playerId = Int(idStr),
                let paStr = row["pa"], let pa = Int(paStr),
                let bipStr = row["bip"], let bip = Int(bipStr),
                let baStr = row["ba"], let ba = Double(baStr),
                let xbaStr = row["est_ba"], let xba = Double(xbaStr),
                let baDiffStr = row["est_ba_minus_ba_diff"], let baDiff = Double(baDiffStr),
                let slgStr = row["slg"], let slg = Double(slgStr),
                let xslgStr = row["est_slg"], let xslg = Double(xslgStr),
                let slgDiffStr = row["est_slg_minus_slg_diff"], let slgDiff = Double(slgDiffStr),
                let wobaStr = row["woba"], let woba = Double(wobaStr),
                let xwobaStr = row["est_woba"], let xwoba = Double(xwobaStr),
                let wobaDiffStr = row["est_woba_minus_woba_diff"], let wobaDiff = Double(wobaDiffStr)
            else { return nil }

            let name = row["last_name, first_name"] ?? row["player_name"] ?? ""

            return ExpectedStatsBatterEntry(
                playerId: playerId,
                playerName: name,
                season: season,
                plateAppearances: pa,
                battedBalls: bip,
                battingAverage: ba,
                expectedBattingAverage: xba,
                expectedBABIPDiff: baDiff,
                slugging: slg,
                expectedSlugging: xslg,
                expectedSluggingDiff: slgDiff,
                wOBA: woba,
                expectedWOBA: xwoba,
                expectedWOBADiff: wobaDiff
            )
        }
    }
}

// MARK: - Expected Stats — Pitcher

/// Query builder for the Baseball Savant pitcher expected-statistics leaderboard.
///
/// Returns qualified pitchers for a given season with actual and expected slash-line
/// against, plus actual ERA vs xERA.
///
/// ```swift
/// let xstats = try await SwiftBaseball
///     .expectedStatsPitcher()
///     .season(2024)
///     .fetch()
/// print(xstats.first?.expectedERA)
/// ```
public struct ExpectedStatsPitcherQuery: Sendable {
    let client: StatcastAPIClient
    private var seasonYear: Int?

    init(client: StatcastAPIClient) {
        self.client = client
    }

    /// Filters to a specific season year.
    public func season(_ year: Int) -> ExpectedStatsPitcherQuery {
        var copy = self
        copy.seasonYear = year
        return copy
    }

    /// Executes the query and returns pitcher expected-stats entries.
    ///
    /// - Returns: An array of ``ExpectedStatsPitcherEntry`` for all qualified pitchers.
    /// - Throws: ``SwiftBaseballError`` if the request or parsing fails.
    public func fetch() async throws -> [ExpectedStatsPitcherEntry] {
        let year = seasonYear ?? Calendar.current.component(.year, from: Date())
        let csv = try await client.fetchSavantCSV(
            path: "leaderboard/expected_statistics",
            queryItems: [
                URLQueryItem(name: "type", value: "pitcher"),
                URLQueryItem(name: "year", value: String(year)),
                URLQueryItem(name: "min", value: "q"),
                URLQueryItem(name: "csv", value: "true")
            ]
        )
        return ExpectedStatsPitcherParser.parse(csv, season: year)
    }
}

/// Parses Baseball Savant pitcher expected-stats CSV into ``ExpectedStatsPitcherEntry`` values.
enum ExpectedStatsPitcherParser {
    static func parse(_ csv: String, season: Int) -> [ExpectedStatsPitcherEntry] {
        let rows = CSVParser.parse(csv)
        return rows.compactMap { row -> ExpectedStatsPitcherEntry? in
            guard
                let idStr = row["player_id"], let playerId = Int(idStr),
                let paStr = row["pa"], let pa = Int(paStr),
                let bipStr = row["bip"], let bip = Int(bipStr),
                let baStr = row["ba"], let ba = Double(baStr),
                let xbaStr = row["est_ba"], let xba = Double(xbaStr),
                let baDiffStr = row["est_ba_minus_ba_diff"], let baDiff = Double(baDiffStr),
                let slgStr = row["slg"], let slg = Double(slgStr),
                let xslgStr = row["est_slg"], let xslg = Double(xslgStr),
                let slgDiffStr = row["est_slg_minus_slg_diff"], let slgDiff = Double(slgDiffStr),
                let wobaStr = row["woba"], let woba = Double(wobaStr),
                let xwobaStr = row["est_woba"], let xwoba = Double(xwobaStr),
                let wobaDiffStr = row["est_woba_minus_woba_diff"], let wobaDiff = Double(wobaDiffStr)
            else { return nil }

            let name = row["last_name, first_name"] ?? row["player_name"] ?? ""
            let era = row["era"].flatMap(Double.init)
            let xera = row["xera"].flatMap(Double.init)
            let eraDiff = row["era_minus_xera_diff"].flatMap(Double.init)

            return ExpectedStatsPitcherEntry(
                playerId: playerId,
                playerName: name,
                season: season,
                plateAppearances: pa,
                battedBalls: bip,
                battingAverage: ba,
                expectedBattingAverage: xba,
                expectedBABIPDiff: baDiff,
                slugging: slg,
                expectedSlugging: xslg,
                expectedSluggingDiff: slgDiff,
                wOBA: woba,
                expectedWOBA: xwoba,
                expectedWOBADiff: wobaDiff,
                era: era,
                expectedERA: xera,
                expectedERADiff: eraDiff
            )
        }
    }
}

// MARK: - Percentile Ranks — Batter

/// Query builder for the Baseball Savant batter percentile-rankings leaderboard.
///
/// Returns 1–99 percentile ranks for each tracked metric, scored against the
/// qualifying batter pool for the season. Empty cells in the source CSV
/// (e.g. a corner outfielder with no qualifying competitive sprints) become `nil`.
public struct PercentileRanksBatterQuery: Sendable {
    let client: StatcastAPIClient
    private var seasonYear: Int?

    init(client: StatcastAPIClient) {
        self.client = client
    }

    /// Filters to a specific season year.
    public func season(_ year: Int) -> PercentileRanksBatterQuery {
        var copy = self
        copy.seasonYear = year
        return copy
    }

    /// Executes the query and returns batter percentile-rank entries.
    ///
    /// - Returns: An array of ``PercentileRanksBatterEntry``.
    /// - Throws: ``SwiftBaseballError`` if the request or parsing fails.
    public func fetch() async throws -> [PercentileRanksBatterEntry] {
        let year = seasonYear ?? Calendar.current.component(.year, from: Date())
        let csv = try await client.fetchSavantCSV(
            path: "leaderboard/percentile-rankings",
            queryItems: [
                URLQueryItem(name: "type", value: "batter"),
                URLQueryItem(name: "year", value: String(year)),
                URLQueryItem(name: "csv", value: "true")
            ]
        )
        return PercentileRanksBatterParser.parse(csv, season: year)
    }
}

/// Parses Baseball Savant batter percentile-rankings CSV into ``PercentileRanksBatterEntry`` values.
enum PercentileRanksBatterParser {
    static func parse(_ csv: String, season: Int) -> [PercentileRanksBatterEntry] {
        let rows = CSVParser.parse(csv)
        return rows.compactMap { row -> PercentileRanksBatterEntry? in
            guard
                let idStr = row["player_id"], let playerId = Int(idStr),
                let name = row["player_name"] ?? row["last_name, first_name"], !name.isEmpty
            else { return nil }

            return PercentileRanksBatterEntry(
                playerId: playerId,
                playerName: name,
                season: season,
                xwOBAPercentile: row["xwoba"].flatMap(Int.init),
                xBAPercentile: row["xba"].flatMap(Int.init),
                xSLGPercentile: row["xslg"].flatMap(Int.init),
                xISOPercentile: row["xiso"].flatMap(Int.init),
                xOBPPercentile: row["xobp"].flatMap(Int.init),
                barrelsPercentile: row["brl"].flatMap(Int.init),
                barrelRatePercentile: row["brl_percent"].flatMap(Int.init),
                exitVelocityPercentile: row["exit_velocity"].flatMap(Int.init),
                maxExitVelocityPercentile: row["max_ev"].flatMap(Int.init),
                hardHitPercentile: row["hard_hit_percent"].flatMap(Int.init),
                strikeoutPercentile: row["k_percent"].flatMap(Int.init),
                walkPercentile: row["bb_percent"].flatMap(Int.init),
                whiffPercentile: row["whiff_percent"].flatMap(Int.init),
                chasePercentile: row["chase_percent"].flatMap(Int.init),
                armStrengthPercentile: row["arm_strength"].flatMap(Int.init),
                sprintSpeedPercentile: row["sprint_speed"].flatMap(Int.init),
                oaaPercentile: row["oaa"].flatMap(Int.init),
                batSpeedPercentile: row["bat_speed"].flatMap(Int.init),
                squaredUpRatePercentile: row["squared_up_rate"].flatMap(Int.init),
                swingLengthPercentile: row["swing_length"].flatMap(Int.init)
            )
        }
    }
}

// MARK: - Percentile Ranks — Pitcher

/// Query builder for the Baseball Savant pitcher percentile-rankings leaderboard.
public struct PercentileRanksPitcherQuery: Sendable {
    let client: StatcastAPIClient
    private var seasonYear: Int?

    init(client: StatcastAPIClient) {
        self.client = client
    }

    /// Filters to a specific season year.
    public func season(_ year: Int) -> PercentileRanksPitcherQuery {
        var copy = self
        copy.seasonYear = year
        return copy
    }

    /// Executes the query and returns pitcher percentile-rank entries.
    ///
    /// - Returns: An array of ``PercentileRanksPitcherEntry``.
    /// - Throws: ``SwiftBaseballError`` if the request or parsing fails.
    public func fetch() async throws -> [PercentileRanksPitcherEntry] {
        let year = seasonYear ?? Calendar.current.component(.year, from: Date())
        let csv = try await client.fetchSavantCSV(
            path: "leaderboard/percentile-rankings",
            queryItems: [
                URLQueryItem(name: "type", value: "pitcher"),
                URLQueryItem(name: "year", value: String(year)),
                URLQueryItem(name: "csv", value: "true")
            ]
        )
        return PercentileRanksPitcherParser.parse(csv, season: year)
    }
}

/// Parses Baseball Savant pitcher percentile-rankings CSV into ``PercentileRanksPitcherEntry`` values.
enum PercentileRanksPitcherParser {
    static func parse(_ csv: String, season: Int) -> [PercentileRanksPitcherEntry] {
        let rows = CSVParser.parse(csv)
        return rows.compactMap { row -> PercentileRanksPitcherEntry? in
            guard
                let idStr = row["player_id"], let playerId = Int(idStr),
                let name = row["player_name"] ?? row["last_name, first_name"], !name.isEmpty
            else { return nil }

            return PercentileRanksPitcherEntry(
                playerId: playerId,
                playerName: name,
                season: season,
                xwOBAPercentile: row["xwoba"].flatMap(Int.init),
                xBAPercentile: row["xba"].flatMap(Int.init),
                xSLGPercentile: row["xslg"].flatMap(Int.init),
                xISOPercentile: row["xiso"].flatMap(Int.init),
                xOBPPercentile: row["xobp"].flatMap(Int.init),
                barrelsPercentile: row["brl"].flatMap(Int.init),
                barrelRatePercentile: row["brl_percent"].flatMap(Int.init),
                exitVelocityPercentile: row["exit_velocity"].flatMap(Int.init),
                maxExitVelocityPercentile: row["max_ev"].flatMap(Int.init),
                hardHitPercentile: row["hard_hit_percent"].flatMap(Int.init),
                strikeoutPercentile: row["k_percent"].flatMap(Int.init),
                walkPercentile: row["bb_percent"].flatMap(Int.init),
                whiffPercentile: row["whiff_percent"].flatMap(Int.init),
                chasePercentile: row["chase_percent"].flatMap(Int.init),
                armStrengthPercentile: row["arm_strength"].flatMap(Int.init),
                xERAPercentile: row["xera"].flatMap(Int.init),
                fastballVelocityPercentile: row["fb_velocity"].flatMap(Int.init),
                fastballSpinPercentile: row["fb_spin"].flatMap(Int.init),
                curveSpinPercentile: row["curve_spin"].flatMap(Int.init)
            )
        }
    }
}

// MARK: - Exit Velocity & Barrels — Batter

/// Query builder for the Baseball Savant batter exit-velocity & barrels leaderboard.
///
/// Returns the contact-quality summary for qualified hitters: average and max EV,
/// hard-hit rate, sweet-spot rate, barrels, and barrel rates.
public struct ExitVeloBarrelsBatterQuery: Sendable {
    let client: StatcastAPIClient
    private var seasonYear: Int?

    init(client: StatcastAPIClient) {
        self.client = client
    }

    /// Filters to a specific season year.
    public func season(_ year: Int) -> ExitVeloBarrelsBatterQuery {
        var copy = self
        copy.seasonYear = year
        return copy
    }

    /// Executes the query and returns batter exit-velo / barrel entries.
    public func fetch() async throws -> [ExitVeloBarrelsBatterEntry] {
        let year = seasonYear ?? Calendar.current.component(.year, from: Date())
        let csv = try await client.fetchSavantCSV(
            path: "leaderboard/statcast",
            queryItems: [
                URLQueryItem(name: "type", value: "batter"),
                URLQueryItem(name: "year", value: String(year)),
                URLQueryItem(name: "min", value: "q"),
                URLQueryItem(name: "csv", value: "true")
            ]
        )
        return ExitVeloBarrelsBatterParser.parse(csv, season: year)
    }
}

/// Parses Baseball Savant batter exit-velo CSV into ``ExitVeloBarrelsBatterEntry`` values.
enum ExitVeloBarrelsBatterParser {
    static func parse(_ csv: String, season: Int) -> [ExitVeloBarrelsBatterEntry] {
        ExitVeloBarrelsParser.parseBatter(csv, season: season)
    }
}

// MARK: - Exit Velocity & Barrels — Pitcher

/// Query builder for the Baseball Savant pitcher exit-velocity & barrels leaderboard.
public struct ExitVeloBarrelsPitcherQuery: Sendable {
    let client: StatcastAPIClient
    private var seasonYear: Int?

    init(client: StatcastAPIClient) {
        self.client = client
    }

    /// Filters to a specific season year.
    public func season(_ year: Int) -> ExitVeloBarrelsPitcherQuery {
        var copy = self
        copy.seasonYear = year
        return copy
    }

    /// Executes the query and returns pitcher exit-velo / barrel entries.
    public func fetch() async throws -> [ExitVeloBarrelsPitcherEntry] {
        let year = seasonYear ?? Calendar.current.component(.year, from: Date())
        let csv = try await client.fetchSavantCSV(
            path: "leaderboard/statcast",
            queryItems: [
                URLQueryItem(name: "type", value: "pitcher"),
                URLQueryItem(name: "year", value: String(year)),
                URLQueryItem(name: "min", value: "q"),
                URLQueryItem(name: "csv", value: "true")
            ]
        )
        return ExitVeloBarrelsPitcherParser.parse(csv, season: year)
    }
}

/// Parses Baseball Savant pitcher exit-velo CSV into ``ExitVeloBarrelsPitcherEntry`` values.
enum ExitVeloBarrelsPitcherParser {
    static func parse(_ csv: String, season: Int) -> [ExitVeloBarrelsPitcherEntry] {
        ExitVeloBarrelsParser.parsePitcher(csv, season: season)
    }
}

// MARK: - Exit Velocity & Barrels — shared parser

/// Shared row-parsing logic for the batter and pitcher exit-velo leaderboards
/// (both share an identical CSV column layout).
private enum ExitVeloBarrelsParser {
    static func parseBatter(_ csv: String, season: Int) -> [ExitVeloBarrelsBatterEntry] {
        parseRows(csv).compactMap { core in
            guard let core else { return nil }
            return ExitVeloBarrelsBatterEntry(
                playerId: core.playerId,
                playerName: core.playerName,
                season: season,
                attempts: core.attempts,
                avgLaunchAngle: core.avgLaunchAngle,
                sweetSpotRate: core.sweetSpotRate,
                maxExitVelocity: core.maxExitVelocity,
                avgExitVelocity: core.avgExitVelocity,
                ev50: core.ev50,
                avgExitVelocityFBLD: core.avgExitVelocityFBLD,
                avgExitVelocityGB: core.avgExitVelocityGB,
                maxDistance: core.maxDistance,
                avgDistance: core.avgDistance,
                avgHomeRunDistance: core.avgHomeRunDistance,
                ev95Plus: core.ev95Plus,
                hardHitRate: core.hardHitRate,
                barrels: core.barrels,
                barrelRate: core.barrelRate,
                barrelsPerPA: core.barrelsPerPA
            )
        }
    }

    static func parsePitcher(_ csv: String, season: Int) -> [ExitVeloBarrelsPitcherEntry] {
        parseRows(csv).compactMap { core in
            guard let core else { return nil }
            return ExitVeloBarrelsPitcherEntry(
                playerId: core.playerId,
                playerName: core.playerName,
                season: season,
                attempts: core.attempts,
                avgLaunchAngle: core.avgLaunchAngle,
                sweetSpotRate: core.sweetSpotRate,
                maxExitVelocity: core.maxExitVelocity,
                avgExitVelocity: core.avgExitVelocity,
                ev50: core.ev50,
                avgExitVelocityFBLD: core.avgExitVelocityFBLD,
                avgExitVelocityGB: core.avgExitVelocityGB,
                maxDistance: core.maxDistance,
                avgDistance: core.avgDistance,
                avgHomeRunDistance: core.avgHomeRunDistance,
                ev95Plus: core.ev95Plus,
                hardHitRate: core.hardHitRate,
                barrels: core.barrels,
                barrelRate: core.barrelRate,
                barrelsPerPA: core.barrelsPerPA
            )
        }
    }

    private struct Core {
        let playerId: Int
        let playerName: String
        let attempts: Int
        let avgLaunchAngle: Double
        let sweetSpotRate: Double
        let maxExitVelocity: Double
        let avgExitVelocity: Double
        let ev50: Double
        let avgExitVelocityFBLD: Double
        let avgExitVelocityGB: Double
        let maxDistance: Int
        let avgDistance: Int
        let avgHomeRunDistance: Int?
        let ev95Plus: Int
        let hardHitRate: Double
        let barrels: Int
        let barrelRate: Double
        let barrelsPerPA: Double
    }

    private static func parseRows(_ csv: String) -> [Core?] {
        let rows = CSVParser.parse(csv)
        return rows.map { row -> Core? in
            guard
                let idStr = row["player_id"], let playerId = Int(idStr),
                let attemptsStr = row["attempts"], let attempts = Int(attemptsStr),
                let angleStr = row["avg_hit_angle"], let avgLaunchAngle = Double(angleStr),
                let ssStr = row["anglesweetspotpercent"], let sweetSpotRate = Double(ssStr),
                let maxEvStr = row["max_hit_speed"], let maxExitVelocity = Double(maxEvStr),
                let avgEvStr = row["avg_hit_speed"], let avgExitVelocity = Double(avgEvStr),
                let ev50Str = row["ev50"], let ev50 = Double(ev50Str),
                let fbldStr = row["fbld"], let avgExitVelocityFBLD = Double(fbldStr),
                let gbStr = row["gb"], let avgExitVelocityGB = Double(gbStr),
                let maxDistStr = row["max_distance"], let maxDistance = Int(maxDistStr),
                let avgDistStr = row["avg_distance"], let avgDistance = Int(avgDistStr),
                let ev95Str = row["ev95plus"], let ev95Plus = Int(ev95Str),
                let hardHitStr = row["ev95percent"], let hardHitRate = Double(hardHitStr),
                let barrelsStr = row["barrels"], let barrels = Int(barrelsStr),
                let brlPctStr = row["brl_percent"], let barrelRate = Double(brlPctStr),
                let brlPaStr = row["brl_pa"], let barrelsPerPA = Double(brlPaStr)
            else { return nil }

            let name = row["last_name, first_name"] ?? row["player_name"] ?? ""
            let avgHrDist = row["avg_hr_distance"].flatMap(Int.init)

            return Core(
                playerId: playerId,
                playerName: name,
                attempts: attempts,
                avgLaunchAngle: avgLaunchAngle,
                sweetSpotRate: sweetSpotRate,
                maxExitVelocity: maxExitVelocity,
                avgExitVelocity: avgExitVelocity,
                ev50: ev50,
                avgExitVelocityFBLD: avgExitVelocityFBLD,
                avgExitVelocityGB: avgExitVelocityGB,
                maxDistance: maxDistance,
                avgDistance: avgDistance,
                avgHomeRunDistance: avgHrDist,
                ev95Plus: ev95Plus,
                hardHitRate: hardHitRate,
                barrels: barrels,
                barrelRate: barrelRate,
                barrelsPerPA: barrelsPerPA
            )
        }
    }
}

// MARK: - Pitch Arsenal

/// Query builder for the Baseball Savant `pitch-arsenals` leaderboard.
///
/// The upstream board exposes three different views of every pitcher's repertoire
/// — average velocity, average spin rate, and raw pitch counts — each in its own
/// CSV. Use ``metric(_:)`` to pick which view to fetch (default
/// ``PitchArsenalMetric/velocity``); the response is flattened to one
/// ``PitchArsenalEntry`` per (pitcher, pitch type) so all three views share
/// the same row layout.
///
/// ```swift
/// let velos = try await SwiftBaseball
///     .pitchArsenal()
///     .season(2024)
///     .metric(.velocity)
///     .fetch()
/// print(velos.first?.value)  // top fastball mph
/// ```
public struct PitchArsenalQuery: Sendable {
    let client: StatcastAPIClient
    private var seasonYear: Int?
    private var _metric: PitchArsenalMetric

    init(client: StatcastAPIClient) {
        self.client = client
        self._metric = .velocity
    }

    /// Filters to a specific season year.
    public func season(_ year: Int) -> PitchArsenalQuery {
        var copy = self
        copy.seasonYear = year
        return copy
    }

    /// Selects which arsenal metric to fetch (default: ``PitchArsenalMetric/velocity``).
    public func metric(_ metric: PitchArsenalMetric) -> PitchArsenalQuery {
        var copy = self
        copy._metric = metric
        return copy
    }

    /// Executes the query and returns one entry per (pitcher, pitch type).
    ///
    /// - Returns: An array of ``PitchArsenalEntry`` values flattened from the wide CSV.
    /// - Throws: ``SwiftBaseballError`` if the request or parsing fails.
    public func fetch() async throws -> [PitchArsenalEntry] {
        let year = seasonYear ?? Calendar.current.component(.year, from: Date())
        let savantType = switch _metric {
        case .velocity: "avg_speed"
        case .spin: "avg_spin"
        }
        let csv = try await client.fetchSavantCSV(
            path: "leaderboard/pitch-arsenals",
            queryItems: [
                URLQueryItem(name: "type", value: savantType),
                URLQueryItem(name: "year", value: String(year)),
                URLQueryItem(name: "min", value: "q"),
                URLQueryItem(name: "csv", value: "true")
            ]
        )
        return PitchArsenalParser.parse(csv, season: year, metric: _metric)
    }
}

/// Parses Baseball Savant pitch-arsenals CSV (wide format) into long-format
/// ``PitchArsenalEntry`` values, one per (pitcher × pitch type) cell.
enum PitchArsenalParser {
    /// Statcast pitch-type codes that appear as wide columns in the pitch-arsenals CSV.
    static let pitchTypes = ["FF", "SI", "FC", "SL", "CH", "CU", "FS", "KN", "ST", "SV"]

    static func parse(_ csv: String, season: Int, metric: PitchArsenalMetric) -> [PitchArsenalEntry] {
        let suffix = switch metric {
        case .velocity: "_avg_speed"
        case .spin: "_avg_spin"
        }
        let rows = CSVParser.parse(csv)
        var entries: [PitchArsenalEntry] = []
        for row in rows {
            guard let idStr = row["pitcher"], let pitcherId = Int(idStr) else { continue }
            let name = row["last_name, first_name"] ?? row["player_name"] ?? ""
            for pitchType in pitchTypes {
                let columnKey = pitchType.lowercased() + suffix
                guard
                    let raw = row[columnKey],
                    !raw.isEmpty,
                    let value = Double(raw)
                else { continue }
                entries.append(PitchArsenalEntry(
                    pitcherId: pitcherId,
                    pitcherName: name,
                    season: season,
                    pitchType: pitchType,
                    metric: metric,
                    value: value
                ))
            }
        }
        return entries
    }
}

// MARK: - Pitch Arsenal Stats

/// Query builder for the Baseball Savant `pitch-arsenal-stats` leaderboard.
///
/// Returns one row per pitcher × pitch type with run value, swing-and-miss, and
/// quality-of-contact outcomes. Use ``minPlateAppearances(_:)`` to relax the
/// default threshold of 25 PA per pitch type.
///
/// ```swift
/// let stats = try await SwiftBaseball
///     .pitchArsenalStats()
///     .season(2024)
///     .fetch()
/// print(stats.first?.runValuePer100)
/// ```
public struct PitchArsenalStatsQuery: Sendable {
    let client: StatcastAPIClient
    private var seasonYear: Int?
    private var _minPA: Int

    static let defaultMinPA = 25

    init(client: StatcastAPIClient, minPA: Int = defaultMinPA) {
        self.client = client
        self._minPA = minPA
    }

    /// Filters to a specific season year.
    public func season(_ year: Int) -> PitchArsenalStatsQuery {
        var copy = self
        copy.seasonYear = year
        return copy
    }

    /// Sets the minimum plate appearances per pitch type required for inclusion
    /// (default: ``defaultMinPA``).
    public func minPlateAppearances(_ count: Int) -> PitchArsenalStatsQuery {
        var copy = self
        copy._minPA = count
        return copy
    }

    /// Executes the query and returns per-pitch outcome entries.
    ///
    /// - Returns: An array of ``PitchArsenalStatsEntry`` rows.
    /// - Throws: ``SwiftBaseballError`` if the request or parsing fails.
    public func fetch() async throws -> [PitchArsenalStatsEntry] {
        let year = seasonYear ?? Calendar.current.component(.year, from: Date())
        let csv = try await client.fetchSavantCSV(
            path: "leaderboard/pitch-arsenal-stats",
            queryItems: [
                URLQueryItem(name: "year", value: String(year)),
                URLQueryItem(name: "min_pa", value: String(_minPA)),
                URLQueryItem(name: "csv", value: "true")
            ]
        )
        return PitchArsenalStatsParser.parse(csv, season: year)
    }
}

/// Parses Baseball Savant pitch-arsenal-stats CSV into ``PitchArsenalStatsEntry`` values.
enum PitchArsenalStatsParser {
    static func parse(_ csv: String, season: Int) -> [PitchArsenalStatsEntry] {
        let rows = CSVParser.parse(csv)
        return rows.compactMap { row -> PitchArsenalStatsEntry? in
            guard
                let idStr = row["player_id"], let playerId = Int(idStr),
                let team = row["team_name_alt"],
                let pitchType = row["pitch_type"],
                let pitchName = row["pitch_name"],
                let rvStr = row["run_value_per_100"], let rv100 = Double(rvStr),
                let rvTotalStr = row["run_value"], let rvTotal = Int(rvTotalStr),
                let pitchesStr = row["pitches"], let pitches = Int(pitchesStr),
                let usageStr = row["pitch_usage"], let usage = Double(usageStr),
                let paStr = row["pa"], let pa = Int(paStr),
                let baStr = row["ba"], let ba = Double(baStr),
                let slgStr = row["slg"], let slg = Double(slgStr),
                let wobaStr = row["woba"], let woba = Double(wobaStr),
                let whiffStr = row["whiff_percent"], let whiff = Double(whiffStr),
                let kStr = row["k_percent"], let kRate = Double(kStr),
                let putAwayStr = row["put_away"], let putAway = Double(putAwayStr),
                let xbaStr = row["est_ba"], let xba = Double(xbaStr),
                let xslgStr = row["est_slg"], let xslg = Double(xslgStr),
                let xwobaStr = row["est_woba"], let xwoba = Double(xwobaStr),
                let hhStr = row["hard_hit_percent"], let hh = Double(hhStr)
            else { return nil }

            let name = row["last_name, first_name"] ?? row["player_name"] ?? ""

            return PitchArsenalStatsEntry(
                playerId: playerId,
                playerName: name,
                season: season,
                team: team,
                pitchType: pitchType,
                pitchName: pitchName,
                runValuePer100: rv100,
                runValue: rvTotal,
                pitches: pitches,
                pitchUsage: usage,
                plateAppearances: pa,
                battingAverage: ba,
                slugging: slg,
                wOBA: woba,
                whiffRate: whiff,
                strikeoutRate: kRate,
                putAwayRate: putAway,
                expectedBattingAverage: xba,
                expectedSlugging: xslg,
                expectedWOBA: xwoba,
                hardHitRate: hh
            )
        }
    }
}

// MARK: - Pitch Movement

/// Query builder for the Baseball Savant `pitch-movement` leaderboard.
///
/// Returns one row per pitcher × pitch type with vertical and horizontal movement
/// expressed both as raw inches and as differentials versus the league average for
/// the same pitch type and velocity (with percentile ranks of those differentials).
///
/// ```swift
/// let movement = try await SwiftBaseball
///     .pitchMovement()
///     .season(2024)
///     .fetch()
/// print(movement.first?.diffZ)  // most rise vs league
/// ```
public struct PitchMovementQuery: Sendable {
    let client: StatcastAPIClient
    private var seasonYear: Int?

    init(client: StatcastAPIClient) {
        self.client = client
    }

    /// Filters to a specific season year.
    public func season(_ year: Int) -> PitchMovementQuery {
        var copy = self
        copy.seasonYear = year
        return copy
    }

    /// Executes the query and returns pitch-movement entries.
    ///
    /// - Returns: An array of ``PitchMovementEntry`` rows.
    /// - Throws: ``SwiftBaseballError`` if the request or parsing fails.
    public func fetch() async throws -> [PitchMovementEntry] {
        let year = seasonYear ?? Calendar.current.component(.year, from: Date())
        let csv = try await client.fetchSavantCSV(
            path: "leaderboard/pitch-movement",
            queryItems: [
                URLQueryItem(name: "year", value: String(year)),
                URLQueryItem(name: "csv", value: "true")
            ]
        )
        return PitchMovementParser.parse(csv, season: year)
    }
}

// MARK: - Active Spin

/// Query builder for the Baseball Savant `active-spin` leaderboard.
///
/// "Active spin" is the share of a pitch's spin that contributes to its movement
/// (as opposed to gyro spin, which doesn't move the ball). The upstream CSV is
/// wide — one column per pitch type. This query flattens to one entry per
/// (pitcher × pitch type) the pitcher actually throws.
///
/// ```swift
/// let entries = try await SwiftBaseball
///     .activeSpin()
///     .season(2024)
///     .fetch()
/// print(entries.first?.activeSpinPercent)  // 0–100 scale
/// ```
public struct ActiveSpinQuery: Sendable {
    let client: StatcastAPIClient
    private var seasonYear: Int?

    init(client: StatcastAPIClient) {
        self.client = client
    }

    /// Filters to a specific season year.
    public func season(_ year: Int) -> ActiveSpinQuery {
        var copy = self
        copy.seasonYear = year
        return copy
    }

    /// Executes the query and returns one entry per (pitcher × pitch type).
    ///
    /// - Returns: An array of ``ActiveSpinEntry`` values flattened from the wide CSV.
    /// - Throws: ``SwiftBaseballError`` if the request or parsing fails.
    public func fetch() async throws -> [ActiveSpinEntry] {
        let year = seasonYear ?? Calendar.current.component(.year, from: Date())
        let csv = try await client.fetchSavantCSV(
            path: "leaderboard/active-spin",
            queryItems: [
                URLQueryItem(name: "year", value: String(year)),
                URLQueryItem(name: "csv", value: "true")
            ]
        )
        return ActiveSpinParser.parse(csv, season: year)
    }
}

/// Parses Baseball Savant active-spin CSV (wide format) into long-format
/// ``ActiveSpinEntry`` values, one per (pitcher × pitch type) cell.
enum ActiveSpinParser {
    /// Mapping from the Savant active-spin column suffix to the Statcast pitch-type code.
    static let pitchTypeMap: [(suffix: String, code: String)] = [
        ("fourseam", "FF"),
        ("sinker", "SI"),
        ("cutter", "FC"),
        ("changeup", "CH"),
        ("splitter", "FS"),
        ("curve", "CU"),
        ("slider", "SL"),
        ("sweeper", "ST"),
        ("slurve", "SV")
    ]

    static func parse(_ csv: String, season: Int) -> [ActiveSpinEntry] {
        let rows = CSVParser.parse(csv)
        var entries: [ActiveSpinEntry] = []
        for row in rows {
            guard
                let idStr = row["entity_id"], let pitcherId = Int(idStr),
                let name = row["entity_name"], !name.isEmpty,
                let hand = row["pitch_hand"]
            else { continue }
            for (suffix, code) in pitchTypeMap {
                let key = "active_spin_" + suffix
                guard
                    let raw = row[key], !raw.isEmpty,
                    let value = Double(raw)
                else { continue }
                entries.append(ActiveSpinEntry(
                    pitcherId: pitcherId,
                    pitcherName: name,
                    pitchHand: hand,
                    season: season,
                    pitchType: code,
                    activeSpinPercent: value
                ))
            }
        }
        return entries
    }
}

// MARK: - Running Splits

/// Query builder for the Baseball Savant `running_splits` leaderboard.
///
/// Returns cumulative split times at every 5-foot mark from 0 to 90 ft (home to first
/// distance) on competitive runs. Switch-hitters appear once per side of the plate.
///
/// ```swift
/// let splits = try await SwiftBaseball
///     .runningSplits()
///     .season(2024)
///     .fetch()
/// print(splits.first?.secondsTo90ft)  // home-to-first time
/// ```
public struct RunningSplitsQuery: Sendable {
    let client: StatcastAPIClient
    private var seasonYear: Int?

    init(client: StatcastAPIClient) {
        self.client = client
    }

    /// Filters to a specific season year.
    public func season(_ year: Int) -> RunningSplitsQuery {
        var copy = self
        copy.seasonYear = year
        return copy
    }

    /// Executes the query and returns one entry per (player × bat side).
    ///
    /// - Returns: An array of ``RunningSplitsEntry`` values.
    /// - Throws: ``SwiftBaseballError`` if the request or parsing fails.
    public func fetch() async throws -> [RunningSplitsEntry] {
        let year = seasonYear ?? Calendar.current.component(.year, from: Date())
        let csv = try await client.fetchSavantCSV(
            path: "leaderboard/running_splits",
            queryItems: [
                URLQueryItem(name: "year", value: String(year)),
                URLQueryItem(name: "min", value: "1"),
                URLQueryItem(name: "splits_type", value: "raw"),
                URLQueryItem(name: "csv", value: "true")
            ]
        )
        return RunningSplitsParser.parse(csv, season: year)
    }
}

/// Parses Baseball Savant running-splits CSV into ``RunningSplitsEntry`` values.
enum RunningSplitsParser {
    static func parse(_ csv: String, season: Int) -> [RunningSplitsEntry] {
        let rows = CSVParser.parse(csv, preserveEmpty: true)
        return rows.compactMap { row -> RunningSplitsEntry? in
            guard
                let idStr = row["player_id"], let playerId = Int(idStr),
                let team = row["name_abbrev"],
                let position = row["position_name"],
                let ageStr = row["age"], let age = Int(ageStr),
                let batSide = row["bat_side"],
                let zeroStr = row["seconds_since_hit_000"], let zero = Double(zeroStr)
            else { return nil }

            let name = row["last_name, first_name"] ?? ""

            func split(_ feet: Int) -> Double? {
                let key = String(format: "seconds_since_hit_%03d", feet)
                guard let raw = row[key], !raw.isEmpty else { return nil }
                return Double(raw)
            }

            return RunningSplitsEntry(
                playerId: playerId,
                playerName: name,
                team: team,
                position: position,
                age: age,
                batSide: batSide,
                season: season,
                secondsTo0ft: zero,
                secondsTo5ft: split(5),
                secondsTo10ft: split(10),
                secondsTo15ft: split(15),
                secondsTo20ft: split(20),
                secondsTo25ft: split(25),
                secondsTo30ft: split(30),
                secondsTo35ft: split(35),
                secondsTo40ft: split(40),
                secondsTo45ft: split(45),
                secondsTo50ft: split(50),
                secondsTo55ft: split(55),
                secondsTo60ft: split(60),
                secondsTo65ft: split(65),
                secondsTo70ft: split(70),
                secondsTo75ft: split(75),
                secondsTo80ft: split(80),
                secondsTo85ft: split(85),
                secondsTo90ft: split(90)
            )
        }
    }
}

// MARK: - Bat Tracking

/// Query builder for the Baseball Savant `bat-tracking` leaderboard (2024+).
///
/// Returns per-batter swing mechanics: bat speed, swing length, fast-swing rate,
/// squared-up rate, blast rate, and run value.
///
/// - Important: This board is **2024 and later only**. Older seasons return empty data.
/// - Important: Rate fields are reported on the **0–1 fraction scale** (e.g. `0.85`
///   means 85%), unlike most other Savant leaderboards.
///
/// ```swift
/// let tracking = try await SwiftBaseball
///     .batTracking()
///     .season(2024)
///     .fetch()
/// print(tracking.first?.avgBatSpeed)
/// ```
public struct BatTrackingQuery: Sendable {
    let client: StatcastAPIClient
    private var seasonYear: Int?

    init(client: StatcastAPIClient) {
        self.client = client
    }

    /// Filters to a specific season year.
    public func season(_ year: Int) -> BatTrackingQuery {
        var copy = self
        copy.seasonYear = year
        return copy
    }

    /// Executes the query and returns bat-tracking entries.
    ///
    /// - Returns: An array of ``BatTrackingEntry`` values.
    /// - Throws: ``SwiftBaseballError`` if the request or parsing fails.
    public func fetch() async throws -> [BatTrackingEntry] {
        let year = seasonYear ?? Calendar.current.component(.year, from: Date())
        let csv = try await client.fetchSavantCSV(
            path: "leaderboard/bat-tracking",
            queryItems: [
                URLQueryItem(name: "year", value: String(year)),
                URLQueryItem(name: "min", value: "q"),
                URLQueryItem(name: "attackZone", value: "all"),
                URLQueryItem(name: "csv", value: "true")
            ]
        )
        return BatTrackingParser.parse(csv, season: year)
    }
}

/// Parses Baseball Savant bat-tracking CSV into ``BatTrackingEntry`` values.
enum BatTrackingParser {
    static func parse(_ csv: String, season: Int) -> [BatTrackingEntry] {
        let rows = CSVParser.parse(csv)
        return rows.compactMap { row -> BatTrackingEntry? in
            guard
                let idStr = row["id"], let playerId = Int(idStr),
                let name = row["name"], !name.isEmpty,
                let swingsStr = row["swings_competitive"], let swings = Int(swingsStr),
                let pctSwingsStr = row["percent_swings_competitive"], let pctSwings = Double(pctSwingsStr),
                let contactStr = row["contact"], let contact = Int(contactStr),
                let bsStr = row["avg_bat_speed"], let batSpeed = Double(bsStr),
                let hardStr = row["hard_swing_rate"], let hard = Double(hardStr),
                let suContactStr = row["squared_up_per_bat_contact"], let suContact = Double(suContactStr),
                let suSwingStr = row["squared_up_per_swing"], let suSwing = Double(suSwingStr),
                let blastContactStr = row["blast_per_bat_contact"], let blastContact = Double(blastContactStr),
                let blastSwingStr = row["blast_per_swing"], let blastSwing = Double(blastSwingStr),
                let lengthStr = row["swing_length"], let length = Double(lengthStr),
                let swordsStr = row["swords"], let swords = Int(swordsStr),
                let rvStr = row["batter_run_value"], let rv = Double(rvStr),
                let whiffsStr = row["whiffs"], let whiffs = Int(whiffsStr),
                let whiffPerStr = row["whiff_per_swing"], let whiffPer = Double(whiffPerStr),
                let bbeStr = row["batted_ball_events"], let bbe = Int(bbeStr),
                let bbePerStr = row["batted_ball_event_per_swing"], let bbePer = Double(bbePerStr)
            else { return nil }

            return BatTrackingEntry(
                playerId: playerId,
                playerName: name,
                season: season,
                competitiveSwings: swings,
                competitiveSwingRate: pctSwings,
                contact: contact,
                avgBatSpeed: batSpeed,
                hardSwingRate: hard,
                squaredUpPerContact: suContact,
                squaredUpPerSwing: suSwing,
                blastPerContact: blastContact,
                blastPerSwing: blastSwing,
                avgSwingLength: length,
                swords: swords,
                batterRunValue: rv,
                whiffs: whiffs,
                whiffPerSwing: whiffPer,
                battedBallEvents: bbe,
                battedBallEventPerSwing: bbePer
            )
        }
    }
}

// MARK: - Outfield Catch Probability

/// Query builder for the Baseball Savant `catch_probability` leaderboard.
///
/// Returns one entry per outfielder with a per-star-bucket breakdown of how many
/// fielding opportunities they saw and how many were converted to outs. Catch
/// percentages are reported on the **0–100 scale**.
///
/// ```swift
/// let entries = try await SwiftBaseball
///     .outfieldCatchProbability()
///     .season(2024)
///     .fetch()
/// print(entries.first?.fiveStarCatchPercent)
/// ```
public struct OutfieldCatchProbabilityQuery: Sendable {
    let client: StatcastAPIClient
    private var seasonYear: Int?

    init(client: StatcastAPIClient) {
        self.client = client
    }

    /// Filters to a specific season year.
    public func season(_ year: Int) -> OutfieldCatchProbabilityQuery {
        var copy = self
        copy.seasonYear = year
        return copy
    }

    /// Executes the query and returns one entry per outfielder.
    ///
    /// - Returns: An array of ``OutfieldCatchProbabilityEntry`` values.
    /// - Throws: ``SwiftBaseballError`` if the request or parsing fails.
    public func fetch() async throws -> [OutfieldCatchProbabilityEntry] {
        let year = seasonYear ?? Calendar.current.component(.year, from: Date())
        let csv = try await client.fetchSavantCSV(
            path: "leaderboard/catch_probability",
            queryItems: [
                URLQueryItem(name: "year", value: String(year)),
                URLQueryItem(name: "min", value: "q"),
                URLQueryItem(name: "csv", value: "true")
            ]
        )
        return OutfieldCatchProbabilityParser.parse(csv, season: year)
    }
}

/// Parses Baseball Savant catch-probability CSV into ``OutfieldCatchProbabilityEntry`` values.
enum OutfieldCatchProbabilityParser {
    static func parse(_ csv: String, season: Int) -> [OutfieldCatchProbabilityEntry] {
        let rows = CSVParser.parse(csv, preserveEmpty: true)
        return rows.compactMap { row -> OutfieldCatchProbabilityEntry? in
            guard
                let idStr = row["player_id"], let playerId = Int(idStr),
                let oaaStr = row["oaa"], let oaa = Int(oaaStr)
            else { return nil }

            let name = row["last_name, first_name"] ?? ""

            func intField(_ key: String) -> Int? {
                guard let raw = row[key], !raw.isEmpty else { return nil }
                return Int(raw)
            }
            func optPercent(_ key: String) -> Double? {
                guard let raw = row[key], !raw.isEmpty else { return nil }
                return Double(raw)
            }

            guard
                let fiveOuts = intField("n_fieldout_5stars"),
                let fiveOpp = intField("n_opp_5stars"),
                let fourOuts = intField("n_fieldout_4stars"),
                let fourOpp = intField("n_opp_4stars"),
                let threeOuts = intField("n_fieldout_3stars"),
                let threeOpp = intField("n_opp_3stars"),
                let twoOuts = intField("n_fieldout_2stars"),
                let twoOpp = intField("n_opp_2stars"),
                let oneOuts = intField("n_fieldout_1stars"),
                let oneOpp = intField("n_opp_1stars")
            else { return nil }

            return OutfieldCatchProbabilityEntry(
                playerId: playerId,
                playerName: name,
                season: season,
                outsAboveAverage: oaa,
                fiveStarOuts: fiveOuts,
                fiveStarOpportunities: fiveOpp,
                fiveStarCatchPercent: optPercent("n_5star_percent"),
                fourStarOuts: fourOuts,
                fourStarOpportunities: fourOpp,
                fourStarCatchPercent: optPercent("n_4star_percent"),
                threeStarOuts: threeOuts,
                threeStarOpportunities: threeOpp,
                threeStarCatchPercent: optPercent("n_3star_percent"),
                twoStarOuts: twoOuts,
                twoStarOpportunities: twoOpp,
                twoStarCatchPercent: optPercent("n_2star_percent"),
                oneStarOuts: oneOuts,
                oneStarOpportunities: oneOpp,
                oneStarCatchPercent: optPercent("n_1star_percent")
            )
        }
    }
}

// MARK: - Outfielder Jumps

/// Query builder for the Baseball Savant `outfield_jump` leaderboard.
///
/// Returns one entry per outfielder with three additive distance components — reaction,
/// burst, and routing — measured against league average (signed feet, positive = better).
///
/// ```swift
/// let jumps = try await SwiftBaseball
///     .outfielderJumps()
///     .season(2024)
///     .fetch()
/// print(jumps.first?.relLeagueBurstDistance)
/// ```
public struct OutfielderJumpsQuery: Sendable {
    let client: StatcastAPIClient
    private var seasonYear: Int?

    init(client: StatcastAPIClient) {
        self.client = client
    }

    /// Filters to a specific season year.
    public func season(_ year: Int) -> OutfielderJumpsQuery {
        var copy = self
        copy.seasonYear = year
        return copy
    }

    /// Executes the query and returns one entry per outfielder.
    ///
    /// - Returns: An array of ``OutfielderJumpEntry`` values.
    /// - Throws: ``SwiftBaseballError`` if the request or parsing fails.
    public func fetch() async throws -> [OutfielderJumpEntry] {
        let year = seasonYear ?? Calendar.current.component(.year, from: Date())
        let csv = try await client.fetchSavantCSV(
            path: "leaderboard/outfield_jump",
            queryItems: [
                URLQueryItem(name: "year", value: String(year)),
                URLQueryItem(name: "min", value: "q"),
                URLQueryItem(name: "csv", value: "true")
            ]
        )
        return OutfielderJumpsParser.parse(csv, season: year)
    }
}

/// Parses Baseball Savant outfield-jump CSV into ``OutfielderJumpEntry`` values.
enum OutfielderJumpsParser {
    static func parse(_ csv: String, season: Int) -> [OutfielderJumpEntry] {
        let rows = CSVParser.parse(csv)
        return rows.compactMap { row -> OutfielderJumpEntry? in
            guard
                let idStr = row["resp_fielder_id"], let playerId = Int(idStr),
                let oaaStr = row["outs_above_average"], let oaa = Int(oaaStr),
                let oppStr = row["outs_per_play"], let oppPct = Double(oppStr),
                let burstStr = row["rel_league_burst_distance"], let burst = Double(burstStr),
                let reactStr = row["rel_league_reaction_distance"], let react = Double(reactStr),
                let routeStr = row["rel_league_routing_distance"], let route = Double(routeStr),
                let bootRelStr = row["rel_league_bootup_distance"], let bootRel = Double(bootRelStr),
                let bootAbsStr = row["f_bootup_distance"], let bootAbs = Double(bootAbsStr),
                let nStr = row["n"], let n = Int(nStr),
                let outsStr = row["n_outs"], let outs = Int(outsStr)
            else { return nil }

            let name = row["last_name, first_name"] ?? ""
            let yr = row["year"].flatMap(Int.init) ?? season

            return OutfielderJumpEntry(
                playerId: playerId,
                playerName: name,
                season: yr,
                outsAboveAverage: oaa,
                outsPerPlay: oppPct,
                relLeagueBurstDistance: burst,
                relLeagueReactionDistance: react,
                relLeagueRoutingDistance: route,
                relLeagueBootupDistance: bootRel,
                fBootupDistance: bootAbs,
                opportunities: n,
                outs: outs
            )
        }
    }
}

/// Parses Baseball Savant pitch-movement CSV into ``PitchMovementEntry`` values.
enum PitchMovementParser {
    static func parse(_ csv: String, season: Int) -> [PitchMovementEntry] {
        let rows = CSVParser.parse(csv)
        return rows.compactMap { row -> PitchMovementEntry? in
            guard
                let idStr = row["pitcher_id"], let pitcherId = Int(idStr),
                let team = row["team_name"],
                let teamAbbrev = row["team_name_abbrev"],
                let hand = row["pitch_hand"],
                let avgSpeedStr = row["avg_speed"], let avgSpeed = Double(avgSpeedStr),
                let thrownStr = row["pitches_thrown"], let thrown = Int(thrownStr),
                let totalStr = row["total_pitches"], let total = Int(totalStr),
                let perGameStr = row["pitches_per_game"], let perGame = Double(perGameStr),
                let usageStr = row["pitch_per"], let usage = Double(usageStr),
                let pitchType = row["pitch_type"],
                let pitchTypeName = row["pitch_type_name"],
                let breakZStr = row["pitcher_break_z"], let breakZ = Double(breakZStr),
                let leagueBreakZStr = row["league_break_z"], let leagueBreakZ = Double(leagueBreakZStr),
                let diffZStr = row["diff_z"], let diffZ = Double(diffZStr),
                let riseStr = row["rise"], let rise = Int(riseStr),
                let inducedZStr = row["pitcher_break_z_induced"], let inducedZ = Double(inducedZStr),
                let breakXStr = row["pitcher_break_x"], let breakX = Double(breakXStr),
                let leagueBreakXStr = row["league_break_x"], let leagueBreakX = Double(leagueBreakXStr),
                let diffXStr = row["diff_x"], let diffX = Double(diffXStr),
                let tailStr = row["tail"], let tail = Int(tailStr),
                let prDzStr = row["percent_rank_diff_z"], let prDz = Double(prDzStr),
                let prDxStr = row["percent_rank_diff_x"], let prDx = Double(prDxStr)
            else { return nil }

            let name = row["last_name, first_name"] ?? row["player_name"] ?? ""
            let yr = row["year"].flatMap(Int.init) ?? season

            return PitchMovementEntry(
                pitcherId: pitcherId,
                pitcherName: name,
                season: yr,
                team: team,
                teamAbbreviation: teamAbbrev,
                pitchHand: hand,
                pitchType: pitchType,
                pitchTypeName: pitchTypeName,
                avgSpeed: avgSpeed,
                pitchesThrown: thrown,
                totalPitches: total,
                pitchesPerGame: perGame,
                pitchUsage: usage,
                pitcherBreakZ: breakZ,
                leagueBreakZ: leagueBreakZ,
                diffZ: diffZ,
                rise: rise,
                pitcherBreakZInduced: inducedZ,
                pitcherBreakX: breakX,
                leagueBreakX: leagueBreakX,
                diffX: diffX,
                tail: tail,
                percentRankDiffZ: prDz,
                percentRankDiffX: prDx
            )
        }
    }
}
