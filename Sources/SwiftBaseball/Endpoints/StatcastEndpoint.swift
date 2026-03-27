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

    /// Executes the query and returns aggregated Statcast batting statistics.
    ///
    /// - Returns: Aggregated batted ball profile including GB%, FB%, LD%, exit velocity, and expected stats.
    /// - Throws: ``SwiftBaseballError`` if the request or parsing fails.
    public func fetch() async throws -> StatcastBatting {
        let items = buildQueryItems()
        let csv = try await client.fetchCSV(queryItems: items)
        let rows = CSVParser.parse(csv)
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

    /// Executes the query and returns aggregated Statcast pitching statistics.
    ///
    /// - Returns: Aggregated pitching profile including batted-ball-against data and pitch arsenal.
    /// - Throws: ``SwiftBaseballError`` if the request or parsing fails.
    public func fetch() async throws -> StatcastPitching {
        let items = buildQueryItems()
        let csv = try await client.fetchCSV(queryItems: items)
        let rows = CSVParser.parse(csv)
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

// MARK: - Batch Batting Query

/// Query builder for Statcast batted ball data for multiple batters in a single request.
///
/// Sends player IDs in batches using `batters_lookup[]` query parameters.
/// Each batch of up to ``defaultBatchSize`` players is fetched in one HTTP request;
/// the combined CSV is parsed and split by batter ID.
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

    /// Executes the batch query and returns aggregated stats keyed by MLB player ID.
    ///
    /// Players with no batted ball events in the date window are omitted from the result.
    /// - Returns: Dictionary of player ID → ``StatcastBatting``.
    /// - Throws: ``SwiftBaseballError`` if any HTTP request fails.
    public func fetch() async throws -> [Int: StatcastBatting] {
        guard !playerIds.isEmpty else { return [:] }
        var results: [Int: StatcastBatting] = [:]
        for chunk in playerIds.chunked(into: _batchSize) {
            let csv = try await client.fetchCSV(queryItems: buildQueryItems(for: chunk))
            let rows = CSVParser.parse(csv)
            let byPlayer = Dictionary(grouping: rows) { $0["batter"].flatMap(Int.init) ?? -1 }
            for (id, playerRows) in byPlayer where id != -1 {
                results[id] = StatcastAggregator.aggregate(playerRows)
            }
        }
        return results
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
/// Each batch of up to ``defaultBatchSize`` pitchers is fetched in one HTTP request;
/// the combined CSV is parsed and split by pitcher ID.
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

    /// Executes the batch query and returns aggregated stats keyed by MLB player ID.
    ///
    /// Pitchers with no pitch data in the date window are omitted from the result.
    /// - Returns: Dictionary of player ID → ``StatcastPitching``.
    /// - Throws: ``SwiftBaseballError`` if any HTTP request fails.
    public func fetch() async throws -> [Int: StatcastPitching] {
        guard !playerIds.isEmpty else { return [:] }
        var results: [Int: StatcastPitching] = [:]
        for chunk in playerIds.chunked(into: _batchSize) {
            let csv = try await client.fetchCSV(queryItems: buildQueryItems(for: chunk))
            let rows = CSVParser.parse(csv)
            let byPlayer = Dictionary(grouping: rows) { $0["pitcher"].flatMap(Int.init) ?? -1 }
            for (id, playerRows) in byPlayer where id != -1 {
                results[id] = StatcastPitcherAggregator.aggregate(playerRows)
            }
        }
        return results
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

        // Expected stats: average across all batted ball events
        let xBAs = battedBalls.compactMap { $0["estimated_ba_using_speedangle"].flatMap(Double.init) }
        let xSLGs = battedBalls.compactMap { $0["estimated_slg_using_speedangle"].flatMap(Double.init) }
        let xwOBAs = battedBalls.compactMap { $0["estimated_woba_using_speedangle"].flatMap(Double.init) }

        let xBA = xBAs.isEmpty ? nil : xBAs.reduce(0, +) / Double(xBAs.count)
        let xSLG = xSLGs.isEmpty ? nil : xSLGs.reduce(0, +) / Double(xSLGs.count)
        let xwOBA = xwOBAs.isEmpty ? nil : xwOBAs.reduce(0, +) / Double(xwOBAs.count)

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
            xwOBA: xwOBA
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
            return PitchMixEntry(
                name: name,
                count: pitches.count,
                percentage: totalPitches > 0 ? Double(pitches.count) / Double(totalPitches) : 0,
                avgVelocity: velos.isEmpty ? nil : velos.reduce(0, +) / Double(velos.count),
                avgSpinRate: spinRates.isEmpty ? nil : spinRates.reduce(0, +) / Double(spinRates.count)
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
