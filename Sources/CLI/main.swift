import Foundation
import SwiftBaseball

// MARK: - Entry point

Task {
    let args = CommandLine.arguments.dropFirst() // drop executable name
    guard let command = args.first else {
        printUsage()
        exit(0)
    }
    let rest = Array(args.dropFirst())
    do {
        switch command {
        case "players":
            try await PlayersCommand.run(args: rest)
        case "standings":
            try await StandingsCommand.run(args: rest)
        case "stats":
            try await StatsCommand.run(args: rest)
        case "leaders":
            try await LeadersCommand.run(args: rest)
        case "--help", "-h", "help":
            printUsage()
        default:
            print("Unknown command: \(command)")
            printUsage()
            exit(1)
        }
    } catch {
        let message = "Error: \(error.localizedDescription)\n"
        FileHandle.standardError.write(Data(message.utf8))
        exit(1)
    }
    exit(0)
}

RunLoop.main.run()

func printUsage() {
    print("""
    baseball-cli — SwiftBaseball command-line interface

    USAGE:
      baseball-cli <command> [options]

    COMMANDS:
      players search <name>                Search players by name
      players id <id>                      Fetch player by MLB ID
      standings [--season YEAR] [--league AL|NL]
                                           Show division standings
      stats <batting|pitching|fielding> <playerID> [--season YEAR]
                                           Show player season stats
      leaders <stat> [--season YEAR] [--limit N]
                                           Show league leaders
                                           Stats: homeRuns, battingAverage, earnedRunAverage,
                                                  strikeouts, wins, rbi, stolenBases, saves

    EXAMPLES:
      baseball-cli players search "Shohei Ohtani"
      baseball-cli players id 660271
      baseball-cli standings --season 2024 --league AL
      baseball-cli stats batting 660271 --season 2024
      baseball-cli leaders homeRuns --season 2024 --limit 10
    """)
}
