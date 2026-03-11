import Foundation
import SwiftBaseball

struct PlayersCommand {
    /// `players search <name>`  or  `players id <id>`
    static func run(args: [String]) async throws {
        guard let sub = args.first else {
            printUsage(); return
        }
        switch sub {
        case "search":
            let name = args.dropFirst().joined(separator: " ")
            guard !name.isEmpty else { print("Usage: players search <name>"); return }
            let players = try await SwiftBaseball.players(.search(name)).fetch()
            renderPlayers(players)
        case "id":
            guard let idStr = args.dropFirst().first, let id = Int(idStr) else {
                print("Usage: players id <id>"); return
            }
            let player = try await SwiftBaseball.player(id: id).fetch()
            renderPlayers([player])
        default:
            printUsage()
        }
    }

    private static func renderPlayers(_ players: [Player]) {
        if players.isEmpty { print("No players found."); return }
        let rows = players.map { p -> [String] in
            [String(p.id), p.fullName, p.primaryPosition.displayName,
             p.currentTeam?.name ?? "-", p.birthDate.map { formatDate($0) } ?? "-"]
        }
        TableFormatter(
            headers: ["ID", "Name", "Position", "Team", "Born"],
            rows: rows
        ).print()
    }

    private static func formatDate(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        return f.string(from: date)
    }

    private static func printUsage() {
        print("Usage: baseball-cli players <search <name> | id <id>>")
    }
}
