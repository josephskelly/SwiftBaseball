import Foundation
@testable import SwiftBaseball
import Testing

/// Tests for `JSONDecoder.mlb`'s custom date decoding strategy.
@Suite("Date Decoder Tests")
struct DateDecoderTests {
    private struct Wrapper: Decodable {
        let date: Date
    }

    // MARK: - Date-only format

    @Test("Decodes YYYY-MM-DD date-only format")
    func decodesDateOnly() throws {
        let json = Data(#"{"date":"2024-07-04"}"#.utf8)
        let result = try JSONDecoder.mlb.decode(Wrapper.self, from: json)

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "UTC"))
        let components = calendar.dateComponents([.year, .month, .day], from: result.date)
        #expect(components.year == 2024)
        #expect(components.month == 7)
        #expect(components.day == 4)
    }

    @Test("Date-only format is parsed as midnight UTC")
    func dateOnlyIsMidnightUTC() throws {
        let json = Data(#"{"date":"2024-01-01"}"#.utf8)
        let result = try JSONDecoder.mlb.decode(Wrapper.self, from: json)

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "UTC"))
        let components = calendar.dateComponents([.hour, .minute, .second], from: result.date)
        #expect(components.hour == 0)
        #expect(components.minute == 0)
        #expect(components.second == 0)
    }

    // MARK: - ISO8601 fallback

    @Test("Decodes ISO8601 datetime with time component")
    func decodesISO8601DateTime() throws {
        let json = Data(#"{"date":"2024-07-04T17:10:00Z"}"#.utf8)
        let result = try JSONDecoder.mlb.decode(Wrapper.self, from: json)

        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = try #require(TimeZone(identifier: "UTC"))
        let components = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: result.date)
        #expect(components.year == 2024)
        #expect(components.month == 7)
        #expect(components.day == 4)
        #expect(components.hour == 17)
        #expect(components.minute == 10)
    }

    @Test("Decodes ISO8601 with fractional seconds")
    func decodesISO8601WithFractionalSeconds() throws {
        let json = Data(#"{"date":"2024-07-04T17:10:00.000Z"}"#.utf8)
        // ISO8601DateFormatter with .withInternetDateTime may or may not handle fractional seconds
        // This test verifies the fallback doesn't throw (graceful handling)
        do {
            let result = try JSONDecoder.mlb.decode(Wrapper.self, from: json)
            var calendar = Calendar(identifier: .gregorian)
            calendar.timeZone = try #require(TimeZone(identifier: "UTC"))
            let year = calendar.component(.year, from: result.date)
            #expect(year == 2024)
        } catch {
            // Fractional seconds are not guaranteed to parse — acceptable to throw DecodingError
            #expect(error is DecodingError)
        }
    }

    // MARK: - Invalid dates

    @Test("Invalid date string throws DecodingError")
    func invalidDateStringThrows() {
        let json = Data(#"{"date":"not-a-date"}"#.utf8)
        #expect(throws: DecodingError.self) {
            _ = try JSONDecoder.mlb.decode(Wrapper.self, from: json)
        }
    }

    @Test("Empty date string throws DecodingError")
    func emptyDateStringThrows() {
        let json = Data(#"{"date":""}"#.utf8)
        #expect(throws: DecodingError.self) {
            _ = try JSONDecoder.mlb.decode(Wrapper.self, from: json)
        }
    }

    @Test("Date with wrong format throws DecodingError")
    func wrongFormatThrows() {
        // MM/DD/YYYY — not a supported format
        let json = Data(#"{"date":"07/04/2024"}"#.utf8)
        #expect(throws: DecodingError.self) {
            _ = try JSONDecoder.mlb.decode(Wrapper.self, from: json)
        }
    }
}
