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
    static func parse(_ text: String) -> [[String: String]] {
        let stripped = text.hasPrefix("\u{FEFF}") ? String(text.dropFirst()) : text
        let lines = stripped.components(separatedBy: "\n")
            .map { $0.trimmingCharacters(in: .carriageReturns) }
            .filter { !$0.isEmpty }
        guard let headerLine = lines.first else { return [] }
        let headers = parseRow(headerLine)
        return lines.dropFirst().map { line in
            let values = parseRow(line)
            var row: [String: String] = [:]
            for (index, header) in headers.enumerated() {
                let value = index < values.count ? values[index] : ""
                if !value.isEmpty {
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

private extension CharacterSet {
    static let carriageReturns = CharacterSet(charactersIn: "\r")
}
