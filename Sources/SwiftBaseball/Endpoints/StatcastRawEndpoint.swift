import Foundation

// MARK: - Date chunking helper

enum StatcastDateChunker {
    /// Default chunk size used to keep date-range raw queries comfortably below the
    /// 25 000-row Savant CSV cap. League-wide pitch volume averages roughly
    /// 2 000–2 500 pitches per day, so a 7-day window stays in the 14k–17k range.
    static let defaultChunkDays = 7

    private static let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    /// Splits an inclusive `[start, end]` date range (in `"YYYY-MM-DD"` form) into
    /// chunks of at most `chunkDays` days. The final chunk's `end` matches the
    /// caller-supplied `end` exactly. Returns the original range as a single chunk
    /// if either date can't be parsed.
    static func chunks(start: String, end: String, chunkDays: Int = defaultChunkDays) -> [(start: String, end: String)] {
        guard
            chunkDays > 0,
            let startDate = formatter.date(from: start),
            let endDate = formatter.date(from: end),
            startDate <= endDate
        else {
            return [(start, end)]
        }

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current

        var chunks: [(String, String)] = []
        var cursor = startDate
        while cursor <= endDate {
            let proposedEnd = calendar.date(byAdding: .day, value: chunkDays - 1, to: cursor) ?? endDate
            let chunkEnd = min(proposedEnd, endDate)
            chunks.append((formatter.string(from: cursor), formatter.string(from: chunkEnd)))
            guard let next = calendar.date(byAdding: .day, value: 1, to: chunkEnd) else { break }
            cursor = next
        }
        return chunks
    }
}

// MARK: - Raw date-range query

/// Query builder for raw Baseball Savant pitch-level data across a date range.
///
/// Returns one ``StatcastPitch`` per pitch, with no aggregation. Internally splits
/// the requested date range into 7-day chunks, fires the requests concurrently, and
/// concatenates the results — keeping each individual response under the Savant
/// 25 000-row cap.
///
/// ```swift
/// let pitches = try await SwiftBaseball
///     .statcastRaw(start: "2024-05-21", end: "2024-05-21")
///     .fetch()
/// ```
public struct StatcastRawQuery: Sendable {
    let client: StatcastAPIClient
    let start: String
    let end: String
    private var gameTypeFilter: String?
    private var _chunkDays: Int = StatcastDateChunker.defaultChunkDays

    init(client: StatcastAPIClient, start: String, end: String) {
        self.client = client
        self.start = start
        self.end = end
    }

    /// Filters to a specific game type (e.g. `"R"` regular season). Applied
    /// client-side after CSV parse — Savant ignores the parameter server-side.
    public func gameType(_ type: String) -> StatcastRawQuery {
        var copy = self
        copy.gameTypeFilter = type
        return copy
    }

    /// Overrides the date-range chunk size. Default is 7 days.
    public func chunkDays(_ days: Int) -> StatcastRawQuery {
        var copy = self
        copy._chunkDays = days
        return copy
    }

    /// Executes the query and returns all pitches in the date range.
    public func fetch() async throws -> [StatcastPitch] {
        let chunks = StatcastDateChunker.chunks(start: start, end: end, chunkDays: _chunkDays)
        let gtFilter = gameTypeFilter
        return try await withThrowingTaskGroup(of: [StatcastPitch].self) { group in
            for chunk in chunks {
                group.addTask {
                    let csv = try await client.fetchCSV(queryItems: [
                        URLQueryItem(name: "all", value: "true"),
                        URLQueryItem(name: "type", value: "details"),
                        URLQueryItem(name: "game_date_gt", value: chunk.start),
                        URLQueryItem(name: "game_date_lt", value: chunk.end)
                    ])
                    var rows = CSVParser.parse(csv, preserveEmpty: true)
                    if let gt = gtFilter {
                        rows = rows.filter { $0["game_type"] == gt }
                    }
                    return StatcastPitchParser.parse(rows: rows)
                }
            }
            var all: [StatcastPitch] = []
            for try await partial in group {
                all.append(contentsOf: partial)
            }
            return all
        }
    }
}

// MARK: - Raw batter query

/// Query builder for raw Baseball Savant pitch-level data filtered to a single batter.
///
/// Returns one ``StatcastPitch`` per pitch the batter saw in the requested window.
public struct StatcastBatterRawQuery: Sendable {
    let client: StatcastAPIClient
    let playerId: Int
    private var seasonYear: Int?
    private var startDate: String?
    private var endDate: String?
    private var gameTypeFilter: String?

    init(client: StatcastAPIClient, playerId: Int) {
        self.client = client
        self.playerId = playerId
    }

    /// Filters to a full calendar year.
    public func season(_ year: Int) -> StatcastBatterRawQuery {
        var copy = self
        copy.seasonYear = year
        return copy
    }

    /// Filters to a date range in `"YYYY-MM-DD"` form.
    public func dateRange(start: String, end: String) -> StatcastBatterRawQuery {
        var copy = self
        copy.startDate = start
        copy.endDate = end
        return copy
    }

    /// Filters to a specific game type code (e.g. `"R"`).
    public func gameType(_ type: String) -> StatcastBatterRawQuery {
        var copy = self
        copy.gameTypeFilter = type
        return copy
    }

    /// Executes the query and returns the batter's pitch-level rows.
    public func fetch() async throws -> [StatcastPitch] {
        let csv = try await client.fetchCSV(queryItems: buildQueryItems())
        var rows = CSVParser.parse(csv, preserveEmpty: true)
        if let gt = gameTypeFilter {
            rows = rows.filter { $0["game_type"] == gt }
        }
        return StatcastPitchParser.parse(rows: rows)
    }

    private func buildQueryItems() -> [URLQueryItem] {
        var items = [
            URLQueryItem(name: "all", value: "true"),
            URLQueryItem(name: "type", value: "details"),
            URLQueryItem(name: "batters_lookup[]", value: String(playerId)),
            URLQueryItem(name: "player_type", value: "batter")
        ]
        appendDateRange(to: &items, startDate: startDate, endDate: endDate, season: seasonYear)
        return items
    }
}

// MARK: - Raw pitcher query

/// Query builder for raw Baseball Savant pitch-level data filtered to a single pitcher.
///
/// Returns one ``StatcastPitch`` per pitch the pitcher threw in the requested window.
public struct StatcastPitcherRawQuery: Sendable {
    let client: StatcastAPIClient
    let playerId: Int
    private var seasonYear: Int?
    private var startDate: String?
    private var endDate: String?
    private var gameTypeFilter: String?

    init(client: StatcastAPIClient, playerId: Int) {
        self.client = client
        self.playerId = playerId
    }

    /// Filters to a full calendar year.
    public func season(_ year: Int) -> StatcastPitcherRawQuery {
        var copy = self
        copy.seasonYear = year
        return copy
    }

    /// Filters to a date range in `"YYYY-MM-DD"` form.
    public func dateRange(start: String, end: String) -> StatcastPitcherRawQuery {
        var copy = self
        copy.startDate = start
        copy.endDate = end
        return copy
    }

    /// Filters to a specific game type code (e.g. `"R"`).
    public func gameType(_ type: String) -> StatcastPitcherRawQuery {
        var copy = self
        copy.gameTypeFilter = type
        return copy
    }

    /// Executes the query and returns the pitcher's pitch-level rows.
    public func fetch() async throws -> [StatcastPitch] {
        let csv = try await client.fetchCSV(queryItems: buildQueryItems())
        var rows = CSVParser.parse(csv, preserveEmpty: true)
        if let gt = gameTypeFilter {
            rows = rows.filter { $0["game_type"] == gt }
        }
        return StatcastPitchParser.parse(rows: rows)
    }

    private func buildQueryItems() -> [URLQueryItem] {
        var items = [
            URLQueryItem(name: "all", value: "true"),
            URLQueryItem(name: "type", value: "details"),
            URLQueryItem(name: "pitchers_lookup[]", value: String(playerId)),
            URLQueryItem(name: "player_type", value: "pitcher")
        ]
        appendDateRange(to: &items, startDate: startDate, endDate: endDate, season: seasonYear)
        return items
    }
}

// MARK: - Single-game query

/// Query builder for raw Baseball Savant pitch-level data filtered to a single game.
///
/// Returns one ``StatcastPitch`` per pitch thrown in the specified `game_pk`.
public struct StatcastGameRawQuery: Sendable {
    let client: StatcastAPIClient
    let gamePk: Int

    /// Executes the query and returns every pitch from the specified game.
    public func fetch() async throws -> [StatcastPitch] {
        let csv = try await client.fetchCSV(queryItems: [
            URLQueryItem(name: "all", value: "true"),
            URLQueryItem(name: "type", value: "details"),
            URLQueryItem(name: "game_pk", value: String(gamePk))
        ])
        return StatcastPitchParser.parse(csv)
    }
}

// MARK: - Helpers

private func appendDateRange(
    to items: inout [URLQueryItem],
    startDate: String?,
    endDate: String?,
    season: Int?
) {
    if let start = startDate, let end = endDate {
        items.append(URLQueryItem(name: "game_date_gt", value: start))
        items.append(URLQueryItem(name: "game_date_lt", value: end))
    } else if let year = season {
        items.append(URLQueryItem(name: "game_date_gt", value: "\(year)-01-01"))
        items.append(URLQueryItem(name: "game_date_lt", value: "\(year)-12-31"))
    }
}
