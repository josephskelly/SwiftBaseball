import Foundation
import SwiftBaseball
import CLISupport

struct StandingsCommand {
    /// `standings [--season YEAR] [--league AL|NL]`
    static func run(args: [String]) async throws {
        var seasonYear: Int?
        var leagueFilter: League?

        var i = 0
        while i < args.count {
            switch args[i] {
            case "--season":
                i += 1
                if i < args.count { seasonYear = Int(args[i]) }
            case "--league":
                i += 1
                if i < args.count {
                    switch args[i].uppercased() {
                    case "AL": leagueFilter = .american
                    case "NL": leagueFilter = .national
                    default: print("Unknown league: \(args[i])"); return
                    }
                }
            default:
                break
            }
            i += 1
        }

        let year = seasonYear ?? Calendar.current.component(.year, from: Date())
        var builder = SwiftBaseball.standings(.season(year))
        if let league = leagueFilter {
            builder = builder.league(league)
        }
        let divisions = try await builder.fetch()

        for division in divisions {
            print("\n\(division.division)")
            let rows = division.teamRecords.map { r -> [String] in
                [r.team.name,
                 String(r.wins), String(r.losses),
                 String(format: "%.3f", r.winningPercentage),
                 r.gamesBack.map { String(format: "%.1f", $0) } ?? "-"]
            }
            TableFormatter(
                headers: ["Team", "W", "L", "PCT", "GB"],
                rows: rows
            ).print()
        }
    }
}
