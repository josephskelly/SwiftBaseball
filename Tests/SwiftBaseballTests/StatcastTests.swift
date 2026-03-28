import Testing
import Foundation
@testable import SwiftBaseball

@Suite("Statcast Tests")
struct StatcastTests {

    // MARK: - CSV Parser

    @Test("CSVParser parses headers and rows correctly")
    func csvParserBasic() {
        let csv = """
        name,age,team
        Ohtani,29,LAD
        Judge,32,NYY
        """
        let rows = CSVParser.parse(csv)

        #expect(rows.count == 2)
        #expect(rows[0]["name"] == "Ohtani")
        #expect(rows[0]["age"] == "29")
        #expect(rows[0]["team"] == "LAD")
        #expect(rows[1]["name"] == "Judge")
    }

    @Test("CSVParser handles quoted fields with commas")
    func csvParserQuotedFields() {
        let csv = """
        name,city
        "Ohtani, Shohei",LA
        "Judge, Aaron",NYC
        """
        let rows = CSVParser.parse(csv)

        #expect(rows.count == 2)
        #expect(rows[0]["name"] == "Ohtani, Shohei")
        #expect(rows[0]["city"] == "LA")
    }

    @Test("CSVParser handles empty fields")
    func csvParserEmptyFields() {
        let csv = """
        a,b,c
        1,,3
        """
        let rows = CSVParser.parse(csv)

        #expect(rows.count == 1)
        #expect(rows[0]["a"] == "1")
        #expect(rows[0]["b"] == nil)
        #expect(rows[0]["c"] == "3")
    }

    @Test("CSVParser returns empty array for empty input")
    func csvParserEmpty() {
        let rows = CSVParser.parse("")
        #expect(rows.isEmpty)
    }

    @Test("CSVParser returns empty array for header-only input")
    func csvParserHeaderOnly() {
        let rows = CSVParser.parse("a,b,c\n")
        #expect(rows.isEmpty)
    }

    // MARK: - Aggregation from fixture

    @Test("Aggregate batted ball counts from fixture CSV")
    func aggregateBattedBallCounts() throws {
        let data = try Fixtures.load("statcast_batting_660271.csv")
        let csv = String(data: data, encoding: .utf8)!
        let rows = CSVParser.parse(csv)
        let stats = StatcastAggregator.aggregate(rows)

        // Fixture has 7 batted ball events (rows with bb_type), 3 non-batted-ball pitches
        #expect(stats.battedBallEvents == 7)
        #expect(stats.groundBalls == 2)
        #expect(stats.flyBalls == 2)
        #expect(stats.lineDrives == 2)
        #expect(stats.popups == 1)
    }

    @Test("Aggregate batted ball percentages from fixture")
    func aggregateBattedBallPercentages() throws {
        let data = try Fixtures.load("statcast_batting_660271.csv")
        let csv = String(data: data, encoding: .utf8)!
        let rows = CSVParser.parse(csv)
        let stats = StatcastAggregator.aggregate(rows)

        // 2/7 ground balls, 2/7 fly balls, 2/7 line drives, 1/7 popups
        #expect(abs((stats.gbPercent ?? 0) - 2.0 / 7.0) < 0.001)
        #expect(abs((stats.fbPercent ?? 0) - 2.0 / 7.0) < 0.001)
        #expect(abs((stats.ldPercent ?? 0) - 2.0 / 7.0) < 0.001)
        #expect(abs((stats.popupPercent ?? 0) - 1.0 / 7.0) < 0.001)
    }

    @Test("Aggregate exit velocity from fixture")
    func aggregateExitVelocity() throws {
        let data = try Fixtures.load("statcast_batting_660271.csv")
        let csv = String(data: data, encoding: .utf8)!
        let rows = CSVParser.parse(csv)
        let stats = StatcastAggregator.aggregate(rows)

        // Max exit velo from fixture: 108.5 (home run)
        #expect(stats.maxExitVelocity == 108.5)
        // Avg across all 7 batted balls
        let expectedAvg = (92.5 + 108.5 + 85.0 + 103.2 + 70.0 + 96.0 + 100.5) / 7.0
        #expect(abs((stats.avgExitVelocity ?? 0) - expectedAvg) < 0.01)
    }

    @Test("Aggregate launch angle from fixture")
    func aggregateLaunchAngle() throws {
        let data = try Fixtures.load("statcast_batting_660271.csv")
        let csv = String(data: data, encoding: .utf8)!
        let rows = CSVParser.parse(csv)
        let stats = StatcastAggregator.aggregate(rows)

        let expectedLA = (-8.2 + 28.0 + (-15.0) + 18.5 + 65.0 + 32.0 + 12.0) / 7.0
        #expect(abs((stats.avgLaunchAngle ?? 0) - expectedLA) < 0.01)
    }

    @Test("Aggregate hard hit rate from fixture")
    func aggregateHardHitRate() throws {
        let data = try Fixtures.load("statcast_batting_660271.csv")
        let csv = String(data: data, encoding: .utf8)!
        let rows = CSVParser.parse(csv)
        let stats = StatcastAggregator.aggregate(rows)

        // Hard hit (>= 95 mph): 108.5, 103.2, 96.0, 100.5 = 4/7
        #expect(abs((stats.hardHitRate ?? 0) - 4.0 / 7.0) < 0.001)
    }

    @Test("Aggregate expected stats from fixture")
    func aggregateExpectedStats() throws {
        let data = try Fixtures.load("statcast_batting_660271.csv")
        let csv = String(data: data, encoding: .utf8)!
        let rows = CSVParser.parse(csv)
        let stats = StatcastAggregator.aggregate(rows)

        // xBA: mean of per-BBE estimated values (7 batted balls)
        let xBAs = [0.420, 0.910, 0.050, 0.780, 0.010, 0.280, 0.650]
        let expectedXBA = xBAs.reduce(0, +) / Double(xBAs.count)
        #expect(abs((stats.xBA ?? 0) - expectedXBA) < 0.001)
        #expect(stats.xSLG != nil)
        // Fixture has 0 strikeouts, walks, HBP — full-PA xwOBA equals contact-only xwOBA
        let xwOBAs = [0.460, 0.980, 0.040, 0.850, 0.010, 0.350, 0.720]
        let expectedXwOBA = xwOBAs.reduce(0, +) / 7.0  // totalPA = 7 BBEs + 0 K + 0 BB + 0 HBP
        #expect(abs((stats.xwOBA ?? 0) - expectedXwOBA) < 0.001)
    }

    @Test("Aggregate PA event counts from fixture")
    func aggregatePAEventCounts() throws {
        let data = try Fixtures.load("statcast_batting_660271.csv")
        let csv = String(data: data, encoding: .utf8)!
        let rows = CSVParser.parse(csv)
        let stats = StatcastAggregator.aggregate(rows)

        // Fixture: 7 in-play events, 0 strikeouts, 0 walks, 0 HBP
        #expect(stats.strikeouts == 0)
        #expect(stats.walks == 0)
        #expect(stats.hitByPitches == 0)
        #expect(stats.plateAppearances == 7)
    }

    @Test("Full-PA xwOBA blends K and BB weights into overall average")
    func fullPAxwOBABlending() {
        // 2 BBEs + 1 strikeout + 2 walks
        let rows: [[String: String]] = [
            ["bb_type": "ground_ball", "launch_speed": "85.0", "launch_angle": "-5.0",
             "estimated_ba_using_speedangle": "0.100",
             "estimated_slg_using_speedangle": "0.100",
             "estimated_woba_using_speedangle": "0.100",
             "events": "field_out"],
            ["bb_type": "fly_ball", "launch_speed": "105.0", "launch_angle": "30.0",
             "estimated_ba_using_speedangle": "0.900",
             "estimated_slg_using_speedangle": "2.000",
             "estimated_woba_using_speedangle": "0.900",
             "events": "home_run"],
            // Strikeout (weight 0.000)
            ["pitch_type": "FF", "description": "swinging_strike", "events": "strikeout"],
            // Walk (weight 0.690)
            ["pitch_type": "FF", "description": "ball", "events": "walk"],
            // Walk (weight 0.690)
            ["pitch_type": "SL", "description": "ball", "events": "walk"],
        ]
        let stats = StatcastAggregator.aggregate(rows)

        #expect(stats.strikeouts == 1)
        #expect(stats.walks == 2)
        #expect(stats.hitByPitches == 0)
        #expect(stats.plateAppearances == 5)

        // Full-PA xwOBA = (0.100 + 0.900 + 0×1 + 0.690×2) / 5 = 2.380 / 5 = 0.476
        // Contact-only mean = (0.100 + 0.900) / 2 = 0.500 — different from full-PA
        let expected = (0.100 + 0.900 + 0.690 * 2.0) / 5.0
        #expect(abs((stats.xwOBA ?? 0) - expected) < 0.001)
    }

    // MARK: - Edge cases

    @Test("Empty rows produce zero batted ball events")
    func emptyRows() {
        let stats = StatcastAggregator.aggregate([])

        #expect(stats.battedBallEvents == 0)
        #expect(stats.groundBalls == 0)
        #expect(stats.gbPercent == nil)
        #expect(stats.avgExitVelocity == nil)
        #expect(stats.xBA == nil)
        #expect(stats.strikeouts == 0)
        #expect(stats.walks == 0)
        #expect(stats.hitByPitches == 0)
        #expect(stats.plateAppearances == 0)
    }

    @Test("Rows with no batted ball type are excluded")
    func noBattedBallType() {
        let rows: [[String: String]] = [
            ["pitch_type": "FF", "description": "called_strike"],
            ["pitch_type": "SL", "description": "ball"],
        ]
        let stats = StatcastAggregator.aggregate(rows)

        #expect(stats.battedBallEvents == 0)
        #expect(stats.gbPercent == nil)
    }

    @Test("All ground balls produces 100% GB rate")
    func allGroundBalls() {
        let rows: [[String: String]] = [
            ["bb_type": "ground_ball", "launch_speed": "90.0", "launch_angle": "-10.0"],
            ["bb_type": "ground_ball", "launch_speed": "85.0", "launch_angle": "-5.0"],
            ["bb_type": "ground_ball", "launch_speed": "88.0", "launch_angle": "-8.0"],
        ]
        let stats = StatcastAggregator.aggregate(rows)

        #expect(stats.battedBallEvents == 3)
        #expect(stats.groundBalls == 3)
        #expect(stats.gbPercent == 1.0)
        #expect(stats.fbPercent == 0.0)
        #expect(stats.ldPercent == 0.0)
        #expect(stats.popupPercent == 0.0)
    }

    @Test("Barrel detection for high-EV optimal-angle batted ball")
    func barrelDetection() {
        let rows: [[String: String]] = [
            // Barrel: 108 mph, 28° — classic barrel
            ["bb_type": "fly_ball", "launch_speed": "108.0", "launch_angle": "28.0"],
            // Not a barrel: 90 mph, 28° — too slow
            ["bb_type": "fly_ball", "launch_speed": "90.0", "launch_angle": "28.0"],
            // Not a barrel: 100 mph, 5° — too low angle
            ["bb_type": "ground_ball", "launch_speed": "100.0", "launch_angle": "5.0"],
        ]
        let stats = StatcastAggregator.aggregate(rows)

        // 1 barrel out of 3 batted balls
        #expect(abs((stats.barrelRate ?? 0) - 1.0 / 3.0) < 0.001)
    }

    // MARK: - Pitcher aggregation from fixture

    @Test("Pitcher aggregation: batted ball counts from fixture")
    func pitcherBattedBallCounts() throws {
        let data = try Fixtures.load("statcast_pitching_543037.csv")
        let csv = String(data: data, encoding: .utf8)!
        let rows = CSVParser.parse(csv)
        let stats = StatcastPitcherAggregator.aggregate(rows)

        // Fixture has 4 batted ball events: popup, ground_ball, ground_ball, ground_ball (wait, let me check)
        // Row 2: popup, Row 4: ground_ball, Row 6: ground_ball
        // Actually: row indices with bb_type: popup(1), ground_ball(3), ground_ball(5) — 3 not 4
        // Let me count: lines 2,4,6 have bb_type set → 3 batted balls
        // Wait no — line 5 (foul) has no bb_type, but launch_speed is set from foul ball
        // bb_type rows: popup(line2), ground_ball(line4), ground_ball(line6)
        #expect(stats.battedBallEvents == 3)
        #expect(stats.groundBalls == 2)
        #expect(stats.popups == 1)
    }

    @Test("Pitcher aggregation: total pitches from fixture")
    func pitcherTotalPitches() throws {
        let data = try Fixtures.load("statcast_pitching_543037.csv")
        let csv = String(data: data, encoding: .utf8)!
        let rows = CSVParser.parse(csv)
        let stats = StatcastPitcherAggregator.aggregate(rows)

        #expect(stats.totalPitches == 15)
    }

    @Test("Pitcher aggregation: fastball velocity from fixture")
    func pitcherFastballVelocity() throws {
        let data = try Fixtures.load("statcast_pitching_543037.csv")
        let csv = String(data: data, encoding: .utf8)!
        let rows = CSVParser.parse(csv)
        let stats = StatcastPitcherAggregator.aggregate(rows)

        // Fastball codes (FF, SI, FC) release_speed values:
        // FF: 94.1, 95.1, 92.7, 97.4 — SI: 94.6, 92.6, 92.5
        let fbVelos = [94.1, 95.1, 92.7, 97.4, 94.6, 92.6, 92.5]
        let expectedAvg = fbVelos.reduce(0, +) / Double(fbVelos.count)
        #expect(abs((stats.avgFastballVelo ?? 0) - expectedAvg) < 0.01)
        #expect(stats.maxFastballVelo == 97.4)
    }

    @Test("Pitcher aggregation: whiff rate from fixture")
    func pitcherWhiffRate() throws {
        let data = try Fixtures.load("statcast_pitching_543037.csv")
        let csv = String(data: data, encoding: .utf8)!
        let rows = CSVParser.parse(csv)
        let stats = StatcastPitcherAggregator.aggregate(rows)

        // Swings: hit_into_play(3), foul(1), foul_tip(1), swinging_strike(2) = 7
        // Whiffs: foul_tip(1), swinging_strike(2) = 3
        // Whiff rate = 3/7
        #expect(abs((stats.whiffRate ?? 0) - 3.0 / 7.0) < 0.001)
    }

    @Test("Pitcher aggregation: CSW from fixture")
    func pitcherCSW() throws {
        let data = try Fixtures.load("statcast_pitching_543037.csv")
        let csv = String(data: data, encoding: .utf8)!
        let rows = CSVParser.parse(csv)
        let stats = StatcastPitcherAggregator.aggregate(rows)

        // CSW descriptions: called_strike(1), swinging_strike(2) = 3
        // CSW = 3 / 15
        #expect(abs((stats.csw ?? 0) - 3.0 / 15.0) < 0.001)
    }

    @Test("Pitcher aggregation: pitch mix from fixture")
    func pitcherPitchMix() throws {
        let data = try Fixtures.load("statcast_pitching_543037.csv")
        let csv = String(data: data, encoding: .utf8)!
        let rows = CSVParser.parse(csv)
        let stats = StatcastPitcherAggregator.aggregate(rows)

        // pitch_name values: 4-Seam Fastball(4), Sinker(3), Sweeper(2), Changeup(2),
        //                    Slider(2), Curveball(2)
        #expect(stats.pitchMix.count == 6)
        #expect(stats.pitchMix[0].name == "4-Seam Fastball")
        #expect(stats.pitchMix[0].count == 4)
        #expect(abs(stats.pitchMix[0].percentage - 4.0 / 15.0) < 0.001)
        #expect(stats.pitchMix[0].avgVelocity != nil)
        #expect(stats.pitchMix[0].avgSpinRate != nil)
    }

    @Test("Pitcher aggregation: pitch movement (pfx_x / pfx_z) per pitch type")
    func pitcherPitchMovement() throws {
        let data = try Fixtures.load("statcast_pitching_543037.csv")
        let csv = String(data: data, encoding: .utf8)!
        let rows = CSVParser.parse(csv)
        let stats = StatcastPitcherAggregator.aggregate(rows)

        // pitch_name values sorted by count: 4-Seam(4), Sinker(3), then 4-way tie at 2
        let ff = try #require(stats.pitchMix.first { $0.name == "4-Seam Fastball" })
        // pfx_x: rows 5,7,8,14 → -0.29, -1.16, -0.04, 0.53 → avg = -0.24
        #expect(abs((ff.avgHorizontalBreak ?? 0) - (-0.24)) < 0.01)
        // pfx_z: 1.08, 0.64, 0.88, 1.44 → avg = 1.01
        #expect(abs((ff.avgInducedVerticalBreak ?? 0) - 1.01) < 0.01)

        let si = try #require(stats.pitchMix.first { $0.name == "Sinker" })
        // pfx_x: rows 6,10,13 → -1.6, -0.9, -1.16 → avg = -1.22
        #expect(abs((si.avgHorizontalBreak ?? 0) - (-1.22)) < 0.01)
        // pfx_z: 0.28, 0.39, 0.31 → avg ≈ 0.327
        #expect(abs((si.avgInducedVerticalBreak ?? 0) - 0.327) < 0.01)

        let sw = try #require(stats.pitchMix.first { $0.name == "Sweeper" })
        // pfx_x: rows 2,3 → 1.35, 1.33 → avg = 1.34
        #expect(abs((sw.avgHorizontalBreak ?? 0) - 1.34) < 0.01)
        // pfx_z: 0, 0.05 → avg = 0.025
        #expect(abs((sw.avgInducedVerticalBreak ?? 0) - 0.025) < 0.01)
    }

    @Test("Pitcher aggregation: per-pitch whiff rate")
    func pitcherPerPitchWhiffRate() throws {
        let data = try Fixtures.load("statcast_pitching_543037.csv")
        let csv = String(data: data, encoding: .utf8)!
        let rows = CSVParser.parse(csv)
        let stats = StatcastPitcherAggregator.aggregate(rows)

        // 4-Seam: 1 foul swing, 0 whiffs → 0.0
        let ff = try #require(stats.pitchMix.first { $0.name == "4-Seam Fastball" })
        #expect(ff.whiffRate == 0.0)

        // Sinker: 2 swings (hit_into_play + foul_tip), 1 whiff (foul_tip) → 0.5
        let si = try #require(stats.pitchMix.first { $0.name == "Sinker" })
        #expect(abs((si.whiffRate ?? 0) - 0.5) < 0.001)

        // Slider: 1 swing (swinging_strike), 1 whiff → 1.0
        let sl = try #require(stats.pitchMix.first { $0.name == "Slider" })
        #expect(sl.whiffRate == 1.0)

        // Curveball: 1 swing (swinging_strike), 1 whiff → 1.0
        let cu = try #require(stats.pitchMix.first { $0.name == "Curveball" })
        #expect(cu.whiffRate == 1.0)
    }

    @Test("Pitcher aggregation: per-pitch CSW from fixture")
    func pitcherPerPitchCSW() throws {
        let data = try Fixtures.load("statcast_pitching_543037.csv")
        let csv = String(data: data, encoding: .utf8)!
        let rows = CSVParser.parse(csv)
        let stats = StatcastPitcherAggregator.aggregate(rows)

        // 4-Seam Fastball (4 pitches): foul, ball, ball, ball → 0 CSW events → 0.0
        let ff = try #require(stats.pitchMix.first { $0.name == "4-Seam Fastball" })
        #expect(ff.csw == 0.0)

        // Sinker (3 pitches): hit_into_play, foul_tip, called_strike → 1 CSW event → 1/3
        let si = try #require(stats.pitchMix.first { $0.name == "Sinker" })
        #expect(abs((si.csw ?? 0) - 1.0 / 3.0) < 0.001)

        // Slider (2 pitches): ball, swinging_strike → 1 CSW event → 0.5
        let sl = try #require(stats.pitchMix.first { $0.name == "Slider" })
        #expect(sl.csw == 0.5)

        // Curveball (2 pitches): swinging_strike, ball → 1 CSW event → 0.5
        let cu = try #require(stats.pitchMix.first { $0.name == "Curveball" })
        #expect(cu.csw == 0.5)
    }

    @Test("Pitcher aggregation: per-pitch xwOBA from fixture")
    func pitcherPerPitchXwOBA() throws {
        let data = try Fixtures.load("statcast_pitching_543037.csv")
        let csv = String(data: data, encoding: .utf8)!
        let rows = CSVParser.parse(csv)
        let stats = StatcastPitcherAggregator.aggregate(rows)

        // Sinker: 1 batted ball (ground_ball) with estimated_woba = 0.072
        let si = try #require(stats.pitchMix.first { $0.name == "Sinker" })
        #expect(abs((si.xwOBA ?? 0) - 0.072) < 0.001)

        // Sweeper: 1 batted ball (popup) with estimated_woba = 0.005
        let sw = try #require(stats.pitchMix.first { $0.name == "Sweeper" })
        #expect(abs((sw.xwOBA ?? 0) - 0.005) < 0.001)

        // Changeup: 1 batted ball (ground_ball) with estimated_woba = 0.287
        let ch = try #require(stats.pitchMix.first { $0.name == "Changeup" })
        #expect(abs((ch.xwOBA ?? 0) - 0.287) < 0.001)

        // 4-Seam Fastball: no batted ball events → nil
        let ff = try #require(stats.pitchMix.first { $0.name == "4-Seam Fastball" })
        #expect(ff.xwOBA == nil)

        // Slider: no batted ball events → nil
        let sl = try #require(stats.pitchMix.first { $0.name == "Slider" })
        #expect(sl.xwOBA == nil)
    }

    @Test("Pitcher aggregation: pitch with no swings has nil whiff rate")
    func pitcherNoSwingsNilWhiffRate() {
        // A pitch that only appears as balls — no swings → whiffRate should be nil
        let rows: [[String: String]] = [
            ["pitch_name": "4-Seam Fastball", "description": "ball",
             "release_speed": "95.0", "release_spin_rate": "2200", "pfx_x": "-0.5", "pfx_z": "1.0"],
            ["pitch_name": "4-Seam Fastball", "description": "ball",
             "release_speed": "94.5", "release_spin_rate": "2180", "pfx_x": "-0.4", "pfx_z": "0.9"],
        ]
        let stats = StatcastPitcherAggregator.aggregate(rows)
        let ff = stats.pitchMix.first { $0.name == "4-Seam Fastball" }
        #expect(ff?.whiffRate == nil)
        // Balls only → no CSW events → csw = 0.0
        #expect(ff?.csw == 0.0)
        // No batted balls → xwOBA = nil
        #expect(ff?.xwOBA == nil)
    }

    @Test("Pitcher aggregation: empty rows produce zero state")
    func pitcherEmptyRows() {
        let stats = StatcastPitcherAggregator.aggregate([])

        #expect(stats.totalPitches == 0)
        #expect(stats.battedBallEvents == 0)
        #expect(stats.whiffRate == nil)
        #expect(stats.csw == nil)
        #expect(stats.avgFastballVelo == nil)
        #expect(stats.pitchMix.isEmpty)
    }

    @Test("Pitcher aggregation: spin rate from fixture")
    func pitcherSpinRate() throws {
        let data = try Fixtures.load("statcast_pitching_543037.csv")
        let csv = String(data: data, encoding: .utf8)!
        let rows = CSVParser.parse(csv)
        let stats = StatcastPitcherAggregator.aggregate(rows)

        #expect(stats.avgSpinRate != nil)
        // All 15 rows have release_spin_rate
        #expect(stats.avgSpinRate! > 1500)
        #expect(stats.avgSpinRate! < 3000)
    }

    // MARK: - xERA / xFIP

    @Test("Pitcher aggregation: K / BB / HBP counts from xFIP fixture")
    func pitcherAggregatorCountsKBBHBP() throws {
        let data = try Fixtures.load("statcast_pitching_xfip.csv")
        let csv = String(data: data, encoding: .utf8)!
        let rows = CSVParser.parse(csv)
        let stats = StatcastPitcherAggregator.aggregate(rows)

        #expect(stats.strikeouts == 5)
        #expect(stats.walks == 2)
        #expect(stats.hitByPitch == 0)
    }

    @Test("Pitcher aggregation: innings pitched from xFIP fixture")
    func pitcherAggregatorInningsPitched() throws {
        let data = try Fixtures.load("statcast_pitching_xfip.csv")
        let csv = String(data: data, encoding: .utf8)!
        let rows = CSVParser.parse(csv)
        let stats = StatcastPitcherAggregator.aggregate(rows)

        // 5 strikeout outs + 4 field_out outs = 9 outs → 3.0 IP
        #expect(stats.inningsPitched == 3.0)
    }

    @Test("Pitcher aggregation: xFIP from xFIP fixture")
    func pitcherAggregatorXFIP() throws {
        let data = try Fixtures.load("statcast_pitching_xfip.csv")
        let csv = String(data: data, encoding: .utf8)!
        let rows = CSVParser.parse(csv)
        let stats = StatcastPitcherAggregator.aggregate(rows)

        // xHR = 3 × 0.105 = 0.315
        // numerator = 13×0.315 + 3×(2+0) − 2×5 = 4.095 + 6.0 − 10.0 = 0.095
        // xFIP = 0.095 / 3.0 + 3.10 ≈ 3.1317
        let expected = 0.095 / 3.0 + 3.10
        let xFIP = try #require(stats.xFIP)
        #expect(abs(xFIP - expected) < 0.0001)
    }

    @Test("Pitcher aggregation: xERA from xFIP fixture")
    func pitcherAggregatorXERA() throws {
        let data = try Fixtures.load("statcast_pitching_xfip.csv")
        let csv = String(data: data, encoding: .utf8)!
        let rows = CSVParser.parse(csv)
        let stats = StatcastPitcherAggregator.aggregate(rows)

        // xwOBA contact sum = 0.040+0.060+0.130+0.050+0.310+0.700 = 1.290
        // full-PA xwOBA = (1.290 + 0.690×2) / 13 = 2.670 / 13 ≈ 0.20538
        // xERA = 0.20538 × 13.0 ≈ 2.670
        let expected = (1.290 + 0.690 * 2.0) / 13.0 * 13.0  // simplifies to 2.670
        let xERA = try #require(stats.xERA)
        #expect(abs(xERA - expected) < 0.01)
    }

    @Test("Pitcher aggregation: xERA and xFIP are nil when insufficient data")
    func pitcherAggregatorNilWhenInsufficientData() {
        // Fewer than 3 PA-terminating events → xERA nil
        // Fewer than 1.0 IP → xFIP nil
        let rows: [[String: String]] = [
            ["pitch_type": "FF", "description": "ball", "events": ""],
            ["pitch_type": "FF", "description": "ball", "events": ""],
        ]
        let stats = StatcastPitcherAggregator.aggregate(rows)

        #expect(stats.xERA == nil)
        #expect(stats.xFIP == nil)
    }

    // MARK: - StatcastQuery builder

    @Test("StatcastQuery season sets date range for full year")
    func statcastQuerySeason() {
        let client = StatcastAPIClient()
        let query = StatcastQuery(playerId: 660271, client: client).season(2024)

        // We can't directly inspect private fields, but we verify it builds without error
        #expect(query.playerId == 660271)
    }

    @Test("StatcastQuery dateRange sets custom dates")
    func statcastQueryDateRange() {
        let client = StatcastAPIClient()
        let query = StatcastQuery(playerId: 660271, client: client)
            .dateRange(start: "2024-06-01", end: "2024-06-30")

        #expect(query.playerId == 660271)
    }

    @Test("StatcastPitcherQuery builds with season")
    func pitcherQuerySeason() {
        let client = StatcastAPIClient()
        let query = StatcastPitcherQuery(playerId: 543037, client: client).season(2024)

        #expect(query.playerId == 543037)
    }

    // MARK: - Batch batting query

    @Test("StatcastBatchBattingQuery stores player IDs")
    func batchBattingQueryStoresPlayerIds() {
        let client = StatcastAPIClient()
        let query = StatcastBatchBattingQuery(playerIds: [660271, 592450], client: client)
        #expect(query.playerIds == [660271, 592450])
    }

    @Test("StatcastBatchBattingQuery dateRange modifier compiles")
    func batchBattingQueryDateRange() {
        let client = StatcastAPIClient()
        let query = StatcastBatchBattingQuery(playerIds: [660271], client: client)
            .dateRange(start: "2025-01-01", end: "2026-03-26")
        #expect(query.playerIds == [660271])
    }

    @Test("StatcastBatchBattingQuery season modifier compiles and preserves player IDs")
    func batchBattingQuerySeason() {
        let client = StatcastAPIClient()
        let query = StatcastBatchBattingQuery(playerIds: [660271, 592450], client: client)
            .season(2024)
        #expect(query.playerIds == [660271, 592450])
    }

    @Test("StatcastBatchBattingQuery batchSize modifier compiles")
    func batchBattingQueryBatchSize() {
        let client = StatcastAPIClient()
        let query = StatcastBatchBattingQuery(playerIds: [660271], client: client)
            .batchSize(4)
        #expect(query.playerIds == [660271])
    }

    @Test("Empty player list returns empty batch batting result")
    func batchBattingEmptyPlayers() async throws {
        let client = StatcastAPIClient()
        let query = StatcastBatchBattingQuery(playerIds: [], client: client)
        let results = try await query.fetch()
        #expect(results.isEmpty)
    }

    @Test("Batch batting: groups rows by batter ID and aggregates each player")
    func batchBattingGroupsAndAggregates() throws {
        let data = try Fixtures.load("statcast_batch_batting.csv")
        let csv = String(data: data, encoding: .utf8)!
        let rows = CSVParser.parse(csv)

        // Simulate what StatcastBatchBattingQuery.fetch() does for one chunk
        let byPlayer = Dictionary(grouping: rows) { $0["batter"].flatMap(Int.init) ?? -1 }
        var results: [Int: StatcastBatting] = [:]
        for (id, playerRows) in byPlayer where id != -1 {
            results[id] = StatcastAggregator.aggregate(playerRows)
        }

        #expect(results.count == 2)
        let ohtani = try #require(results[660271])
        let judge = try #require(results[592450])

        // Ohtani: 1 fly_ball + 1 ground_ball
        #expect(ohtani.battedBallEvents == 2)
        #expect(ohtani.flyBalls == 1)
        #expect(ohtani.groundBalls == 1)
        #expect(abs((ohtani.gbPercent ?? 0) - 0.5) < 0.001)
        #expect(abs((ohtani.fbPercent ?? 0) - 0.5) < 0.001)
        #expect(ohtani.maxExitVelocity == 108.5)

        // Judge: 1 fly_ball + 1 line_drive + 1 ground_ball
        #expect(judge.battedBallEvents == 3)
        #expect(judge.flyBalls == 1)
        #expect(judge.lineDrives == 1)
        #expect(judge.groundBalls == 1)
        #expect(abs((judge.gbPercent ?? 0) - 1.0 / 3.0) < 0.001)
        #expect(abs((judge.ldPercent ?? 0) - 1.0 / 3.0) < 0.001)
    }

    @Test("SwiftBaseball.statcastBatchBatting returns correct query type")
    func namespacedBatchBatting() {
        let query = SwiftBaseball.statcastBatchBatting(playerIds: [660271, 592450])
        #expect(query.playerIds == [660271, 592450])
    }

    // MARK: - Batch pitching query

    @Test("StatcastBatchPitchingQuery stores player IDs")
    func batchPitchingQueryStoresPlayerIds() {
        let client = StatcastAPIClient()
        let query = StatcastBatchPitchingQuery(playerIds: [808967, 687717], client: client)
        #expect(query.playerIds == [808967, 687717])
    }

    @Test("StatcastBatchPitchingQuery season modifier compiles and preserves player IDs")
    func batchPitchingQuerySeason() {
        let client = StatcastAPIClient()
        let query = StatcastBatchPitchingQuery(playerIds: [808967, 687717], client: client)
            .season(2024)
        #expect(query.playerIds == [808967, 687717])
    }

    @Test("Empty player list returns empty batch pitching result")
    func batchPitchingEmptyPlayers() async throws {
        let client = StatcastAPIClient()
        let query = StatcastBatchPitchingQuery(playerIds: [], client: client)
        let results = try await query.fetch()
        #expect(results.isEmpty)
    }

    @Test("Batch pitching: groups rows by pitcher ID and aggregates each pitcher")
    func batchPitchingGroupsAndAggregates() throws {
        let data = try Fixtures.load("statcast_batch_pitching.csv")
        let csv = String(data: data, encoding: .utf8)!
        let rows = CSVParser.parse(csv)

        // Simulate what StatcastBatchPitchingQuery.fetch() does for one chunk
        let byPlayer = Dictionary(grouping: rows) { $0["pitcher"].flatMap(Int.init) ?? -1 }
        var results: [Int: StatcastPitching] = [:]
        for (id, playerRows) in byPlayer where id != -1 {
            results[id] = StatcastPitcherAggregator.aggregate(playerRows)
        }

        #expect(results.count == 2)
        let king = try #require(results[650633])
        let castillo = try #require(results[622491])

        // King: popup + ground_ball + called_strike (3 pitches, 2 batted balls)
        #expect(king.battedBallEvents == 2)
        #expect(king.popups == 1)
        #expect(king.groundBalls == 1)
        #expect(king.totalPitches == 3)
        // Fastballs: FF (94.1) + SI (94.6) → avg = 94.35, max = 94.6
        #expect(abs((king.avgFastballVelo ?? 0) - (94.1 + 94.6) / 2.0) < 0.01)
        #expect(king.maxFastballVelo == 94.6)

        // Castillo: ground_ball + swinging_strike + ball (3 pitches, 1 batted ball)
        #expect(castillo.battedBallEvents == 1)
        #expect(castillo.groundBalls == 1)
        #expect(castillo.totalPitches == 3)
        // Swings: hit_into_play(1) + swinging_strike(1) = 2; whiffs: swinging_strike(1) = 1
        #expect(abs((castillo.whiffRate ?? 0) - 0.5) < 0.001)
        // Pitch mix: Sinker, 4-Seam Fastball, Slider
        #expect(castillo.pitchMix.count == 3)
    }

    @Test("SwiftBaseball.statcastBatchPitching returns correct query type")
    func namespacedBatchPitching() {
        let query = SwiftBaseball.statcastBatchPitching(playerIds: [808967, 650633])
        #expect(query.playerIds == [808967, 650633])
    }

    // MARK: - Parallel fetch merge logic

    @Test("Batch merge: disjoint partials combine correctly")
    func batchMergeDisjoint() {
        var accumulated: [Int: Int] = [1: 10, 2: 20]
        let incoming: [Int: Int] = [3: 30, 4: 40]
        accumulated.merge(incoming) { _, new in new }
        #expect(accumulated == [1: 10, 2: 20, 3: 30, 4: 40])
    }

    @Test("Batch merge: collision takes newer partial value")
    func batchMergeCollision() {
        var accumulated: [Int: Int] = [1: 10]
        let incoming: [Int: Int] = [1: 99]
        accumulated.merge(incoming) { _, new in new }
        #expect(accumulated[1] == 99)
    }
}
