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
            URLQueryItem(name: "player_id", value: String(playerId)),
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
}
