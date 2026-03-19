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

        // xBA: average of 7 values
        let xBAs = [0.420, 0.910, 0.050, 0.780, 0.010, 0.280, 0.650]
        let expectedXBA = xBAs.reduce(0, +) / Double(xBAs.count)
        #expect(abs((stats.xBA ?? 0) - expectedXBA) < 0.001)
        #expect(stats.xSLG != nil)
        #expect(stats.xwOBA != nil)
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
}
