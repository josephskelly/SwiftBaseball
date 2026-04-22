import Foundation
@testable import SwiftBaseball
import Testing

@Suite("Attendance Tests")
struct AttendanceTests {
    private func loadRecords() throws -> [TeamAttendance] {
        let data = try Fixtures.load("attendance_147_2024.json")
        let response = try JSONDecoder.mlb.decode(MLBAttendanceResponse.self, from: data)
        return MLBResponseConverters.attendance(from: response)
    }

    @Test("Records decode into TeamAttendance entries")
    func recordsDecode() throws {
        let records = try loadRecords()
        #expect(records.count == 1)
    }

    @Test("Team reference and season are populated")
    func teamAndYear() throws {
        let record = try #require(try loadRecords().first)

        #expect(record.team.id == 147)
        #expect(record.team.name == "New York Yankees")
        #expect(record.year == "2024")
    }

    @Test("Game type decodes as regular season")
    func gameType() throws {
        let record = try #require(try loadRecords().first)
        #expect(record.gameType == .regularSeason)
    }

    @Test("Totals and averages carry through")
    func totals() throws {
        let record = try #require(try loadRecords().first)

        #expect(record.gamesTotal == 165)
        #expect(record.gamesHomeTotal == 83)
        #expect(record.gamesAwayTotal == 82)

        #expect(record.attendanceTotal == 5_947_960)
        #expect(record.attendanceTotalHome == 3_309_838)
        #expect(record.attendanceTotalAway == 2_638_122)

        #expect(record.attendanceAverageYtd == 37_175)
        #expect(record.attendanceAverageHome == 41_897)
        #expect(record.attendanceAverageAway == 32_569)
        #expect(record.attendanceOpeningAverage == 40_849)
    }

    @Test("High and low flatten gamePk from the nested game ref")
    func highAndLow() throws {
        let record = try #require(try loadRecords().first)

        #expect(record.attendanceHigh == 48_760)
        #expect(record.attendanceHighGamePk == 745_716)

        #expect(record.attendanceLow == 30_060)
        #expect(record.attendanceLowGamePk == 745_709)
    }

    @Test("High and low dates parse to UTC midnight")
    func highAndLowDates() throws {
        let record = try #require(try loadRecords().first)

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC") ?? .current

        let high = try #require(record.attendanceHighDate)
        let highComponents = calendar.dateComponents([.year, .month, .day], from: high)
        #expect(highComponents.year == 2024)
        #expect(highComponents.month == 7)
        #expect(highComponents.day == 24)

        let low = try #require(record.attendanceLowDate)
        let lowComponents = calendar.dateComponents([.year, .month, .day], from: low)
        #expect(lowComponents.year == 2024)
        #expect(lowComponents.month == 8)
        #expect(lowComponents.day == 7)
    }

    @Test("Records without team or year are skipped")
    func skipsIncompleteRecords() throws {
        let json = #"""
        {"records":[{"year":"2024"},{"team":{"id":147,"name":"Yankees"}}]}
        """#
        let data = Data(json.utf8)
        let response = try JSONDecoder.mlb.decode(MLBAttendanceResponse.self, from: data)
        let records = MLBResponseConverters.attendance(from: response)
        #expect(records.isEmpty)
    }

    @Test("Unknown game type falls through to nil")
    func unknownGameType() throws {
        let json = #"""
        {"records":[{"team":{"id":1,"name":"X"},"year":"2024","gameType":{"id":"ZZ","description":"Unknown"}}]}
        """#
        let data = Data(json.utf8)
        let response = try JSONDecoder.mlb.decode(MLBAttendanceResponse.self, from: data)
        let record = try #require(MLBResponseConverters.attendance(from: response).first)
        #expect(record.gameType == nil)
    }

    @Test("Endpoint URL targets /attendance with teamId and season")
    func endpointURL() throws {
        let endpoint = Endpoint(path: "attendance", queryItems: [
            URLQueryItem(name: "teamId", value: "147"),
            URLQueryItem(name: "season", value: "2024")
        ])
        let baseURL = try #require(URL(string: "https://statsapi.mlb.com/api/v1/"))
        let built = try #require(endpoint.url(baseURL: baseURL))
        #expect(built.absoluteString == "https://statsapi.mlb.com/api/v1/attendance?teamId=147&season=2024")
    }
}
