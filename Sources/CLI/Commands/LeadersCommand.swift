import Foundation
import SwiftBaseball
import CLISupport

struct LeadersCommand {
    /// `leaders <stat> [--season YEAR] [--limit N]`
    static func run(args: [String]) async throws {
        guard let statName = args.first else { printUsage(); return }

        guard let category = LeaderStatCategory(rawValue: statName) else {
            print("Unknown stat category: \(statName)")
            print("Batting:  homeRuns, battingAverage, onBasePlusSlugging, rbi, hits, runs, doubles, triples, stolenBases")
            print("Pitching: earnedRunAverage, wins, strikeouts, saves, whip, inningsPitched, walksAndHitsPerInningPitched, strikeoutsPer9Inn")
            return
        }

        var seasonYear: Int?
        var limitCount: Int?

        var i = 1
        while i < args.count {
            switch args[i] {
            case "--season":
                i += 1
                if i < args.count { seasonYear = Int(args[i]) }
            case "--limit":
                i += 1
                if i < args.count { limitCount = Int(args[i]) }
            default:
                break
            }
            i += 1
        }

        var builder = SwiftBaseball.leaders(category)
        if let year = seasonYear { builder = builder.season(year) }
        if let n = limitCount { builder = builder.limit(n) }
        let categories = try await builder.fetch()

        for cat in categories {
            print("\n\(cat.leaderCategory) Leaders")
            let rows = cat.leaders.map { entry -> [String] in
                [String(entry.rank),
                 entry.player.fullName,
                 entry.team?.name ?? "-",
                 entry.value]
            }
            TableFormatter(
                headers: ["Rank", "Player", "Team", "Value"],
                rows: rows
            ).print()
        }
    }

    private static func printUsage() {
        print("Usage: baseball-cli leaders <stat> [--season YEAR] [--limit N]")
        print("Batting:  homeRuns, battingAverage, onBasePlusSlugging, rbi, hits, runs, doubles, triples, stolenBases")
        print("Pitching: earnedRunAverage, wins, strikeouts, saves, whip, inningsPitched, walksAndHitsPerInningPitched, strikeoutsPer9Inn")
    }
}
