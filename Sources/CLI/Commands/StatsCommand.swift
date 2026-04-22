import CLISupport
import Foundation
import SwiftBaseball

enum StatsCommand {
    /// `stats <batting|pitching> <playerID> [--season YEAR]`
    static func run(args: [String]) async throws {
        guard args.count >= 2 else { printUsage()
            return
        }

        let groupStr = args[0]
        guard let playerId = Int(args[1]) else { printUsage()
            return
        }

        let group: StatGroup
        switch groupStr.lowercased() {
        case "batting": group = .batting
        case "pitching": group = .pitching
        case "fielding": group = .fielding
        default: print("Unknown stat group: \(groupStr)")
            printUsage()
            return
        }

        var seasonYear: Int?
        var i = 2
        while i < args.count {
            if args[i] == "--season", i + 1 < args.count {
                seasonYear = Int(args[i + 1])
                i += 2
            } else {
                i += 1
            }
        }

        var builder = SwiftBaseball.playerStats(id: playerId).group(group)
        if let year = seasonYear {
            builder = builder.season(year)
        }
        let statsList = try await builder.fetch()

        if statsList.isEmpty {
            print("No stats found for player \(playerId).")
            return
        }

        for stats in statsList {
            print("\n\(stats.player.fullName) — \(stats.season) \(stats.group.rawValue)")
            if let b = stats.batting {
                renderBatting(b)
            } else if let p = stats.pitching {
                renderPitching(p)
            } else if let f = stats.fielding {
                renderFielding(f)
            }
        }
    }

    private static func renderBatting(_ b: BattingStats) {
        TableFormatter(
            headers: ["G", "PA", "AB", "H", "2B", "3B", "HR", "RBI", "SB", "BB", "SO", "AVG", "OBP", "SLG", "OPS"],
            rows: [[
                str(b.gamesPlayed), str(b.plateAppearances), str(b.atBats), str(b.hits),
                str(b.doubles), str(b.triples), str(b.homeRuns), str(b.rbi),
                str(b.stolenBases), str(b.baseOnBalls), str(b.strikeOuts),
                fmt(b.avg), fmt(b.obp), fmt(b.slg), fmt(b.ops)
            ]]
        ).print()
    }

    private static func renderPitching(_ p: PitchingStats) {
        TableFormatter(
            headers: ["G", "GS", "W", "L", "SV", "IP", "H", "ER", "BB", "SO", "ERA", "WHIP"],
            rows: [[
                str(p.gamesPlayed), str(p.gamesStarted), str(p.wins), str(p.losses),
                str(p.saves), fmt(p.inningsPitched), str(p.hits), str(p.earnedRuns),
                str(p.baseOnBalls), str(p.strikeOuts), fmt(p.era), fmt(p.whip)
            ]]
        ).print()
    }

    private static func renderFielding(_ f: FieldingStats) {
        TableFormatter(
            headers: ["G", "GS", "PO", "A", "E", "FLD%"],
            rows: [[
                str(f.gamesPlayed), str(f.gamesStarted),
                str(f.putOuts), str(f.assists), str(f.errors), fmt(f.fielding)
            ]]
        ).print()
    }

    private static func str(_ v: Int?) -> String {
        v.map(String.init) ?? "-"
    }

    private static func fmt(_ v: Double?) -> String {
        v.map { String(format: "%.3f", $0) } ?? "-"
    }

    private static func printUsage() {
        print("Usage: baseball-cli stats <batting|pitching|fielding> <playerID> [--season YEAR]")
    }
}
