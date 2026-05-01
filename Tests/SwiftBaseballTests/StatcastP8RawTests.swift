import Foundation
@testable import SwiftBaseball
import Testing

// MARK: - Pitch parser

@Suite("Statcast Raw Pitch Parser Tests")
struct StatcastRawPitchParserTests {
    private func loadPitches() throws -> [StatcastPitch] {
        let data = try Fixtures.load("statcast_raw_game_746309.csv")
        let csv = try #require(String(data: data, encoding: .utf8))
        return StatcastPitchParser.parse(csv)
    }

    @Test("Decodes 15 pitches from the fixture")
    func decodesAllRows() throws {
        let pitches = try loadPitches()
        #expect(pitches.count == 15)
    }

    @Test("First pitch — Torkelson SL — typed fields parse")
    func firstPitchTypedFields() throws {
        let pitches = try loadPitches()
        let pitch = try #require(pitches.first)
        #expect(pitch.pitchType == "SL")
        #expect(pitch.pitchName == "Slider")
        #expect(pitch.playerName == "Torkelson, Spencer")
        #expect(pitch.batter == 679_529)
        #expect(pitch.pitcher == 679_525)
        #expect(pitch.events == "field_out")
        #expect(pitch.description == "hit_into_play")
        #expect(pitch.type == "X")
        #expect(pitch.bbType == "ground_ball")
        #expect(pitch.balls == 1)
        #expect(pitch.strikes == 1)
        #expect(pitch.zone == 6)
        #expect(pitch.stand == "R")
        #expect(pitch.pThrows == "R")
        #expect(pitch.homeTeam == "KC")
        #expect(pitch.awayTeam == "DET")
        #expect(pitch.gameType == "R")
        #expect(pitch.inning == 6)
        #expect(pitch.inningTopBot == "Top")
        #expect(pitch.outsWhenUp == 2)
        #expect(pitch.gamePk == 746_309)
        #expect(pitch.gameYear == 2024)
        #expect(pitch.atBatNumber == 53)
        #expect(pitch.pitchNumber == 3)
        #expect(pitch.hitLocation == 5)
    }

    @Test("Pitch physics fields decode as Doubles")
    func pitchPhysics() throws {
        let pitches = try loadPitches()
        let pitch = try #require(pitches.first)
        #expect(abs((pitch.releaseSpeed ?? 0) - 88.3) < 0.0001)
        #expect(abs((pitch.releasePosX ?? 0) - -2.04) < 0.0001)
        #expect(abs((pitch.releasePosZ ?? 0) - 5.5) < 0.0001)
        #expect(abs((pitch.effectiveSpeed ?? 0) - 87.9) < 0.0001)
        #expect(abs((pitch.releaseSpinRate ?? 0) - 2398) < 0.0001)
        #expect(pitch.spinAxis == 68)
    }

    @Test("Batted-ball + expected-stats fields decode")
    func battedBallFields() throws {
        let pitches = try loadPitches()
        let pitch = try #require(pitches.first)
        #expect(abs((pitch.launchSpeed ?? 0) - 89.6) < 0.0001)
        #expect(abs((pitch.launchAngle ?? 0) - 6) < 0.0001)
        #expect(pitch.launchSpeedAngle == 4)
        #expect(pitch.hitDistanceSc == 110)
        #expect(abs((pitch.estimatedBaUsingSpeedAngle ?? 0) - 0.455) < 0.0001)
        #expect(abs((pitch.estimatedWobaUsingSpeedAngle ?? 0) - 0.41) < 0.0001)
        #expect(abs((pitch.estimatedSlgUsingSpeedAngle ?? 0) - 0.506) < 0.0001)
    }

    @Test("Bat-tracking fields (2024+) decode")
    func batTracking() throws {
        let pitches = try loadPitches()
        let pitch = try #require(pitches.first)
        #expect(abs((pitch.batSpeed ?? 0) - 75.1) < 0.0001)
        #expect(abs((pitch.swingLength ?? 0) - 7.8) < 0.0001)
        #expect(pitch.attackAngle != nil)
        #expect(pitch.swingPathTilt != nil)
        #expect(pitch.armAngle != nil)
    }

    @Test("game_date parses as Date in UTC")
    func gameDateParses() throws {
        let pitches = try loadPitches()
        let pitch = try #require(pitches.first)
        let date = try #require(pitch.gameDate)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0) ?? .current
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        #expect(components.year == 2024)
        #expect(components.month == 5)
        #expect(components.day == 21)
    }

    @Test("Win-expectancy delta fields parse with sign")
    func winExpectancy() throws {
        let pitches = try loadPitches()
        let pitch = try #require(pitches.first)
        // Torkelson grounded out with KC up 8–3 in the 6th — small WP shift toward home.
        #expect((pitch.deltaHomeWinExp ?? 0) > 0)
        #expect((pitch.deltaRunExp ?? 0) < 0) // out → run expectancy drops for batting team
        #expect((pitch.homeWinExp ?? 0) > 0.9) // KC heavily favored
    }

    @Test("Empty optional cells stay nil; populated runner IDs decode")
    func emptyCellsAreNil() throws {
        let pitches = try loadPitches()
        let pitch = try #require(pitches.first)
        // Runners on first and second on this pitch; third is empty.
        #expect(pitch.on1B == 690_993)
        #expect(pitch.on2B == 663_837)
        #expect(pitch.on3B == nil)
        // Deprecated spin direction is empty in the fixture row.
        #expect(pitch.spinDir == nil)
        // Umpire id is also empty.
        #expect(pitch.umpire == nil)
    }

    @Test("raw escape hatch carries every CSV column")
    func rawEscapeHatch() throws {
        let pitches = try loadPitches()
        let pitch = try #require(pitches.first)
        #expect(pitch.raw["pitch_type"] == "SL")
        #expect(pitch.raw["pitch_name"] == "Slider")
        // Deprecated columns are not on the typed surface but ARE in raw.
        #expect(pitch.raw["spin_rate_deprecated"] != nil)
        #expect(pitch.raw["tfs_deprecated"] != nil)
        #expect(pitch.raw["break_angle_deprecated"] != nil)
        // Headers we DO type-decode also stay verbatim in raw.
        #expect(pitch.raw["release_speed"] == "88.3")
    }
}

// MARK: - Date chunker

@Suite("Statcast Date Chunker Tests")
struct StatcastDateChunkerTests {
    @Test("Single-day range yields one chunk")
    func singleDay() {
        let chunks = StatcastDateChunker.chunks(start: "2024-05-21", end: "2024-05-21")
        #expect(chunks.count == 1)
        #expect(chunks.first?.start == "2024-05-21")
        #expect(chunks.first?.end == "2024-05-21")
    }

    @Test("Range below chunk size yields one chunk")
    func smallRange() {
        let chunks = StatcastDateChunker.chunks(start: "2024-05-01", end: "2024-05-05")
        #expect(chunks.count == 1)
        #expect(chunks.first?.start == "2024-05-01")
        #expect(chunks.first?.end == "2024-05-05")
    }

    @Test("Exactly one chunk for a 7-day window")
    func exactWindow() {
        let chunks = StatcastDateChunker.chunks(start: "2024-05-01", end: "2024-05-07")
        #expect(chunks.count == 1)
        #expect(chunks.first?.end == "2024-05-07")
    }

    @Test("Range spanning multiple chunks splits cleanly with no gaps or overlaps")
    func multipleChunks() {
        // 21 days → exactly 3 × 7-day chunks.
        let chunks = StatcastDateChunker.chunks(start: "2024-05-01", end: "2024-05-21")
        #expect(chunks.count == 3)
        #expect(chunks[0].start == "2024-05-01")
        #expect(chunks[0].end == "2024-05-07")
        #expect(chunks[1].start == "2024-05-08")
        #expect(chunks[1].end == "2024-05-14")
        #expect(chunks[2].start == "2024-05-15")
        #expect(chunks[2].end == "2024-05-21")
    }

    @Test("Final chunk truncates to caller-supplied end")
    func partialFinalChunk() {
        // 10 days → 7 + 3.
        let chunks = StatcastDateChunker.chunks(start: "2024-05-01", end: "2024-05-10")
        #expect(chunks.count == 2)
        #expect(chunks[1].start == "2024-05-08")
        #expect(chunks[1].end == "2024-05-10")
    }

    @Test("Custom chunk size is honored")
    func customChunkSize() {
        let chunks = StatcastDateChunker.chunks(
            start: "2024-05-01",
            end: "2024-05-10",
            chunkDays: 3
        )
        #expect(chunks.count == 4) // 3+3+3+1
        #expect(chunks[3].end == "2024-05-10")
    }

    @Test("Reversed range falls back to a single chunk")
    func reversedRange() {
        let chunks = StatcastDateChunker.chunks(start: "2024-05-10", end: "2024-05-01")
        #expect(chunks.count == 1)
    }
}

// MARK: - Endpoint URL

@Suite("Statcast Raw Endpoint URL Tests")
struct StatcastRawEndpointURLTests {
    @Test("Single-game endpoint targets game_pk")
    func gameEndpoint() throws {
        let endpoint = Endpoint(path: "statcast_search/csv", queryItems: [
            URLQueryItem(name: "all", value: "true"),
            URLQueryItem(name: "type", value: "details"),
            URLQueryItem(name: "game_pk", value: "746309")
        ])
        let baseURL = try #require(URL(string: "https://baseballsavant.mlb.com/"))
        let built = try #require(endpoint.url(baseURL: baseURL))
        #expect(built.absoluteString.contains("game_pk=746309"))
        #expect(built.absoluteString.contains("type=details"))
    }

    @Test("Batter raw endpoint includes batters_lookup and player_type")
    func batterEndpoint() throws {
        let endpoint = Endpoint(path: "statcast_search/csv", queryItems: [
            URLQueryItem(name: "all", value: "true"),
            URLQueryItem(name: "type", value: "details"),
            URLQueryItem(name: "batters_lookup[]", value: "660271"),
            URLQueryItem(name: "player_type", value: "batter"),
            URLQueryItem(name: "game_date_gt", value: "2024-01-01"),
            URLQueryItem(name: "game_date_lt", value: "2024-12-31")
        ])
        let baseURL = try #require(URL(string: "https://baseballsavant.mlb.com/"))
        let built = try #require(endpoint.url(baseURL: baseURL))
        #expect(built.absoluteString.contains("player_type=batter"))
        #expect(built.absoluteString.contains("game_date_gt=2024-01-01"))
        #expect(built.absoluteString.contains("game_date_lt=2024-12-31"))
    }
}
