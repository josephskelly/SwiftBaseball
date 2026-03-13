import Foundation

/// Renders tabular data as an ASCII table.
public struct TableFormatter {
    public let headers: [String]
    public let rows: [[String]]

    public init(headers: [String], rows: [[String]]) {
        self.headers = headers
        self.rows = rows
    }

    /// Renders and returns the ASCII table as a string.
    public func render() -> String {
        guard !headers.isEmpty else { return "" }

        // Compute column widths
        var widths = headers.map(\.count)
        for row in rows {
            for (i, cell) in row.prefix(headers.count).enumerated() {
                widths[i] = max(widths[i], cell.count)
            }
        }

        let separator = "+" + widths.map { String(repeating: "-", count: $0 + 2) }.joined(separator: "+") + "+"

        func formatRow(_ cells: [String]) -> String {
            var line = "|"
            for (i, cell) in cells.prefix(headers.count).enumerated() {
                line += " " + cell.padding(toLength: widths[i], withPad: " ", startingAt: 0) + " |"
            }
            return line
        }

        var lines: [String] = []
        lines.append(separator)
        lines.append(formatRow(headers))
        lines.append(separator)
        for row in rows {
            lines.append(formatRow(row))
        }
        lines.append(separator)
        return lines.joined(separator: "\n")
    }

    /// Prints the table to stdout.
    public func print() {
        Swift.print(render())
    }
}
