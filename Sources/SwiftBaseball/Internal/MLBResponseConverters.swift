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
                    batting: nil,   // Full stat parsing in Phase 4
                    pitching: nil,
                    fielding: nil
                )
            }
        }
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
