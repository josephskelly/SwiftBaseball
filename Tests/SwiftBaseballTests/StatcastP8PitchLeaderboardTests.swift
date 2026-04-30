import Foundation
@testable import SwiftBaseball
import Testing

// MARK: - Pitch Arsenal — Velocity

@Suite("Pitch Arsenal — Velocity Tests")
struct PitchArsenalVelocityTests {
    private func loadEntries() throws -> [PitchArsenalEntry] {
        let data = try Fixtures.load("pitch_arsenals_speed_2024.csv")
        let csv = try #require(String(data: data, encoding: .utf8))
        return PitchArsenalParser.parse(csv, season: 2024, metric: .velocity)
    }

    @Test("Wide CSV flattens to one entry per (pitcher × non-empty pitch type)")
    func flattens() throws {
        let entries = try loadEntries()
        // 15 pitchers × ~5 pitch types each, after empty cells filtered → > 50, < 100.
        #expect(entries.count > 50)
        #expect(entries.count < 100)
        #expect(entries.allSatisfy { $0.season == 2024 })
        #expect(entries.allSatisfy { $0.metric == .velocity })
    }

    @Test("Webb's pitch types decode with expected velocities")
    func webbArsenal() throws {
        let entries = try loadEntries()
        let webb = entries.filter { $0.pitcherId == 657_277 }
        // Webb throws FF, SI, FC, CH, ST in the fixture (5 pitch types).
        #expect(webb.count == 5)
        let types = Set(webb.map(\.pitchType))
        #expect(types == ["FF", "SI", "FC", "CH", "ST"])
        let ff = try #require(webb.first { $0.pitchType == "FF" })
        #expect(abs(ff.value - 92.6) < 0.0001)
        let st = try #require(webb.first { $0.pitchType == "ST" })
        #expect(abs(st.value - 83.8) < 0.0001)
    }

    @Test("Empty cells produce no entries for that pitch type")
    func emptyCellsSkipped() throws {
        let entries = try loadEntries()
        // Webb does NOT throw a SL, CU, FS, KN, or SV.
        let webb = entries.filter { $0.pitcherId == 657_277 }
        let webbTypes = Set(webb.map(\.pitchType))
        #expect(webbTypes.intersection(["SL", "CU", "FS", "KN", "SV"]).isEmpty)
    }

    @Test("Endpoint URL targets /leaderboard/pitch-arsenals with type=avg_speed")
    func endpointURL() throws {
        let endpoint = Endpoint(path: "leaderboard/pitch-arsenals", queryItems: [
            URLQueryItem(name: "type", value: "avg_speed"),
            URLQueryItem(name: "year", value: "2024"),
            URLQueryItem(name: "min", value: "q"),
            URLQueryItem(name: "csv", value: "true")
        ])
        let baseURL = try #require(URL(string: "https://baseballsavant.mlb.com/"))
        let built = try #require(endpoint.url(baseURL: baseURL))
        #expect(built.absoluteString.contains("type=avg_speed"))
        #expect(built.absoluteString.contains("year=2024"))
    }
}

// MARK: - Pitch Arsenal — Spin

@Suite("Pitch Arsenal — Spin Tests")
struct PitchArsenalSpinTests {
    private func loadEntries() throws -> [PitchArsenalEntry] {
        let data = try Fixtures.load("pitch_arsenals_spin_2024.csv")
        let csv = try #require(String(data: data, encoding: .utf8))
        return PitchArsenalParser.parse(csv, season: 2024, metric: .spin)
    }

    @Test("Spin metric flag and rpm value")
    func spinValues() throws {
        let entries = try loadEntries()
        #expect(entries.allSatisfy { $0.metric == .spin })
        let webbFF = try #require(entries.first { $0.pitcherId == 657_277 && $0.pitchType == "FF" })
        #expect(abs(webbFF.value - 2054) < 0.0001)
    }

    @Test("Endpoint URL targets type=avg_spin")
    func endpointURL() throws {
        let endpoint = Endpoint(path: "leaderboard/pitch-arsenals", queryItems: [
            URLQueryItem(name: "type", value: "avg_spin"),
            URLQueryItem(name: "year", value: "2024"),
            URLQueryItem(name: "min", value: "q"),
            URLQueryItem(name: "csv", value: "true")
        ])
        let baseURL = try #require(URL(string: "https://baseballsavant.mlb.com/"))
        let built = try #require(endpoint.url(baseURL: baseURL))
        #expect(built.absoluteString.contains("type=avg_spin"))
    }
}

// MARK: - Pitch Arsenal Stats

@Suite("Pitch Arsenal Stats Tests")
struct PitchArsenalStatsTests {
    private func loadEntries() throws -> [PitchArsenalStatsEntry] {
        let data = try Fixtures.load("pitch_arsenal_stats_2024.csv")
        let csv = try #require(String(data: data, encoding: .utf8))
        return PitchArsenalStatsParser.parse(csv, season: 2024)
    }

    @Test("Decodes 25 long-format rows from fixture")
    func decodesAllRows() throws {
        let entries = try loadEntries()
        #expect(entries.count == 25)
        #expect(entries.allSatisfy { $0.season == 2024 })
    }

    @Test("Top entry — Peralta FF — parses run value, usage, slash line")
    func topEntry() throws {
        let entries = try loadEntries()
        let top = try #require(entries.first)
        #expect(top.playerId == 642_547)
        #expect(top.playerName == "Peralta, Freddy")
        #expect(top.team == "MIL")
        #expect(top.pitchType == "FF")
        #expect(top.pitchName == "4-Seam Fastball")
        #expect(top.runValuePer100 == 0)
        #expect(top.runValue == 1)
        #expect(top.pitches == 1650)
        #expect(abs(top.pitchUsage - 53.8) < 0.0001)
        #expect(top.plateAppearances == 405)
        #expect(abs(top.battingAverage - 0.239) < 0.0001)
        #expect(abs(top.slugging - 0.424) < 0.0001)
        #expect(abs(top.wOBA - 0.338) < 0.0001)
        #expect(abs(top.whiffRate - 25.2) < 0.0001)
        #expect(abs(top.strikeoutRate - 26.9) < 0.0001)
        #expect(abs(top.hardHitRate - 44.1) < 0.0001)
    }

    @Test("Same pitcher appears once per pitch type")
    func multiplePitchTypesPerPitcher() throws {
        let entries = try loadEntries()
        let webb = entries.filter { $0.playerId == 657_277 }
        let types = Set(webb.map(\.pitchType))
        // Webb's CH and SI both clear the min-PA threshold within the trimmed fixture.
        #expect(types.contains("CH"))
        #expect(types.contains("SI"))
    }

    @Test("Negative run value reflects effective pitch")
    func negativeRunValue() throws {
        let entries = try loadEntries()
        let corbinSI = try #require(entries.first { $0.playerId == 571_578 && $0.pitchType == "SI" })
        // Corbin's sinker had -1.9 RV/100 — bad pitch from his perspective in a bad year,
        // but for a good pitcher's pitch the negative would mean "good for the pitcher".
        // The point here is just that we parse signs correctly.
        #expect(corbinSI.runValuePer100 < 0)
        #expect(corbinSI.runValue < 0)
    }

    @Test("Endpoint URL targets /leaderboard/pitch-arsenal-stats with min_pa")
    func endpointURL() throws {
        let endpoint = Endpoint(path: "leaderboard/pitch-arsenal-stats", queryItems: [
            URLQueryItem(name: "year", value: "2024"),
            URLQueryItem(name: "min_pa", value: "25"),
            URLQueryItem(name: "csv", value: "true")
        ])
        let baseURL = try #require(URL(string: "https://baseballsavant.mlb.com/"))
        let built = try #require(endpoint.url(baseURL: baseURL))
        #expect(built.absoluteString.contains("min_pa=25"))
        #expect(built.absoluteString.contains("year=2024"))
    }
}

// MARK: - Pitch Movement

@Suite("Pitch Movement Tests")
struct PitchMovementTests {
    private func loadEntries() throws -> [PitchMovementEntry] {
        let data = try Fixtures.load("pitch_movement_2024.csv")
        let csv = try #require(String(data: data, encoding: .utf8))
        return PitchMovementParser.parse(csv, season: 2024)
    }

    @Test("Decodes 25 movement rows")
    func decodesAllRows() throws {
        let entries = try loadEntries()
        #expect(entries.count == 25)
        #expect(entries.allSatisfy { $0.season == 2024 })
        #expect(entries.allSatisfy { $0.pitchType == "FF" })  // fixture trimmed to 4-seamers
    }

    @Test("Top entry — Gore — vertical/horizontal break parses with sign")
    func topEntry() throws {
        let entries = try loadEntries()
        let top = try #require(entries.first)
        #expect(top.pitcherId == 669_022)
        #expect(top.pitcherName == "Gore, MacKenzie")
        #expect(top.team == "Nationals")
        #expect(top.teamAbbreviation == "WSH")
        #expect(top.pitchHand == "L")
        #expect(top.pitchType == "FF")
        #expect(top.pitchTypeName == "4-Seam Fastball")
        #expect(abs(top.avgSpeed - 96) < 0.0001)
        #expect(top.pitchesThrown == 1658)
        #expect(top.totalPitches == 2994)
        #expect(abs(top.pitcherBreakZ - 12.1) < 0.0001)
        #expect(abs(top.leagueBreakZ - (-13.7)) < 0.0001)
        #expect(abs(top.diffZ - 1.5) < 0.0001)
        #expect(top.rise == 11)
        #expect(abs(top.pitcherBreakZInduced - 17.6) < 0.0001)
    }

    @Test("Negative tail and percent-rank parsing")
    func negativeTail() throws {
        let entries = try loadEntries()
        // Cease's FF has a negative tail (-67) and very low x-axis percentile rank.
        let cease = try #require(entries.first { $0.pitcherId == 656_302 })
        #expect(cease.tail == -67)
        #expect(cease.percentRankDiffX < 0.1)
    }

    @Test("Year column populates season when present")
    func yearFromCSV() throws {
        let data = try Fixtures.load("pitch_movement_2024.csv")
        let csv = try #require(String(data: data, encoding: .utf8))
        // Pass deliberately-wrong season; CSV's year column should win.
        let entries = PitchMovementParser.parse(csv, season: 1999)
        #expect(entries.allSatisfy { $0.season == 2024 })
    }

    @Test("Endpoint URL targets /leaderboard/pitch-movement")
    func endpointURL() throws {
        let endpoint = Endpoint(path: "leaderboard/pitch-movement", queryItems: [
            URLQueryItem(name: "year", value: "2024"),
            URLQueryItem(name: "csv", value: "true")
        ])
        let baseURL = try #require(URL(string: "https://baseballsavant.mlb.com/"))
        let built = try #require(endpoint.url(baseURL: baseURL))
        #expect(built.absoluteString.contains("pitch-movement"))
        #expect(built.absoluteString.contains("year=2024"))
    }
}
