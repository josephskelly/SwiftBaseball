import Foundation

/// Shared `"yyyy-MM-dd"` formatter used by every public method that accepts a
/// `Date` for an MLB-API or Savant query parameter.
///
/// Locale is fixed to `en_US_POSIX` and the timezone is UTC, matching the
/// canonical wire format used by both the MLB Stats API and Baseball Savant.
enum MLBDateFormatter {
    static let shared: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    /// Formats a `Date` to `"yyyy-MM-dd"` UTC for use as a query parameter.
    static func string(from date: Date) -> String {
        shared.string(from: date)
    }

    /// Parses a `"yyyy-MM-dd"` string in UTC. Returns `nil` if the string
    /// doesn't match the expected format.
    static func date(from string: String) -> Date? {
        shared.date(from: string)
    }
}
