import Foundation
@testable import SwiftBaseball
import Testing

@Suite("Expected Stats — Batter Tests")
struct ExpectedStatsBatterTests {
    private func loadEntries() throws -> [ExpectedStatsBatterEntry] {
        let data = try Fixtures.load("expected_stats_batter_2024.csv")
        let csv = try #require(String(data: data, encoding: .utf8))
        return ExpectedStatsBatterParser.parse(csv, season: 2024)
    }

    @Test("Decodes 15 batter rows from fixture")
    func decodesAllRows() throws {
        let entries = try loadEntries()
        #expect(entries.count == 15)
        #expect(entries.allSatisfy { $0.season == 2024 })
    }

    @Test("Top entry parses player + slash line + diffs")
    func topEntryFields() throws {
        let entries = try loadEntries()
        let top = try #require(entries.first)
        #expect(top.playerId == 680_776)
        #expect(top.playerName == "Duran, Jarren")
        #expect(top.plateAppearances == 735)
        #expect(top.battedBalls == 515)
        #expect(abs(top.battingAverage - 0.285) < 0.0001)
        #expect(abs(top.expectedBattingAverage - 0.267) < 0.0001)
        #expect(top.expectedBABIPDiff > 0) // outperforming xBA
        #expect(abs(top.slugging - 0.492) < 0.0001)
        #expect(abs(top.expectedSlugging - 0.456) < 0.0001)
        #expect(abs(top.wOBA - 0.357) < 0.0001)
        #expect(abs(top.expectedWOBA - 0.340) < 0.0001)
    }

    @Test("Diff sign reflects under-performer")
    func underPerformerDiff() throws {
        let entries = try loadEntries()
        let soto = try #require(entries.first { $0.playerId == 665_742 })
        // Soto's actual wOBA (0.421) trails xwOBA (0.463) — diff negative.
        #expect(soto.expectedWOBADiff < 0)
        #expect(abs(soto.expectedWOBA - 0.463) < 0.0001)
    }

    @Test("Endpoint URL targets /leaderboard/expected_statistics with type=batter")
    func endpointURL() throws {
        let endpoint = Endpoint(path: "leaderboard/expected_statistics", queryItems: [
            URLQueryItem(name: "type", value: "batter"),
            URLQueryItem(name: "year", value: "2024"),
            URLQueryItem(name: "min", value: "q"),
            URLQueryItem(name: "csv", value: "true")
        ])
        let baseURL = try #require(URL(string: "https://baseballsavant.mlb.com/"))
        let built = try #require(endpoint.url(baseURL: baseURL))
        #expect(built.absoluteString.contains("type=batter"))
        #expect(built.absoluteString.contains("year=2024"))
        #expect(built.absoluteString.contains("min=q"))
        #expect(built.absoluteString.contains("csv=true"))
    }
}

@Suite("Expected Stats — Pitcher Tests")
struct ExpectedStatsPitcherTests {
    private func loadEntries() throws -> [ExpectedStatsPitcherEntry] {
        let data = try Fixtures.load("expected_stats_pitcher_2024.csv")
        let csv = try #require(String(data: data, encoding: .utf8))
        return ExpectedStatsPitcherParser.parse(csv, season: 2024)
    }

    @Test("Decodes 15 pitcher rows")
    func decodesAllRows() throws {
        let entries = try loadEntries()
        #expect(entries.count == 15)
        #expect(entries.allSatisfy { $0.season == 2024 })
    }

    @Test("Top entry parses ERA / xERA fields")
    func topEntryERA() throws {
        let entries = try loadEntries()
        let webb = try #require(entries.first { $0.playerId == 657_277 })
        #expect(webb.playerName == "Webb, Logan")
        #expect(webb.plateAppearances == 841)
        #expect(abs((webb.era ?? 0) - 3.47) < 0.001)
        #expect(abs((webb.expectedERA ?? 0) - 4.37) < 0.001)
        // Diff: era - xera = 3.47 - 4.37 = -0.90 (Webb is outperforming his xERA)
        #expect((webb.expectedERADiff ?? 0) < 0)
    }

    @Test("Pitcher slash-line against decodes correctly")
    func slashAgainst() throws {
        let entries = try loadEntries()
        let burnes = try #require(entries.first { $0.playerId == 669_203 })
        #expect(abs(burnes.battingAverage - 0.226) < 0.0001)
        #expect(abs(burnes.expectedBattingAverage - 0.229) < 0.0001)
        #expect(abs(burnes.slugging - 0.347) < 0.0001)
        #expect(abs(burnes.wOBA - 0.273) < 0.0001)
    }

    @Test("Missing era fields tolerate nil")
    func missingEraNil() {
        let csv = """
        "last_name, first_name","player_id","year","pa","bip","ba","est_ba","est_ba_minus_ba_diff","slg","est_slg","est_slg_minus_slg_diff","woba","est_woba","est_woba_minus_woba_diff"
        "Test, Player","999999","2024","100","60",0.250,0.260,-0.010,0.400,0.410,-0.010,0.300,0.310,-0.010
        """
        let entries = ExpectedStatsPitcherParser.parse(csv, season: 2024)
        let row = entries.first
        #expect(row?.era == nil)
        #expect(row?.expectedERA == nil)
        #expect(row?.expectedERADiff == nil)
    }
}

@Suite("Percentile Ranks — Batter Tests")
struct PercentileRanksBatterTests {
    private func loadEntries() throws -> [PercentileRanksBatterEntry] {
        let data = try Fixtures.load("percentile_ranks_batter_2024.csv")
        let csv = try #require(String(data: data, encoding: .utf8))
        return PercentileRanksBatterParser.parse(csv, season: 2024)
    }

    @Test("Decodes 15 batter rows")
    func decodesAllRows() throws {
        let entries = try loadEntries()
        #expect(entries.count == 15)
        #expect(entries.allSatisfy { $0.season == 2024 })
    }

    @Test("Witt Jr. carries elite percentile profile")
    func wittPercentiles() throws {
        let entries = try loadEntries()
        let witt = try #require(entries.first { $0.playerId == 677_951 })
        #expect(witt.playerName == "Witt Jr., Bobby")
        #expect(witt.xwOBAPercentile == 98)
        #expect(witt.xBAPercentile == 98)
        #expect(witt.xSLGPercentile == 98)
        #expect(witt.exitVelocityPercentile == 94)
        #expect(witt.sprintSpeedPercentile == 100)
        #expect(witt.oaaPercentile == 99)
        #expect(witt.batSpeedPercentile == 86)
        #expect(witt.swingLengthPercentile == 72)
    }

    @Test("Sparse row leaves stat percentiles nil while preserving filled fields")
    func sparseRowNils() throws {
        let entries = try loadEntries()
        // Kirilloff row has only max_ev + arm_strength + sprint_speed populated.
        let kirilloff = try #require(entries.first { $0.playerId == 666_135 })
        #expect(kirilloff.xwOBAPercentile == nil)
        #expect(kirilloff.xBAPercentile == nil)
        #expect(kirilloff.barrelsPercentile == nil)
        #expect(kirilloff.hardHitPercentile == nil)
        #expect(kirilloff.maxExitVelocityPercentile == 27)
        #expect(kirilloff.armStrengthPercentile == 40)
        #expect(kirilloff.sprintSpeedPercentile == 35)
        #expect(kirilloff.batSpeedPercentile == nil)
    }
}

@Suite("Percentile Ranks — Pitcher Tests")
struct PercentileRanksPitcherTests {
    private func loadEntries() throws -> [PercentileRanksPitcherEntry] {
        let data = try Fixtures.load("percentile_ranks_pitcher_2024.csv")
        let csv = try #require(String(data: data, encoding: .utf8))
        return PercentileRanksPitcherParser.parse(csv, season: 2024)
    }

    @Test("Decodes 15 pitcher rows")
    func decodesAllRows() throws {
        let entries = try loadEntries()
        #expect(entries.count == 15)
    }

    @Test("Wheeler carries elite pitcher profile")
    func wheelerPercentiles() throws {
        let entries = try loadEntries()
        let wheeler = try #require(entries.first { $0.playerId == 554_430 })
        #expect(wheeler.xwOBAPercentile == 93)
        #expect(wheeler.xBAPercentile == 93)
        #expect(wheeler.fastballVelocityPercentile == 67)
        #expect(wheeler.fastballSpinPercentile == 82)
        #expect(wheeler.curveSpinPercentile == 78)
        #expect(wheeler.strikeoutPercentile == 85)
        #expect(wheeler.xERAPercentile == 93)
    }

    @Test("Pitcher entry has no batter-only fields")
    func noBatterFields() throws {
        // The model itself drops sprint_speed / oaa / bat_speed; assert via
        // mirror that there is no `sprintSpeedPercentile` on the pitcher type.
        let mirror = Mirror(reflecting: PercentileRanksPitcherEntry(
            playerId: 0, playerName: "x", season: 2024,
            xwOBAPercentile: nil, xBAPercentile: nil, xSLGPercentile: nil,
            xISOPercentile: nil, xOBPPercentile: nil,
            barrelsPercentile: nil, barrelRatePercentile: nil,
            exitVelocityPercentile: nil, maxExitVelocityPercentile: nil,
            hardHitPercentile: nil, strikeoutPercentile: nil,
            walkPercentile: nil, whiffPercentile: nil, chasePercentile: nil,
            armStrengthPercentile: nil,
            xERAPercentile: nil,
            fastballVelocityPercentile: nil, fastballSpinPercentile: nil,
            curveSpinPercentile: nil
        ))
        let labels = mirror.children.compactMap { $0.label }
        #expect(!labels.contains("sprintSpeedPercentile"))
        #expect(!labels.contains("oaaPercentile"))
        #expect(!labels.contains("batSpeedPercentile"))
        #expect(labels.contains("fastballVelocityPercentile"))
    }
}

@Suite("Exit Velo & Barrels — Batter Tests")
struct ExitVeloBarrelsBatterTests {
    private func loadEntries() throws -> [ExitVeloBarrelsBatterEntry] {
        let data = try Fixtures.load("exit_velo_barrels_batter_2024.csv")
        let csv = try #require(String(data: data, encoding: .utf8))
        return ExitVeloBarrelsBatterParser.parse(csv, season: 2024)
    }

    @Test("Decodes 15 batter rows with season injected")
    func decodesAllRows() throws {
        let entries = try loadEntries()
        #expect(entries.count == 15)
        #expect(entries.allSatisfy { $0.season == 2024 })
    }

    @Test("Top entry parses Arraez batted-ball profile")
    func topEntryFields() throws {
        let entries = try loadEntries()
        let top = try #require(entries.first)
        #expect(top.playerId == 650_333)
        #expect(top.playerName == "Arraez, Luis")
        #expect(top.attempts == 611)
        #expect(abs(top.avgLaunchAngle - 13.7) < 0.001)
        #expect(abs(top.maxExitVelocity - 108.4) < 0.001)
        #expect(abs(top.avgExitVelocity - 86.3) < 0.001)
        #expect(top.maxDistance == 401)
        #expect(top.avgDistance == 164)
        #expect(top.ev95Plus == 145)
        #expect(abs(top.hardHitRate - 23.7) < 0.001)
        #expect(top.barrels == 10)
        #expect(abs(top.barrelRate - 1.6) < 0.001)
        #expect(abs(top.barrelsPerPA - 1.5) < 0.001)
    }

    @Test("avgHomeRunDistance falls through optional decoder")
    func hrDistanceDecodes() throws {
        let entries = try loadEntries()
        // Non-nil for power hitter rows; let's pick Vlad Jr.
        let vlad = try #require(entries.first { $0.playerId == 665_489 })
        #expect(vlad.avgHomeRunDistance == 412)
    }
}

@Suite("Exit Velo & Barrels — Pitcher Tests")
struct ExitVeloBarrelsPitcherTests {
    private func loadEntries() throws -> [ExitVeloBarrelsPitcherEntry] {
        let data = try Fixtures.load("exit_velo_barrels_pitcher_2024.csv")
        let csv = try #require(String(data: data, encoding: .utf8))
        return ExitVeloBarrelsPitcherParser.parse(csv, season: 2024)
    }

    @Test("Decodes 15 pitcher rows")
    func decodesAllRows() throws {
        let entries = try loadEntries()
        #expect(entries.count == 15)
    }

    @Test("Webb top-of-board profile parses correctly")
    func webbTopOfBoard() throws {
        let entries = try loadEntries()
        let webb = try #require(entries.first { $0.playerId == 657_277 })
        #expect(webb.attempts == 617)
        #expect(abs(webb.maxExitVelocity - 120.4) < 0.001)
        #expect(abs(webb.avgExitVelocity - 89.8) < 0.001)
        #expect(webb.barrels == 43)
        #expect(abs(webb.barrelRate - 7.0) < 0.001)
        #expect(abs(webb.hardHitRate - 46.2) < 0.001)
    }

    @Test("Endpoint URL targets /leaderboard/statcast with type=pitcher")
    func endpointURL() throws {
        let endpoint = Endpoint(path: "leaderboard/statcast", queryItems: [
            URLQueryItem(name: "type", value: "pitcher"),
            URLQueryItem(name: "year", value: "2024"),
            URLQueryItem(name: "min", value: "q"),
            URLQueryItem(name: "csv", value: "true")
        ])
        let baseURL = try #require(URL(string: "https://baseballsavant.mlb.com/"))
        let built = try #require(endpoint.url(baseURL: baseURL))
        #expect(built.absoluteString.contains("type=pitcher"))
        #expect(built.absoluteString.contains("year=2024"))
        #expect(built.absoluteString.contains("min=q"))
    }
}
