import Foundation

// Converts internal MLB API raw response types into public model types.

enum MLBResponseConverters {

    // MARK: - Player

    static func player(from raw: MLBPerson) -> Player {
        Player(
            id: raw.id,
            fullName: raw.fullName,
            firstName: raw.firstName ?? "",
            lastName: raw.lastName ?? "",
            primaryNumber: raw.primaryNumber,
            birthDate: raw.birthDate.flatMap(parseDate),
            currentAge: raw.currentAge,
            birthCity: raw.birthCity,
            birthCountry: raw.birthCountry,
            height: raw.height,
            weight: raw.weight,
            active: raw.active ?? false,
            primaryPosition: position(from: raw.primaryPosition),
            batSide: handSide(from: raw.batSide?.code),
            pitchHand: handSide(from: raw.pitchHand?.code),
            currentTeam: raw.currentTeam.map(teamReference),
            mlbDebutDate: raw.mlbDebutDate.flatMap(parseDate)
        )
    }

    static func rosterEntry(from raw: MLBRosterEntry) -> RosterEntry {
        RosterEntry(
            person: playerReference(from: raw.person),
            jerseyNumber: raw.jerseyNumber,
            position: position(from: raw.position),
            status: raw.status?.description
        )
    }

    // MARK: - Team

    static func team(from raw: MLBTeam) -> Team {
        Team(
            id: raw.id,
            name: raw.name,
            teamName: raw.teamName ?? "",
            locationName: raw.locationName ?? "",
            abbreviation: raw.abbreviation ?? "",
            shortName: raw.shortName ?? raw.name,
            franchiseName: raw.franchiseName,
            clubName: raw.clubName,
            season: raw.season,
            firstYearOfPlay: raw.firstYearOfPlay,
            active: raw.active ?? true,
            league: leagueReference(from: raw.league),
            division: divisionReference(from: raw.division),
            venue: venueReference(from: raw.venue)
        )
    }

    // MARK: - Schedule

    static func scheduleEntries(from response: MLBScheduleResponse) -> [ScheduleEntry] {
        response.dates.flatMap { $0.games }.compactMap(scheduleEntry)
    }

    static func scheduleEntry(from raw: MLBGame) -> ScheduleEntry? {
        guard
            let teamsRaw = raw.teams,
            let awayTeam = teamsRaw.away.team,
            let homeTeam = teamsRaw.home.team
        else { return nil }

        let gameDate = parseDateTime(raw.gameDate) ?? Date()

        let awayEntry = ScheduleTeamEntry(
            team: TeamReference(id: awayTeam.id, name: awayTeam.displayName),
            score: teamsRaw.away.score,
            isWinner: teamsRaw.away.isWinner,
            splitSquad: teamsRaw.away.splitSquad,
            leagueRecord: teamsRaw.away.leagueRecord.map(leagueRecord)
        )
        let homeEntry = ScheduleTeamEntry(
            team: TeamReference(id: homeTeam.id, name: homeTeam.displayName),
            score: teamsRaw.home.score,
            isWinner: teamsRaw.home.isWinner,
            splitSquad: teamsRaw.home.splitSquad,
            leagueRecord: teamsRaw.home.leagueRecord.map(leagueRecord)
        )

        return ScheduleEntry(
            id: raw.gamePk,
            gameDate: gameDate,
            status: gameStatus(from: raw.status?.detailedState),
            teams: ScheduleTeams(away: awayEntry, home: homeEntry),
            venue: raw.venue.map(venueReference) ?? VenueReference(id: 0, name: ""),
            gameType: GameType(rawValue: raw.gameType ?? "R") ?? .regularSeason,
            season: raw.season ?? "",
            seriesDescription: raw.seriesDescription,
            gamesInSeries: raw.gamesInSeries,
            seriesGameNumber: raw.seriesGameNumber
        )
    }

    // MARK: - Standings

    static func divisionStandings(from response: MLBStandingsResponse) -> [DivisionStandings] {
        response.records.compactMap { record in
            guard let divRef = record.division else { return nil }
            let teamRecords = record.teamRecords.compactMap(standingsRecord)
            return DivisionStandings(
                division: divisionReference(from: divRef),
                teamRecords: teamRecords
            )
        }
    }

    static func standingsRecord(from raw: MLBTeamRecord) -> StandingsRecord? {
        guard let teamRef = raw.team else { return nil }
        let pct = Double(raw.winningPercentage) ?? 0.0

        let lastTen: LastTen
        if let splits = raw.records?.splitRecords,
           let l10 = splits.first(where: { $0.type == "lastTen" }) {
            lastTen = LastTen(wins: l10.wins, losses: l10.losses, pct: l10.pct)
        } else {
            lastTen = LastTen(wins: 0, losses: 0, pct: ".000")
        }

        return StandingsRecord(
            team: teamReference(from: teamRef),
            wins: raw.wins,
            losses: raw.losses,
            winningPercentage: pct,
            gamesBack: raw.gamesBack.flatMap(Double.init),
            wildCardGamesBack: raw.wildCardGamesBack.flatMap(Double.init),
            divisionRank: Int(raw.divisionRank ?? "0") ?? 0,
            leagueRank: Int(raw.leagueRank ?? "0") ?? 0,
            wildCardRank: raw.wildCardRank.flatMap(Int.init),
            divisionChamp: raw.divisionChamp ?? false,
            divisionLeader: raw.divisionLeader ?? false,
            hasWildCard: raw.hasWildCard ?? false,
            clinched: raw.clinched ?? false,
            eliminationNumber: raw.eliminationNumber,
            streak: Streak(
                streakType: raw.streak?.streakType,
                streakNumber: raw.streak?.streakNumber,
                streakCode: raw.streak?.streakCode
            ),
            lastTen: lastTen,
            runsAllowed: raw.runsAllowed,
            runsScored: raw.runsScored,
            runDifferential: raw.runDifferential
        )
    }

    // MARK: - Leaders

    static func leaderEntries(from response: MLBLeadersResponse) -> [LeaderCategory] {
        response.leagueLeaders.map { cat in
            LeaderCategory(
                leaderCategory: cat.leaderCategory ?? "",
                leaders: cat.leaders.compactMap(leaderEntry)
            )
        }
    }

    static func leaderEntry(from raw: MLBLeaderEntry) -> LeaderEntry? {
        guard let personRef = raw.person else { return nil }
        return LeaderEntry(
            rank: raw.rank ?? 0,
            value: raw.value ?? "",
            player: playerReference(from: personRef),
            team: raw.team.map(teamReference),
            season: raw.season,
            leagueRank: raw.leagueRank
        )
    }

    // MARK: - Player stats

    static func playerSeasonStats(
        from response: MLBPlayerStatsResponse,
        playerRef: PlayerReference
    ) -> [PlayerSeasonStats] {
        response.stats.flatMap { statGroup -> [PlayerSeasonStats] in
            let groupCode = statGroup.group?.code ?? ""
            let group = StatGroup(apiValue: groupCode)
            return statGroup.splits.map { split in
                PlayerSeasonStats(
                    player: split.player.map(playerReference) ?? playerRef,
                    team: split.team.map(teamReference),
                    season: split.season ?? "",
                    group: group,
                    batting: group == .batting ? battingStats(from: split.stat) : nil,
                    pitching: group == .pitching ? pitchingStats(from: split.stat) : nil,
                    fielding: group == .fielding ? fieldingStats(from: split.stat) : nil
                )
            }
        }
    }

    private static func battingStats(from raw: MLBStatPayload) -> BattingStats {
        BattingStats(
            gamesPlayed: raw.gamesPlayed, plateAppearances: raw.plateAppearances,
            atBats: raw.atBats, runs: raw.runs, hits: raw.hits,
            doubles: raw.doubles, triples: raw.triples, homeRuns: raw.homeRuns,
            rbi: raw.rbi, stolenBases: raw.stolenBases,
            caughtStealing: raw.caughtStealing, baseOnBalls: raw.baseOnBalls,
            intentionalWalks: raw.intentionalWalks, strikeOuts: raw.strikeOuts,
            hitByPitch: raw.hitByPitch, sacFlies: raw.sacFlies,
            sacBunts: raw.sacBunts, groundIntoDoublePlay: raw.groundIntoDoublePlay,
            totalBases: raw.totalBases, leftOnBase: raw.leftOnBase,
            avg: raw.avg.flatMap(Double.init), obp: raw.obp.flatMap(Double.init),
            slg: raw.slg.flatMap(Double.init), ops: raw.ops.flatMap(Double.init),
            babip: raw.babip.flatMap(Double.init)
        )
    }

    private static func pitchingStats(from raw: MLBStatPayload) -> PitchingStats {
        PitchingStats(
            gamesPlayed: raw.gamesPlayed, gamesStarted: raw.gamesStarted,
            wins: raw.wins, losses: raw.losses, saves: raw.saves,
            saveOpportunities: raw.saveOpportunities, holds: raw.holds,
            blownSaves: raw.blownSaves, completeGames: raw.completeGames,
            shutouts: raw.shutouts, hits: raw.hits, runs: raw.runs,
            earnedRuns: raw.earnedRuns, homeRuns: raw.homeRunsAllowed,
            baseOnBalls: raw.baseOnBalls, intentionalWalks: raw.intentionalWalks,
            strikeOuts: raw.strikeOuts, hitByPitch: raw.hitByPitch,
            wildPitches: raw.wildPitches, balks: raw.balks,
            battersFaced: raw.battersFaced,
            era: raw.era.flatMap(Double.init), whip: raw.whip.flatMap(Double.init),
            avg: raw.avg.flatMap(Double.init),
            inningsPitched: raw.inningsPitched.flatMap(Double.init)
        )
    }

    private static func fieldingStats(from raw: MLBStatPayload) -> FieldingStats {
        FieldingStats(
            gamesPlayed: raw.gamesPlayed, gamesStarted: raw.gamesStarted,
            assists: raw.assists, putOuts: raw.putOuts, errors: raw.errors,
            chances: raw.chances, doublePlays: raw.doublePlays,
            triplePlays: raw.triplePlays, passedBalls: raw.passedBalls,
            innings: raw.innings.flatMap(Double.init),
            fielding: raw.fielding.flatMap(Double.init)
        )
    }

    // MARK: - Boxscore

    static func boxscore(from response: MLBBoxscoreResponse) -> Boxscore {
        guard let teams = response.teams else {
            return Boxscore(teams: BoxscoreTeams(
                away: emptyBoxscoreTeam(),
                home: emptyBoxscoreTeam()
            ), officials: nil, info: nil)
        }
        return Boxscore(
            teams: BoxscoreTeams(
                away: boxscoreTeam(from: teams.away),
                home: boxscoreTeam(from: teams.home)
            ),
            officials: response.officials?.compactMap(official),
            info: response.info?.compactMap(boxscoreInfoItem)
        )
    }

    private static func boxscoreTeam(from raw: MLBBoxscoreTeam) -> BoxscoreTeam {
        let team = raw.team.map(teamReference) ?? TeamReference(id: 0, name: "")
        let stats = BoxscoreTeamStats(
            batting: raw.teamStats?.batting ?? emptyBattingStats(),
            pitching: raw.teamStats?.pitching ?? emptyPitchingStats(),
            fielding: raw.teamStats?.fielding ?? emptyFieldingStats()
        )
        let players: [String: BoxscorePlayer]? = raw.players?.reduce(into: [:]) { result, pair in
            let (key, value) = pair
            result[key] = boxscorePlayer(from: value)
        }
        return BoxscoreTeam(
            team: team,
            teamStats: stats,
            players: players,
            batters: raw.batters,
            pitchers: raw.pitchers,
            battingOrder: raw.battingOrder,
            note: raw.note?.compactMap(boxscoreInfoItem)
        )
    }

    private static func boxscorePlayer(from raw: MLBBoxscorePlayer) -> BoxscorePlayer {
        let person = raw.person.map(playerReference)
            ?? PlayerReference(id: 0, fullName: "")
        let pos = position(from: raw.position)
        let stats = BoxscorePlayerStats(
            batting: raw.stats?.batting ?? emptyBattingStats(),
            pitching: raw.stats?.pitching ?? emptyPitchingStats(),
            fielding: raw.stats?.fielding ?? emptyFieldingStats()
        )
        return BoxscorePlayer(
            person: person,
            jerseyNumber: raw.jerseyNumber,
            position: pos,
            stats: stats,
            battingOrder: raw.battingOrder
        )
    }

    private static func official(from raw: MLBOfficial) -> Official? {
        guard let ref = raw.official else { return nil }
        return Official(
            official: playerReference(from: ref),
            officialType: raw.officialType ?? ""
        )
    }

    private static func boxscoreInfoItem(from raw: MLBBoxscoreInfo) -> BoxscoreInfoItem? {
        guard let label = raw.label else { return nil }
        return BoxscoreInfoItem(label: label, value: raw.value)
    }

    private static func emptyBoxscoreTeam() -> BoxscoreTeam {
        BoxscoreTeam(
            team: TeamReference(id: 0, name: ""),
            teamStats: BoxscoreTeamStats(
                batting: emptyBattingStats(),
                pitching: emptyPitchingStats(),
                fielding: emptyFieldingStats()
            ),
            players: nil, batters: nil, pitchers: nil, battingOrder: nil, note: nil
        )
    }

    // MARK: - Private helpers

    private static func position(from raw: MLBPositionObject?) -> Position {
        guard let code = raw?.code else { return .unknown }
        return Position(rawValue: code) ?? .unknown
    }

    private static func handSide(from code: String?) -> HandSide {
        guard let code else { return .unknown }
        return HandSide(rawValue: code) ?? .unknown
    }

    private static func teamReference(from raw: MLBEntityRef) -> TeamReference {
        TeamReference(id: raw.id, name: raw.displayName)
    }

    private static func leagueReference(from raw: MLBEntityRef?) -> LeagueReference {
        LeagueReference(id: raw?.id ?? 0, name: raw?.displayName ?? "")
    }

    private static func divisionReference(from raw: MLBEntityRef) -> DivisionReference {
        DivisionReference(id: raw.id, name: raw.displayName)
    }

    private static func divisionReference(from raw: MLBEntityRef?) -> DivisionReference {
        DivisionReference(id: raw?.id ?? 0, name: raw?.displayName ?? "")
    }

    private static func venueReference(from raw: MLBEntityRef) -> VenueReference {
        VenueReference(id: raw.id, name: raw.displayName)
    }

    private static func venueReference(from raw: MLBEntityRef?) -> VenueReference {
        VenueReference(id: raw?.id ?? 0, name: raw?.displayName ?? "")
    }

    private static func playerReference(from raw: MLBEntityRef) -> PlayerReference {
        PlayerReference(id: raw.id, fullName: raw.fullName ?? raw.name ?? "")
    }

    private static func leagueRecord(from raw: MLBLeagueRecord) -> LeagueRecord {
        LeagueRecord(wins: raw.wins, losses: raw.losses, pct: raw.pct)
    }

    private static func gameStatus(from detailedState: String?) -> GameStatus {
        guard let state = detailedState else { return .scheduled }
        return GameStatus(rawValue: state) ?? .scheduled
    }

    private static func emptyBattingStats() -> BattingStats { .empty }
    private static func emptyPitchingStats() -> PitchingStats { .empty }
    private static func emptyFieldingStats() -> FieldingStats { .empty }

    private static let dateOnlyFormatter: DateFormatter = {
        let f = DateFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.timeZone = TimeZone(identifier: "UTC")
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    private static func parseDate(_ string: String) -> Date? {
        dateOnlyFormatter.date(from: string)
    }

    private static func parseDateTime(_ string: String) -> Date? {
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime]
        return iso.date(from: string) ?? parseDate(string)
    }
}

// MARK: - StatGroup from MLB API group name

private extension StatGroup {
    init(apiValue: String) {
        switch apiValue.lowercased() {
        case "hitting": self = .batting
        case "pitching": self = .pitching
        case "fielding": self = .fielding
        default: self = .batting
        }
    }
}
