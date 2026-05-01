import Foundation

/// Minimal CSV parser for Baseball Savant responses.
///
/// Handles quoted fields, embedded commas, and empty values.
/// Does not handle newlines within quoted fields (not needed for Statcast data).
enum CSVParser {
    /// Parses CSV text into an array of dictionaries keyed by header name.
    ///
    /// Strips a leading UTF-8 BOM (`U+FEFF`) if present — several Baseball Savant
    /// CSV exports prepend one, which would otherwise corrupt the first header key.
    /// CRLF and lone CR line endings are normalized to LF so the parser behaves
    /// identically on Darwin and swift-corelibs-foundation.
    static func parse(_ text: String) -> [[String: String]] {
        parse(text, preserveEmpty: false)
    }

    /// Parses CSV text, optionally retaining empty cells as `""` entries in each row dictionary.
    ///
    /// Default behavior (`preserveEmpty: false`) drops empty cells so callers can use
    /// `if let value = row[key]` as the empty-cell check. Pass `preserveEmpty: true` when
    /// the consumer needs to inspect every column that existed in the source CSV — e.g.
    /// the raw Statcast pitch model's `raw` escape hatch.
    static func parse(_ text: String, preserveEmpty: Bool) -> [[String: String]] {
        let stripped = text.hasPrefix("\u{FEFF}") ? String(text.dropFirst()) : text
        let normalized = stripped
            .replacingOccurrences(of: "\r\n", with: "\n")
            .replacingOccurrences(of: "\r", with: "\n")
        let lines = normalized.components(separatedBy: "\n")
            .filter { !$0.isEmpty }
        guard let headerLine = lines.first else { return [] }
        let headers = parseRow(headerLine)
        return lines.dropFirst().map { line in
            let values = parseRow(line)
            var row: [String: String] = [:]
            for (index, header) in headers.enumerated() {
                let value = index < values.count ? values[index] : ""
                if preserveEmpty || !value.isEmpty {
                    row[header] = value
                }
            }
            return row
        }
    }

    /// Parses a single CSV row, handling quoted fields.
    private static func parseRow(_ line: String) -> [String] {
        var fields: [String] = []
        var current = ""
        var inQuotes = false

        for char in line {
            if char == "\"" {
                inQuotes.toggle()
            } else if char == "," && !inQuotes {
                fields.append(current)
                current = ""
            } else {
                current.append(char)
            }
        }
        fields.append(current)
        return fields
    }
}
