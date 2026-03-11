import Foundation

/// Renders tabular data as an ASCII table.
struct TableFormatter {
    let headers: [String]
    let rows: [[String]]

    /// Renders and returns the ASCII table as a string.
    func render() -> String {
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
    func print() {
        Swift.print(render())
    }
}
