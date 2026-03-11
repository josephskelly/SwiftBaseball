import Testing
import Foundation
@testable import SwiftBaseball

/// Tests for CLI-facing SwiftBaseball types: argument-parseable enums and category mappings.
@Suite("CLI Tests")
struct CLITests {

    // MARK: - StatGroup raw values (used for CLI argument parsing)

    @Test("StatGroup raw values match CLI argument strings")
    func statGroupRawValues() {
        #expect(StatGroup.batting.rawValue == "batting")
        #expect(StatGroup.pitching.rawValue == "pitching")
        #expect(StatGroup.fielding.rawValue == "fielding")
    }

    @Test("StatGroup round-trips through rawValue")
    func statGroupRoundTrip() {
        for group in [StatGroup.batting, .pitching, .fielding] {
            #expect(StatGroup(rawValue: group.rawValue) == group)
        }
    }

    // MARK: - LeaderStatCategory raw values

    @Test("Known leader categories round-trip through rawValue")
    func knownLeaderCategories() {
        let known: [(String, LeaderStatCategory)] = [
            ("homeRuns", .homeRuns),
            ("battingAverage", .battingAverage),
            ("earnedRunAverage", .earnedRunAverage),
            ("strikeouts", .strikeouts),
            ("wins", .wins),
            ("rbi", .rbi),
            ("stolenBases", .stolenBases),
            ("saves", .saves)
        ]
        for (raw, expected) in known {
            #expect(LeaderStatCategory(rawValue: raw) == expected)
        }
    }

    @Test("Unknown leader stat category raw value returns nil")
    func unknownLeaderCategory() {
        #expect(LeaderStatCategory(rawValue: "notAStat") == nil)
        #expect(LeaderStatCategory(rawValue: "") == nil)
    }

    // MARK: - League enum (used for --league flag parsing)

    @Test("League leagueId values are correct")
    func leagueIds() {
        #expect(League.american.leagueId == 103)
        #expect(League.national.leagueId == 104)
    }

    // MARK: - TableFormatter (self-contained, no SwiftBaseball dependency)

    @Test("TableFormatter renders header and rows")
    func tableFormatterBasic() {
        let rows = [["Aaron Judge", "58"], ["Shohei Ohtani", "54"]]
        let table = InlineTableFormatter(headers: ["Player", "HR"], rows: rows).render()
        #expect(table.contains("Aaron Judge"))
        #expect(table.contains("Shohei Ohtani"))
        #expect(table.contains("Player"))
        #expect(table.contains("HR"))
    }

    @Test("TableFormatter pads all content lines to equal width")
    func tableFormatterEqualWidth() {
        let table = InlineTableFormatter(
            headers: ["Name", "Value"],
            rows: [["A very long name", "1"], ["B", "99"]]
        ).render()
        let lines = table.split(separator: "\n").filter { $0.hasPrefix("|") }
        let lengths = Set(lines.map(\.count))
        #expect(lengths.count == 1)
    }

    @Test("TableFormatter empty rows produces header-only table")
    func tableFormatterEmptyRows() {
        let table = InlineTableFormatter(headers: ["X", "Y"], rows: []).render()
        #expect(table.contains("X"))
        #expect(!table.split(separator: "\n").filter { $0.hasPrefix("|") }.dropFirst().isEmpty == false)
    }

    @Test("TableFormatter empty headers returns empty string")
    func tableFormatterEmptyHeaders() {
        #expect(InlineTableFormatter(headers: [], rows: []).render().isEmpty)
    }
}

// MARK: - InlineTableFormatter (duplicate of CLI's TableFormatter for testability)

/// Mirrors `Sources/CLI/Formatting/TableFormatter.swift` for unit testing without
/// importing the executable target.
private struct InlineTableFormatter {
    let headers: [String]
    let rows: [[String]]

    func render() -> String {
        guard !headers.isEmpty else { return "" }
        var widths = headers.map(\.count)
        for row in rows {
            for (i, cell) in row.prefix(headers.count).enumerated() {
                widths[i] = max(widths[i], cell.count)
            }
        }
        let sep = "+" + widths.map { String(repeating: "-", count: $0 + 2) }.joined(separator: "+") + "+"
        func line(_ cells: [String]) -> String {
            var s = "|"
            for (i, cell) in cells.prefix(headers.count).enumerated() {
                s += " " + cell.padding(toLength: widths[i], withPad: " ", startingAt: 0) + " |"
            }
            return s
        }
        return ([sep, line(headers), sep] + rows.map { line($0) } + [sep]).joined(separator: "\n")
    }
}
