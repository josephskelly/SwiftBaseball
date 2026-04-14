import Foundation

/// Query builder for Statcast batted ball data from Baseball Savant.
///
/// Unlike MLB Stats API queries, Statcast queries fetch pitch-level CSV data
/// and aggregate it into ``StatcastBatting`` statistics.
///
/// ```swift
/// let stats = try await SwiftBaseball
///     .statcastBatting(playerId: 660271)
///     .season(2024)
///     .fetch()
/// ```
public struct StatcastQuery: Sendable {
    let playerId: Int
    let client: StatcastAPIClient
    private var seasonYear: Int?
    private var startDate: String?
    private var endDate: String?
    private var gameTypeFilter: String?

    init(playerId: Int, client: StatcastAPIClient) {
        self.playerId = playerId
        self.client = client
    }

    /// Filters to a specific season. Sets date range to the full calendar year.
    public func season(_ year: Int) -> StatcastQuery {
        var copy = self
        copy.seasonYear = year
        return copy
    }

    /// Filters to a specific date range in `"YYYY-MM-DD"` format.
    public func dateRange(start: String, end: String) -> StatcastQuery {
        var copy = self
        copy.startDate = start
        copy.endDate = end
        return copy
    }

    /// Filters to a specific game type (e.g. `"R"` for regular season, `"S"` for spring training).
    ///
    /// Savant's CSV endpoint does not filter server-side by game type — it always returns
    /// all rows in the date window. This filter is applied client-side against the
    /// `game_type` column present in every CSV row.
    public func gameType(_ type: String) -> StatcastQuery {
        var copy = self
        copy.gameTypeFilter = type
        return copy
    }

    /// Executes the query and returns aggregated Statcast batting statistics.
    ///
    /// - Returns: Aggregated batted ball profile including GB%, FB%, LD%, exit velocity, and expected stats.
    /// - Throws: ``SwiftBaseballError`` if the request or parsing fails.
    public func fetch() async throws -> StatcastBatting {
        let items = buildQueryItems()
        let csv = try await client.fetchCSV(queryItems: items)
        var rows = CSVParser.parse(csv)
        if let gt = gameTypeFilter {
            rows = rows.filter { $0["game_type"] == gt }
        }
        return StatcastAggregator.aggregate(rows)
    }

    private func buildQueryItems() -> [URLQueryItem] {
        var items = [
            URLQueryItem(name: "all", value: "true"),
            URLQueryItem(name: "type", value: "details"),
            URLQueryItem(name: "batters_lookup[]", value: String(playerId)),
            URLQueryItem(name: "player_type", value: "batter"),
        ]

        if let start = startDate, let end = endDate {
            items.append(URLQueryItem(name: "game_date_gt", value: start))
            items.append(URLQueryItem(name: "game_date_lt", value: end))
        } else if let year = seasonYear {
            items.append(URLQueryItem(name: "game_date_gt", value: "\(year)-01-01"))
            items.append(URLQueryItem(name: "game_date_lt", value: "\(year)-12-31"))
        }

        return items
    }
}

// MARK: - Pitcher Query

/// Query builder for Statcast pitching data from Baseball Savant.
///
/// Fetches pitch-level CSV data and aggregates it into ``StatcastPitching``
/// statistics including batted-ball-against metrics and pitch arsenal data.
///
/// ```swift
/// let stats = try await SwiftBaseball
///     .statcastPitching(playerId: 543037)
///     .season(2024)
///     .fetch()
/// ```
public struct StatcastPitcherQuery: Sendable {
    let playerId: Int
    let client: StatcastAPIClient
    private var seasonYear: Int?
    private var startDate: String?
    private var endDate: String?
    private var gameTypeFilter: String?

    init(playerId: Int, client: StatcastAPIClient) {
        self.playerId = playerId
        self.client = client
    }

    /// Filters to a specific season. Sets date range to the full calendar year.
    public func season(_ year: Int) -> StatcastPitcherQuery {
        var copy = self
        copy.seasonYear = year
        return copy
    }

    /// Filters to a specific date range in `"YYYY-MM-DD"` format.
    public func dateRange(start: String, end: String) -> StatcastPitcherQuery {
        var copy = self
        copy.startDate = start
        copy.endDate = end
        return copy
    }

    /// Filters to a specific game type (e.g. `"R"` for regular season, `"S"` for spring training).
    ///
    /// When omitted, Baseball Savant returns all game types within the date window,
    /// including spring training and exhibition games. Pass `"R"` to match the default
    /// view on the Savant website.
    public func gameType(_ type: String) -> StatcastPitcherQuery {
        var copy = self
        copy.gameTypeFilter = type
        return copy
    }

    /// Executes the query and returns aggregated Statcast pitching statistics.
    ///
    /// - Returns: Aggregated pitching profile including batted-ball-against data and pitch arsenal.
    /// - Throws: ``SwiftBaseballError`` if the request or parsing fails.
    public func fetch() async throws -> StatcastPitching {
        let items = buildQueryItems()
        let csv = try await client.fetchCSV(queryItems: items)
        var rows = CSVParser.parse(csv)
        if let gt = gameTypeFilter {
            rows = rows.filter { $0["game_type"] == gt }
        }
        return StatcastPitcherAggregator.aggregate(rows)
    }

    private func buildQueryItems() -> [URLQueryItem] {
        var items = [
            URLQueryItem(name: "all", value: "true"),
            URLQueryItem(name: "type", value: "details"),
            URLQueryItem(name: "pitchers_lookup[]", value: String(playerId)),
            URLQueryItem(name: "player_type", value: "pitcher"),
        ]

        if let start = startDate, let end = endDate {
            items.append(URLQueryItem(name: "game_date_gt", value: start))
            items.append(URLQueryItem(name: "game_date_lt", value: end))
        } else if let year = seasonYear {
            items.append(URLQueryItem(name: "game_date_gt", value: "\(year)-01-01"))
            items.append(URLQueryItem(name: "game_date_lt", value: "\(year)-12-31"))
        }

        return items
    }
}

// MARK: - Career Split Batting Query

/// Query builder for career Statcast batting splits by opposing pitcher handedness.
///
/// Fires two concurrent Baseball Savant requests (`p_throws=L` and `p_throws=R`) with
/// no date filter, covering the full Statcast era (2015–present).
///
/// ```swift
/// let splits = try await SwiftBaseball
///     .statcastCareerSplits(playerId: 660271)
///     .fetch()
/// // splits.vsLHP.xwOBA, splits.vsRHP.pa
/// ```
public struct StatcastCareerSplitBattingQuery: Sendable {
    let playerId: Int
    let client: StatcastAPIClient

    init(playerId: Int, client: StatcastAPIClient) {
        self.playerId = playerId
        self.client = client
    }

    /// Executes the query and returns career Statcast splits vs LHP and RHP.
    ///
    /// Two HTTP requests are fired concurrently — one for `p_throws=L` and one for
    /// `p_throws=R`. No date range is applied; the result covers the entire Statcast era.
    ///
    /// - Returns: ``StatcastCareerSplits`` with vsLHP and vsRHP ``CareerSplitStats``.
    /// - Throws: ``SwiftBaseballError`` if either request or CSV parse fails.
    public func fetch() async throws -> StatcastCareerSplits {
        async let lCSV = client.fetchCSV(queryItems: buildQueryItems(pThrows: "L"))
        async let rCSV = client.fetchCSV(queryItems: buildQueryItems(pThrows: "R"))
        let (lText, rText) = try await (lCSV, rCSV)
        let lSplit = StatcastCareerSplitAggregator.aggregate(CSVParser.parse(lText))
        let rSplit = StatcastCareerSplitAggregator.aggregate(CSVParser.parse(rText))
        return StatcastCareerSplits(vsLHP: lSplit, vsRHP: rSplit)
    }

    private func buildQueryItems(pThrows: String) -> [URLQueryItem] {
        // No game_date_gt / game_date_lt — career = all Statcast era data.
        [
            URLQueryItem(name: "batters_lookup[]", value: String(playerId)),
            URLQueryItem(name: "all", value: "true"),
            URLQueryItem(name: "type", value: "details"),
            URLQueryItem(name: "player_type", value: "batter"),
            URLQueryItem(name: "p_throws", value: pThrows),
        ]
    }
}

// MARK: - Batch Batting Query

/// Query builder for Statcast batted ball data for multiple batters in a single request.
///
/// Sends player IDs in batches using `batters_lookup[]` query parameters.
/// All batches are dispatched concurrently via a task group; the ``StatcastAPIClient``
/// rate limiter (capped at 4) prevents overloading Baseball Savant.
///
/// ```swift
/// let stats = try await SwiftBaseball
///     .statcastBatchBatting(playerIds: [660271, 592450, 665742])
///     .season(2024)
///     .fetch()
/// // stats[660271]?.gbPercent
/// ```
public struct StatcastBatchBattingQuery: Sendable {
    let playerIds: [Int]
    let client: StatcastAPIClient
    private var seasonYear: Int?
    private var startDate: String?
    private var endDate: String?
    private var gameTypeFilter: String?
    private var _batchSize: Int

    /// Default number of player IDs per HTTP request.
    ///
    /// Set to 8 so that a typical roster chunk stays well under the Savant 25 000-row
    /// response cap (≈ 2 700 rows/player × 8 = ≈ 21 600 rows).
    public static let defaultBatchSize = 8

    init(playerIds: [Int], client: StatcastAPIClient, batchSize: Int = defaultBatchSize) {
        self.playerIds = playerIds
        self.client = client
        self._batchSize = batchSize
    }

    /// Filters to a specific season. Sets date range to the full calendar year.
    public func season(_ year: Int) -> StatcastBatchBattingQuery {
        var copy = self
        copy.seasonYear = year
        return copy
    }

    /// Filters to a custom date range in `"YYYY-MM-DD"` format.
    public func dateRange(start: String, end: String) -> StatcastBatchBattingQuery {
        var copy = self
        copy.startDate = start
        copy.endDate = end
        return copy
    }

    /// Overrides the number of player IDs sent per HTTP request (default: ``defaultBatchSize``).
    public func batchSize(_ size: Int) -> StatcastBatchBattingQuery {
        var copy = self
        copy._batchSize = size
        return copy
    }

    /// Filters to a specific game type (e.g. `"R"` for regular season, `"S"` for spring training).
    ///
    /// When omitted, Baseball Savant returns all game types within the date window,
    /// including spring training and exhibition games. Pass `"R"` to match the default
    /// view on the Savant website.
    public func gameType(_ type: String) -> StatcastBatchBattingQuery {
        var copy = self
        copy.gameTypeFilter = type
        return copy
    }

    /// Executes the batch query and returns aggregated stats keyed by MLB player ID.
    ///
    /// All chunks are dispatched concurrently; the ``StatcastAPIClient`` rate limiter
    /// (capped at 4 simultaneous requests) prevents overloading Baseball Savant.
    /// Players with no batted ball events in the date window are omitted from the result.
    /// Results may arrive in any order; the returned dictionary is keyed by player ID.
    ///
    /// - Returns: Dictionary of player ID → ``StatcastBatting``.
    /// - Throws: ``SwiftBaseballError`` if any HTTP request fails.
    public func fetch() async throws -> [Int: StatcastBatting] {
        guard !playerIds.isEmpty else { return [:] }
        let chunks = playerIds.chunked(into: _batchSize)
        let gtFilter = gameTypeFilter
        return try await withThrowingTaskGroup(of: [Int: StatcastBatting].self) { group in
            for chunk in chunks {
                group.addTask {
                    let csv = try await self.client.fetchCSV(queryItems: self.buildQueryItems(for: chunk))
                    var rows = CSVParser.parse(csv)
                    if let gt = gtFilter {
                        rows = rows.filter { $0["game_type"] == gt }
                    }
                    let byPlayer = Dictionary(grouping: rows) { $0["batter"].flatMap(Int.init) ?? -1 }
                    var partial: [Int: StatcastBatting] = [:]
                    for (id, playerRows) in byPlayer where id != -1 {
                        partial[id] = StatcastAggregator.aggregate(playerRows)
                    }
                    return partial
                }
            }
            var results: [Int: StatcastBatting] = [:]
            for try await partial in group {
                results.merge(partial) { _, new in new }
            }
            return results
        }
    }

    private func buildQueryItems(for ids: [Int]) -> [URLQueryItem] {
        var items: [URLQueryItem] = ids.map { URLQueryItem(name: "batters_lookup[]", value: String($0)) }
        items += [
            URLQueryItem(name: "all", value: "true"),
            URLQueryItem(name: "type", value: "details"),
            URLQueryItem(name: "player_type", value: "batter"),
        ]
        if let start = startDate, let end = endDate {
            items.append(URLQueryItem(name: "game_date_gt", value: start))
            items.append(URLQueryItem(name: "game_date_lt", value: end))
        } else if let year = seasonYear {
            items.append(URLQueryItem(name: "game_date_gt", value: "\(year)-01-01"))
            items.append(URLQueryItem(name: "game_date_lt", value: "\(year)-12-31"))
        }
        return items
    }
}

// MARK: - Batch Pitching Query

/// Query builder for Statcast pitching data for multiple pitchers in a single request.
///
/// Sends player IDs in batches using `pitchers_lookup[]` query parameters.
/// All batches are dispatched concurrently via a task group; the ``StatcastAPIClient``
/// rate limiter (capped at 4) prevents overloading Baseball Savant.
///
/// ```swift
/// let stats = try await SwiftBaseball
///     .statcastBatchPitching(playerIds: [808967, 687717, 641154])
///     .season(2024)
///     .fetch()
/// // stats[808967]?.whiffRate
/// ```
public struct StatcastBatchPitchingQuery: Sendable {
    let playerIds: [Int]
    let client: StatcastAPIClient
    private var seasonYear: Int?
    private var startDate: String?
    private var endDate: String?
    private var gameTypeFilter: String?
    private var _batchSize: Int

    /// Default number of player IDs per HTTP request.
    ///
    /// Set to 8 to keep batch responses under the Savant 25 000-row cap.
    public static let defaultBatchSize = 8

    init(playerIds: [Int], client: StatcastAPIClient, batchSize: Int = defaultBatchSize) {
        self.playerIds = playerIds
        self.client = client
        self._batchSize = batchSize
    }

    /// Filters to a specific season. Sets date range to the full calendar year.
    public func season(_ year: Int) -> StatcastBatchPitchingQuery {
        var copy = self
        copy.seasonYear = year
        return copy
    }

    /// Filters to a custom date range in `"YYYY-MM-DD"` format.
    public func dateRange(start: String, end: String) -> StatcastBatchPitchingQuery {
        var copy = self
        copy.startDate = start
        copy.endDate = end
        return copy
    }

    /// Overrides the number of player IDs sent per HTTP request (default: ``defaultBatchSize``).
    public func batchSize(_ size: Int) -> StatcastBatchPitchingQuery {
        var copy = self
        copy._batchSize = size
        return copy
    }

    /// Filters to a specific game type (e.g. `"R"` for regular season, `"S"` for spring training).
    ///
    /// When omitted, Baseball Savant returns all game types within the date window,
    /// including spring training and exhibition games. Pass `"R"` to match the default
    /// view on the Savant website.
    public func gameType(_ type: String) -> StatcastBatchPitchingQuery {
        var copy = self
        copy.gameTypeFilter = type
        return copy
    }

    /// Executes the batch query and returns aggregated stats keyed by MLB player ID.
    ///
    /// All chunks are dispatched concurrently; the ``StatcastAPIClient`` rate limiter
    /// (capped at 4 simultaneous requests) prevents overloading Baseball Savant.
    /// Pitchers with no pitch data in the date window are omitted from the result.
    /// Results may arrive in any order; the returned dictionary is keyed by player ID.
    ///
    /// - Returns: Dictionary of player ID → ``StatcastPitching``.
    /// - Throws: ``SwiftBaseballError`` if any HTTP request fails.
    public func fetch() async throws -> [Int: StatcastPitching] {
        guard !playerIds.isEmpty else { return [:] }
        let chunks = playerIds.chunked(into: _batchSize)
        let gtFilter = gameTypeFilter
        return try await withThrowingTaskGroup(of: [Int: StatcastPitching].self) { group in
            for chunk in chunks {
                group.addTask {
                    let csv = try await self.client.fetchCSV(queryItems: self.buildQueryItems(for: chunk))
                    var rows = CSVParser.parse(csv)
                    if let gt = gtFilter {
                        rows = rows.filter { $0["game_type"] == gt }
                    }
                    let byPlayer = Dictionary(grouping: rows) { $0["pitcher"].flatMap(Int.init) ?? -1 }
                    var partial: [Int: StatcastPitching] = [:]
                    for (id, playerRows) in byPlayer where id != -1 {
                        partial[id] = StatcastPitcherAggregator.aggregate(playerRows)
                    }
                    return partial
                }
            }
            var results: [Int: StatcastPitching] = [:]
            for try await partial in group {
                results.merge(partial) { _, new in new }
            }
            return results
        }
    }

    private func buildQueryItems(for ids: [Int]) -> [URLQueryItem] {
        var items: [URLQueryItem] = ids.map { URLQueryItem(name: "pitchers_lookup[]", value: String($0)) }
        items += [
            URLQueryItem(name: "all", value: "true"),
            URLQueryItem(name: "type", value: "details"),
            URLQueryItem(name: "player_type", value: "pitcher"),
        ]
        if let start = startDate, let end = endDate {
            items.append(URLQueryItem(name: "game_date_gt", value: start))
            items.append(URLQueryItem(name: "game_date_lt", value: end))
        } else if let year = seasonYear {
            items.append(URLQueryItem(name: "game_date_gt", value: "\(year)-01-01"))
            items.append(URLQueryItem(name: "game_date_lt", value: "\(year)-12-31"))
        }
        return items
    }
}

// MARK: - Batch Career Split Batting Query

/// Query builder for career Statcast batting splits for multiple batters in batched requests.
///
/// Sends player IDs in batches using `batters_lookup[]` query parameters. For each batch,
/// two concurrent requests are fired — one for `p_throws=L` and one for `p_throws=R`.
/// No date filter is applied; results cover the full Statcast era (2015–present).
///
/// The default batch size is 4 (half of ``StatcastBatchBattingQuery/defaultBatchSize``)
/// because career rows are approximately 3× larger than single-season rows, keeping
/// each response well under the Savant 25,000-row cap.
///
/// ```swift
/// let splits = try await SwiftBaseball
///     .statcastBatchCareerSplits([660271, 592450, 665742])
///     .fetch()
/// // splits[660271]?.vsLHP.xwOBA
/// ```
public struct StatcastBatchCareerSplitBattingQuery: Sendable {
    let playerIds: [Int]
    let client: StatcastAPIClient
    private var _batchSize: Int

    /// Default number of player IDs per HTTP request pair (L + R).
    ///
    /// Set to 4 because career rows are ~3× larger than single-season rows.
    /// A batch of 4 players × ~8,000 career rows/player = ~32,000 rows total,
    /// split across two requests (L and R), keeping each under the 25,000-row cap.
    public static let defaultBatchSize = 4

    init(playerIds: [Int], client: StatcastAPIClient, batchSize: Int = defaultBatchSize) {
        self.playerIds = playerIds
        self.client = client
        self._batchSize = batchSize
    }

    /// Overrides the number of player IDs sent per HTTP request pair (default: ``defaultBatchSize``).
    public func batchSize(_ size: Int) -> StatcastBatchCareerSplitBattingQuery {
        var copy = self
        copy._batchSize = size
        return copy
    }

    /// Executes the batch query and returns career splits keyed by MLB player ID.
    ///
    /// All chunks are dispatched concurrently; within each chunk, the `p_throws=L`
    /// and `p_throws=R` requests are also concurrent. The ``StatcastAPIClient`` rate
    /// limiter (capped at 4) prevents overloading Baseball Savant.
    ///
    /// - Returns: Dictionary of player ID → ``StatcastCareerSplits``.
    /// - Throws: ``SwiftBaseballError`` if any HTTP request fails.
    public func fetch() async throws -> [Int: StatcastCareerSplits] {
        guard !playerIds.isEmpty else { return [:] }
        let chunks = playerIds.chunked(into: _batchSize)
        return try await withThrowingTaskGroup(of: [Int: StatcastCareerSplits].self) { group in
            for chunk in chunks {
                group.addTask {
                    async let lCSV = self.client.fetchCSV(
                        queryItems: self.buildQueryItems(for: chunk, pThrows: "L"))
                    async let rCSV = self.client.fetchCSV(
                        queryItems: self.buildQueryItems(for: chunk, pThrows: "R"))
                    let (lText, rText) = try await (lCSV, rCSV)
                    let lByPlayer = Dictionary(grouping: CSVParser.parse(lText)) {
                        $0["batter"].flatMap(Int.init) ?? -1
                    }
                    let rByPlayer = Dictionary(grouping: CSVParser.parse(rText)) {
                        $0["batter"].flatMap(Int.init) ?? -1
                    }
                    var partial: [Int: StatcastCareerSplits] = [:]
                    let allIds = Set(lByPlayer.keys).union(rByPlayer.keys).subtracting([-1])
                    for id in allIds {
                        partial[id] = StatcastCareerSplits(
                            vsLHP: StatcastCareerSplitAggregator.aggregate(lByPlayer[id] ?? []),
                            vsRHP: StatcastCareerSplitAggregator.aggregate(rByPlayer[id] ?? [])
                        )
                    }
                    return partial
                }
            }
            var results: [Int: StatcastCareerSplits] = [:]
            for try await partial in group {
                results.merge(partial) { _, new in new }
            }
            return results
        }
    }

    private func buildQueryItems(for ids: [Int], pThrows: String) -> [URLQueryItem] {
        var items: [URLQueryItem] = ids.map { URLQueryItem(name: "batters_lookup[]", value: String($0)) }
        items += [
            URLQueryItem(name: "all", value: "true"),
            URLQueryItem(name: "type", value: "details"),
            URLQueryItem(name: "player_type", value: "batter"),
            URLQueryItem(name: "p_throws", value: pThrows),
        ]
        // No date range — career = all Statcast era data.
        return items
    }
}

// MARK: - Array helper

private extension Array {
    /// Splits the array into sequential chunks of at most `size` elements.
    func chunked(into size: Int) -> [[Element]] {
        guard size > 0 else { return [] }
        return stride(from: 0, to: count, by: size).map {
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}

// MARK: - Batting Aggregator

/// Aggregates pitch-level Statcast rows into ``StatcastBatting``.
enum StatcastAggregator {

    /// wOBA linear weight assigned to a walk.
    private static let walkWOBA: Double = 0.690
    /// wOBA linear weight assigned to a hit-by-pitch.
    private static let hbpWOBA: Double = 0.720

    /// PA-terminating `events` values that record exactly one out.
    private static let singleOutEvents: Set<String> = [
        "field_out", "force_out", "sac_fly", "sac_bunt",
        "fielder_choice_out", "catcher_interf",
    ]

    /// PA-terminating `events` values that record two outs.
    private static let doublePlayEvents: Set<String> = [
        "double_play", "grounded_into_double_play",
        "sac_fly_double_play", "sac_bunt_double_play", "strikeout_double_play",
    ]

    /// Counts PA-outcome events (K, BB, HBP, outs) from the `events` CSV field.
    ///
    /// The `events` field is non-empty only on the final pitch of a plate appearance.
    /// Shared by ``StatcastAggregator`` (batters) and ``StatcastPitcherAggregator`` (pitchers).
    static func countPAEvents(
        _ rows: [[String: String]]
    ) -> (k: Int, bb: Int, hbp: Int, outs: Int) {
        var k = 0, bb = 0, hbp = 0, outs = 0
        for row in rows {
            guard let ev = row["events"], !ev.isEmpty else { continue }
            switch ev {
            case "strikeout":
                k += 1; outs += 1
            case "strikeout_double_play":
                k += 1; outs += 2
            case "walk":
                bb += 1
            case "hit_by_pitch":
                hbp += 1
            case "triple_play":
                outs += 3
            default:
                if doublePlayEvents.contains(ev) {
                    outs += 2
                } else if singleOutEvents.contains(ev) {
                    outs += 1
                }
            }
        }
        return (k, bb, hbp, outs)
    }

    static func aggregate(_ rows: [[String: String]]) -> StatcastBatting {
        // Filter to rows with a batted ball type (in-play events only).
        let battedBalls = rows.filter { $0["bb_type"] != nil }

        let total = battedBalls.count
        let groundBalls = battedBalls.filter { $0["bb_type"] == "ground_ball" }.count
        let flyBalls = battedBalls.filter { $0["bb_type"] == "fly_ball" }.count
        let lineDrives = battedBalls.filter { $0["bb_type"] == "line_drive" }.count
        let popups = battedBalls.filter { $0["bb_type"] == "popup" }.count

        let gbPct = total > 0 ? Double(groundBalls) / Double(total) : nil
        let fbPct = total > 0 ? Double(flyBalls) / Double(total) : nil
        let ldPct = total > 0 ? Double(lineDrives) / Double(total) : nil
        let popupPct = total > 0 ? Double(popups) / Double(total) : nil

        // Exit velocity
        let exitVelos = battedBalls.compactMap { $0["launch_speed"].flatMap(Double.init) }
        let avgEV = exitVelos.isEmpty ? nil : exitVelos.reduce(0, +) / Double(exitVelos.count)
        let maxEV = exitVelos.max()

        // Launch angle
        let launchAngles = battedBalls.compactMap { $0["launch_angle"].flatMap(Double.init) }
        let avgLA = launchAngles.isEmpty ? nil : launchAngles.reduce(0, +) / Double(launchAngles.count)

        // Barrel: exit velo >= 98 mph AND launch angle 26–30° (with a wider range at higher velos).
        // Simplified MLB definition: EV >= 98 AND 26 <= LA <= 50 AND LA >= (50 - EV - 48) * 1.2.
        // Using the simpler threshold: barrel if EV >= 98 and LA in [26, 30] at minimum,
        // expanding by 2° per mph over 98, up to LA 50.
        let barrels = battedBalls.filter { row in
            guard let ev = row["launch_speed"].flatMap(Double.init),
                  let la = row["launch_angle"].flatMap(Double.init),
                  ev >= 98.0 else { return false }
            let minAngle = 26.0 - (ev - 98.0) * 1.0
            let maxAngle = min(50.0, 30.0 + (ev - 98.0) * 2.0)
            return la >= max(minAngle, 8.0) && la <= maxAngle
        }.count
        let barrelRate = total > 0 ? Double(barrels) / Double(total) : nil

        // Hard hit: exit velocity >= 95 mph
        let hardHit = exitVelos.filter { $0 >= 95.0 }.count
        let hardHitRate = total > 0 ? Double(hardHit) / Double(total) : nil

        // xBA/xSLG: mean of per-BBE estimated values (matches Savant leaderboard methodology).
        let xBAs = battedBalls.compactMap { $0["estimated_ba_using_speedangle"].flatMap(Double.init) }
        let xSLGs = battedBalls.compactMap { $0["estimated_slg_using_speedangle"].flatMap(Double.init) }
        let xBA = xBAs.isEmpty ? nil : xBAs.reduce(0, +) / Double(xBAs.count)
        let xSLG = xSLGs.isEmpty ? nil : xSLGs.reduce(0, +) / Double(xSLGs.count)

        // Full-PA xwOBA: blend contact xwOBA with per-event weights for K/BB/HBP,
        // identical to the methodology used in ``StatcastPitcherAggregator``.
        let paEvents = countPAEvents(rows)
        let xwOBAContactSum = battedBalls
            .compactMap { $0["estimated_woba_using_speedangle"].flatMap(Double.init) }
            .reduce(0.0, +)
        let totalPA = total + paEvents.k + paEvents.bb + paEvents.hbp
        let xwOBA: Double? = totalPA > 0
            ? (xwOBAContactSum + walkWOBA * Double(paEvents.bb) + hbpWOBA * Double(paEvents.hbp))
              / Double(totalPA)
            : nil

        return StatcastBatting(
            battedBallEvents: total,
            groundBalls: groundBalls,
            flyBalls: flyBalls,
            lineDrives: lineDrives,
            popups: popups,
            gbPercent: gbPct,
            fbPercent: fbPct,
            ldPercent: ldPct,
            popupPercent: popupPct,
            avgExitVelocity: avgEV,
            maxExitVelocity: maxEV,
            avgLaunchAngle: avgLA,
            barrelRate: barrelRate,
            hardHitRate: hardHitRate,
            xBA: xBA,
            xSLG: xSLG,
            xwOBA: xwOBA,
            strikeouts: paEvents.k,
            walks: paEvents.bb,
            hitByPitches: paEvents.hbp,
            plateAppearances: totalPA
        )
    }

    /// Computes barrel/hard-hit/expected stats from batted ball rows.
    ///
    /// Shared by both ``StatcastAggregator`` and ``StatcastPitcherAggregator``.
    static func battedBallMetrics(
        from battedBalls: [[String: String]]
    ) -> (
        groundBalls: Int, flyBalls: Int, lineDrives: Int, popups: Int,
        gbPct: Double?, fbPct: Double?, ldPct: Double?, popupPct: Double?,
        avgEV: Double?, maxEV: Double?, avgLA: Double?,
        barrelRate: Double?, hardHitRate: Double?,
        xBA: Double?, xSLG: Double?, xwOBA: Double?
    ) {
        let total = battedBalls.count
        let gb = battedBalls.filter { $0["bb_type"] == "ground_ball" }.count
        let fb = battedBalls.filter { $0["bb_type"] == "fly_ball" }.count
        let ld = battedBalls.filter { $0["bb_type"] == "line_drive" }.count
        let pu = battedBalls.filter { $0["bb_type"] == "popup" }.count

        let gbPct = total > 0 ? Double(gb) / Double(total) : nil
        let fbPct = total > 0 ? Double(fb) / Double(total) : nil
        let ldPct = total > 0 ? Double(ld) / Double(total) : nil
        let puPct = total > 0 ? Double(pu) / Double(total) : nil

        let evs = battedBalls.compactMap { $0["launch_speed"].flatMap(Double.init) }
        let avgEV = evs.isEmpty ? nil : evs.reduce(0, +) / Double(evs.count)
        let maxEV = evs.max()

        let las = battedBalls.compactMap { $0["launch_angle"].flatMap(Double.init) }
        let avgLA = las.isEmpty ? nil : las.reduce(0, +) / Double(las.count)

        let barrels = battedBalls.filter { row in
            guard let ev = row["launch_speed"].flatMap(Double.init),
                  let la = row["launch_angle"].flatMap(Double.init),
                  ev >= 98.0 else { return false }
            let minA = 26.0 - (ev - 98.0) * 1.0
            let maxA = min(50.0, 30.0 + (ev - 98.0) * 2.0)
            return la >= max(minA, 8.0) && la <= maxA
        }.count
        let barrelRate = total > 0 ? Double(barrels) / Double(total) : nil

        let hardHit = evs.filter { $0 >= 95.0 }.count
        let hardHitRate = total > 0 ? Double(hardHit) / Double(total) : nil

        let xBAs = battedBalls.compactMap { $0["estimated_ba_using_speedangle"].flatMap(Double.init) }
        let xSLGs = battedBalls.compactMap { $0["estimated_slg_using_speedangle"].flatMap(Double.init) }
        let xwOBAs = battedBalls.compactMap { $0["estimated_woba_using_speedangle"].flatMap(Double.init) }
        let xBA = xBAs.isEmpty ? nil : xBAs.reduce(0, +) / Double(xBAs.count)
        let xSLG = xSLGs.isEmpty ? nil : xSLGs.reduce(0, +) / Double(xSLGs.count)
        let xwOBA = xwOBAs.isEmpty ? nil : xwOBAs.reduce(0, +) / Double(xwOBAs.count)

        return (gb, fb, ld, pu, gbPct, fbPct, ldPct, puPct,
                avgEV, maxEV, avgLA, barrelRate, hardHitRate, xBA, xSLG, xwOBA)
    }
}

// MARK: - Career Split Aggregator

/// Aggregates pitch-level Statcast rows into ``CareerSplitStats``.
///
/// Reuses ``StatcastAggregator/countPAEvents(_:)`` for PA outcome counting and
/// applies the same full-PA xwOBA blend (contact + walk/HBP weights) used by
/// ``StatcastAggregator/aggregate(_:)``.
enum StatcastCareerSplitAggregator {

    /// wOBA linear weight assigned to a walk.
    private static let walkWOBA: Double = 0.690
    /// wOBA linear weight assigned to a hit-by-pitch.
    private static let hbpWOBA: Double = 0.720

    /// Aggregates rows for a single pitcher-handedness split.
    ///
    /// - Parameter rows: Pitch-level rows from a Savant CSV already filtered to one `p_throws` value.
    /// - Returns: ``CareerSplitStats`` with full-PA xwOBA, total PA, and truncation flag.
    static func aggregate(_ rows: [[String: String]]) -> CareerSplitStats {
        let isTruncated = rows.count == 25_000
        if isTruncated {
            print("[SwiftBaseball] Warning: Savant returned 25,000 rows — career split data may be truncated.")
        }
        let battedBalls = rows.filter { $0["bb_type"] != nil }
        let paEvents = StatcastAggregator.countPAEvents(rows)
        let totalPA = battedBalls.count + paEvents.k + paEvents.bb + paEvents.hbp
        let contactSum = battedBalls
            .compactMap { $0["estimated_woba_using_speedangle"].flatMap(Double.init) }
            .reduce(0.0, +)
        let xwOBA: Double? = totalPA > 0
            ? (contactSum + walkWOBA * Double(paEvents.bb) + hbpWOBA * Double(paEvents.hbp))
              / Double(totalPA)
            : nil
        return CareerSplitStats(xwOBA: xwOBA, pa: totalPA, isTruncated: isTruncated)
    }
}

// MARK: - Pitcher Aggregator

/// Aggregates pitch-level Statcast rows into ``StatcastPitching``.
enum StatcastPitcherAggregator {

    /// Descriptions that count as swinging strikes (whiffs).
    private static let whiffDescriptions: Set<String> = [
        "swinging_strike", "swinging_strike_blocked", "foul_tip", "missed_bunt",
    ]

    /// Descriptions that count as swings (denominator for whiff rate).
    private static let swingDescriptions: Set<String> = [
        "swinging_strike", "swinging_strike_blocked", "foul_tip", "missed_bunt",
        "foul", "foul_bunt", "hit_into_play", "bunt_foul_tip",
    ]

    /// Descriptions that count as called strikes + whiffs (CSW numerator).
    private static let cswDescriptions: Set<String> = [
        "called_strike", "swinging_strike", "swinging_strike_blocked",
    ]

    /// Fastball pitch type codes for velocity aggregation.
    private static let fastballCodes: Set<String> = ["FF", "SI", "FC"]

    /// League-average HR-per-fly-ball rate used for xFIP.
    private static let leagueHRperFBRate: Double = 0.105

    /// FIP constant added to the FIP numerator/IP quotient.
    private static let fipConstant: Double = 3.10

    /// wOBA linear weight assigned to a walk for full-PA xwOBA blending.
    private static let walkWOBA: Double = 0.690

    /// wOBA linear weight assigned to a hit-by-pitch for full-PA xwOBA blending.
    private static let hbpWOBA: Double = 0.720

    static func aggregate(_ rows: [[String: String]]) -> StatcastPitching {
        // Batted ball against — reuse shared logic
        let battedBalls = rows.filter { $0["bb_type"] != nil }
        let bb = StatcastAggregator.battedBallMetrics(from: battedBalls)

        // Pitch arsenal
        let totalPitches = rows.count

        // Fastball velocity
        let fbVelos = rows.compactMap { row -> Double? in
            guard let code = row["pitch_type"], fastballCodes.contains(code) else { return nil }
            return row["release_speed"].flatMap(Double.init)
        }
        let avgFBV = fbVelos.isEmpty ? nil : fbVelos.reduce(0, +) / Double(fbVelos.count)
        let maxFBV = fbVelos.max()

        // Spin rate across all pitches
        let spins = rows.compactMap { $0["release_spin_rate"].flatMap(Double.init) }
        let avgSpin = spins.isEmpty ? nil : spins.reduce(0, +) / Double(spins.count)

        // Whiff rate = swinging strikes / total swings
        let swings = rows.filter { row in
            guard let desc = row["description"] else { return false }
            return swingDescriptions.contains(desc)
        }.count
        let whiffs = rows.filter { row in
            guard let desc = row["description"] else { return false }
            return whiffDescriptions.contains(desc)
        }.count
        let whiffRate = swings > 0 ? Double(whiffs) / Double(swings) : nil

        // CSW = (called strikes + whiffs) / total pitches
        let cswCount = rows.filter { row in
            guard let desc = row["description"] else { return false }
            return cswDescriptions.contains(desc)
        }.count
        let csw = totalPitches > 0 ? Double(cswCount) / Double(totalPitches) : nil

        // PA event counts (K, BB, HBP, outs) for xERA and xFIP
        let paEvents = StatcastAggregator.countPAEvents(rows)
        let ip = Double(paEvents.outs) / 3.0

        // Full-PA xwOBA: blend contact xwOBA values with per-event weights for K / BB / HBP.
        // Strikeouts contribute 0.000; walks contribute walkWOBA; HBP contributes hbpWOBA.
        let xwOBAContactSum = battedBalls
            .compactMap { $0["estimated_woba_using_speedangle"].flatMap(Double.init) }
            .reduce(0.0, +)
        let totalPA = battedBalls.count + paEvents.k + paEvents.bb + paEvents.hbp
        let fullPAxwOBA = totalPA > 0
            ? (xwOBAContactSum + walkWOBA * Double(paEvents.bb) + hbpWOBA * Double(paEvents.hbp))
              / Double(totalPA)
            : nil
        // xERA ≈ fullPAxwOBA × 13.0  (linear calibration: avg xwOBA ~0.320 → ~4.16 ERA)
        let xERA: Double? = (totalPA >= 3 && fullPAxwOBA != nil)
            ? max(0.0, fullPAxwOBA! * 13.0)
            : nil

        // xFIP = ((13 × xHR + 3 × (BB + HBP) − 2 × K) / IP) + fipConstant
        let xFIP: Double?
        if ip >= 1.0 {
            let xHR = Double(bb.flyBalls) * leagueHRperFBRate
            let numerator = 13.0 * xHR + 3.0 * Double(paEvents.bb + paEvents.hbp) - 2.0 * Double(paEvents.k)
            xFIP = numerator / ip + fipConstant
        } else {
            xFIP = nil
        }

        // Pitch mix
        var pitchGroups: [String: [Dictionary<String, String>]] = [:]
        for row in rows {
            let name = row["pitch_name"] ?? "Unknown"
            guard !name.isEmpty else { continue }
            pitchGroups[name, default: []].append(row)
        }
        let mix = pitchGroups.map { (name, pitches) -> PitchMixEntry in
            let velos = pitches.compactMap { $0["release_speed"].flatMap(Double.init) }
            let spinRates = pitches.compactMap { $0["release_spin_rate"].flatMap(Double.init) }
            let hBreaks = pitches.compactMap { $0["pfx_x"].flatMap(Double.init) }
            let vBreaks = pitches.compactMap { $0["pfx_z"].flatMap(Double.init) }

            let pitchSwings = pitches.filter { row in
                guard let desc = row["description"] else { return false }
                return swingDescriptions.contains(desc)
            }.count
            let pitchWhiffs = pitches.filter { row in
                guard let desc = row["description"] else { return false }
                return whiffDescriptions.contains(desc)
            }.count
            let pitchCSWCount = pitches.filter { row in
                guard let desc = row["description"] else { return false }
                return cswDescriptions.contains(desc)
            }.count
            let pitchCSW: Double? = pitches.isEmpty ? nil : Double(pitchCSWCount) / Double(pitches.count)
            let pitchXwOBAValues = pitches.compactMap { row -> Double? in
                guard row["bb_type"] != nil else { return nil }
                return row["estimated_woba_using_speedangle"].flatMap(Double.init)
            }
            let pitchXwOBA: Double? = pitchXwOBAValues.isEmpty
                ? nil
                : pitchXwOBAValues.reduce(0, +) / Double(pitchXwOBAValues.count)

            return PitchMixEntry(
                name: name,
                count: pitches.count,
                percentage: totalPitches > 0 ? Double(pitches.count) / Double(totalPitches) : 0,
                avgVelocity: velos.isEmpty ? nil : velos.reduce(0, +) / Double(velos.count),
                avgSpinRate: spinRates.isEmpty ? nil : spinRates.reduce(0, +) / Double(spinRates.count),
                avgHorizontalBreak: hBreaks.isEmpty ? nil : hBreaks.reduce(0, +) / Double(hBreaks.count),
                avgInducedVerticalBreak: vBreaks.isEmpty ? nil : vBreaks.reduce(0, +) / Double(vBreaks.count),
                whiffRate: pitchSwings > 0 ? Double(pitchWhiffs) / Double(pitchSwings) : nil,
                csw: pitchCSW,
                xwOBA: pitchXwOBA
            )
        }.sorted { $0.count > $1.count }

        return StatcastPitching(
            battedBallEvents: battedBalls.count,
            groundBalls: bb.groundBalls,
            flyBalls: bb.flyBalls,
            lineDrives: bb.lineDrives,
            popups: bb.popups,
            gbPercent: bb.gbPct,
            fbPercent: bb.fbPct,
            ldPercent: bb.ldPct,
            popupPercent: bb.popupPct,
            avgExitVelocity: bb.avgEV,
            maxExitVelocity: bb.maxEV,
            avgLaunchAngle: bb.avgLA,
            barrelRate: bb.barrelRate,
            hardHitRate: bb.hardHitRate,
            xBA: bb.xBA,
            xSLG: bb.xSLG,
            xwOBA: bb.xwOBA,
            strikeouts: paEvents.k,
            walks: paEvents.bb,
            hitByPitch: paEvents.hbp,
            inningsPitched: ip,
            xERA: xERA,
            xFIP: xFIP,
            totalPitches: totalPitches,
            avgFastballVelo: avgFBV,
            maxFastballVelo: maxFBV,
            avgSpinRate: avgSpin,
            whiffRate: whiffRate,
            csw: csw,
            pitchMix: mix
        )
    }
}
