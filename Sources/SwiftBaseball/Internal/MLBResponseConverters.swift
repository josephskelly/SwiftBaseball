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
            mlbDebutDate: raw.mlbDebutDate.flatMap(parseDate),
            alumniLastSeason: raw.alumniLastSeason
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

    static func teamStaff(from raw: MLBCoach) -> TeamStaff {
        TeamStaff(
            person: playerReference(from: raw.person),
            jerseyNumber: raw.jerseyNumber,
            job: raw.job ?? "",
            jobId: raw.jobId ?? "",
            title: raw.title
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
            venue: venueReference(from: raw.venue),
            sportName: raw.sport?.name,
            parentOrgId: raw.parentOrgId,
            parentOrgName: raw.parentOrgName
        )
    }

    // MARK: - Schedule

    static func scheduleEntries(from response: MLBScheduleResponse) -> [ScheduleEntry] {
        response.dates.flatMap(\.games).compactMap(scheduleEntry)
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
            leagueRecord: teamsRaw.away.leagueRecord.map(leagueRecord),
            probablePitcher: teamsRaw.away.probablePitcher.map(playerReference)
        )
        let homeEntry = ScheduleTeamEntry(
            team: TeamReference(id: homeTeam.id, name: homeTeam.displayName),
            score: teamsRaw.home.score,
            isWinner: teamsRaw.home.isWinner,
            splitSquad: teamsRaw.home.splitSquad,
            leagueRecord: teamsRaw.home.leagueRecord.map(leagueRecord),
            probablePitcher: teamsRaw.home.probablePitcher.map(playerReference)
        )

        return ScheduleEntry(
            id: raw.gamePk,
            gameDate: gameDate,
            status: gameStatus(from: raw.status?.detailedState, abstractGameState: raw.status?.abstractGameState),
            teams: ScheduleTeams(away: awayEntry, home: homeEntry),
            venue: raw.venue.map(venueReference),
            gameType: GameType(rawValue: raw.gameType ?? "") ?? .unknown,
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

        let l10 = raw.records?.splitRecords?.first { $0.type == "lastTen" }
        let lastTen = l10.map { LastTen(wins: $0.wins, losses: $0.losses, pct: $0.pct) }
            ?? LastTen(wins: 0, losses: 0, pct: ".000")

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
            let groupCode = statGroup.group?.displayName ?? ""
            let group = StatGroup(apiValue: groupCode)
            return statGroup.splits.map { split in
                let sport = split.sport.flatMap { Sport(rawValue: $0.id) }
                let league = split.league.map { leagueReference(from: $0) }
                return PlayerSeasonStats(
                    player: split.player.map(playerReference) ?? playerRef,
                    team: split.team.map(teamReference),
                    season: split.season ?? "",
                    group: group,
                    batting: group == .batting ? battingStats(from: split.stat) : nil,
                    pitching: group == .pitching ? pitchingStats(from: split.stat) : nil,
                    fielding: group == .fielding ? fieldingStats(from: split.stat) : nil,
                    sabermetrics: nil,
                    sport: sport,
                    league: league
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

    /// Builds batter platoon stats by deduplicating and aggregating splits
    /// across all game types.
    ///
    /// When the MLB API receives comma-separated `gameType` values (e.g.
    /// `R,S,E,F,D,L,W,A`), it returns duplicate splits — the same
    /// `(splitCode, gameType)` pair repeated N times (once per requested type).
    /// This method deduplicates by `(splitCode, gameType)`, then sums counting
    /// stats across game types to produce a single aggregated vL and vR result.
    static func playerPlatoonStats(
        from response: MLBPlayerStatsResponse,
        playerRef: PlayerReference
    ) -> PlayerPlatoonStats {
        let unique = deduplicatedSplits(from: response)
        let vlStats = unique.filter { $0.split?.code == "vl" }.map { battingStats(from: $0.stat) }
        let vrStats = unique.filter { $0.split?.code == "vr" }.map { battingStats(from: $0.stat) }
        return PlayerPlatoonStats(
            vsLeft: aggregateBattingStats(vlStats),
            vsRight: aggregateBattingStats(vrStats)
        )
    }

    /// Builds pitcher platoon stats by deduplicating and aggregating splits
    /// across all game types.
    static func pitcherPlatoonStats(
        from response: MLBPlayerStatsResponse,
        playerRef: PlayerReference
    ) -> PitcherPlatoonStats {
        let unique = deduplicatedSplits(from: response)
        let vlStats = unique.filter { $0.split?.code == "vl" }.map { pitchingStats(from: $0.stat) }
        let vrStats = unique.filter { $0.split?.code == "vr" }.map { pitchingStats(from: $0.stat) }
        return PitcherPlatoonStats(
            vsLeft: aggregatePitchingStats(vlStats),
            vsRight: aggregatePitchingStats(vrStats)
        )
    }

    // MARK: - Home/Away splits

    /// Builds batter home/away splits by deduplicating and aggregating across game types.
    static func playerHomeAwaySplits(
        from response: MLBPlayerStatsResponse,
        playerRef: PlayerReference
    ) -> PlayerHomeAwaySplits {
        let unique = deduplicatedSplits(from: response)
        let homeStats = unique.filter { $0.split?.code == "h" }.map { battingStats(from: $0.stat) }
        let awayStats = unique.filter { $0.split?.code == "a" }.map { battingStats(from: $0.stat) }
        return PlayerHomeAwaySplits(
            home: aggregateBattingStats(homeStats),
            away: aggregateBattingStats(awayStats)
        )
    }

    /// Builds pitcher home/away splits by deduplicating and aggregating across game types.
    static func pitcherHomeAwaySplits(
        from response: MLBPlayerStatsResponse,
        playerRef: PlayerReference
    ) -> PitcherHomeAwaySplits {
        let unique = deduplicatedSplits(from: response)
        let homeStats = unique.filter { $0.split?.code == "h" }.map { pitchingStats(from: $0.stat) }
        let awayStats = unique.filter { $0.split?.code == "a" }.map { pitchingStats(from: $0.stat) }
        return PitcherHomeAwaySplits(
            home: aggregatePitchingStats(homeStats),
            away: aggregatePitchingStats(awayStats)
        )
    }

    // MARK: - Day/Night splits

    /// Builds batter day/night splits by deduplicating and aggregating across game types.
    static func playerDayNightSplits(
        from response: MLBPlayerStatsResponse,
        playerRef: PlayerReference
    ) -> PlayerDayNightSplits {
        let unique = deduplicatedSplits(from: response)
        let dayStats = unique.filter { $0.split?.code == "d" }.map { battingStats(from: $0.stat) }
        let nightStats = unique.filter { $0.split?.code == "n" }.map { battingStats(from: $0.stat) }
        return PlayerDayNightSplits(
            day: aggregateBattingStats(dayStats),
            night: aggregateBattingStats(nightStats)
        )
    }

    /// Builds pitcher day/night splits by deduplicating and aggregating across game types.
    static func pitcherDayNightSplits(
        from response: MLBPlayerStatsResponse,
        playerRef: PlayerReference
    ) -> PitcherDayNightSplits {
        let unique = deduplicatedSplits(from: response)
        let dayStats = unique.filter { $0.split?.code == "d" }.map { pitchingStats(from: $0.stat) }
        let nightStats = unique.filter { $0.split?.code == "n" }.map { pitchingStats(from: $0.stat) }
        return PitcherDayNightSplits(
            day: aggregatePitchingStats(dayStats),
            night: aggregatePitchingStats(nightStats)
        )
    }

    /// Builds batter monthly splits by deduplicating and aggregating across game types.
    static func playerMonthlySplits(
        from response: MLBPlayerStatsResponse,
        playerRef: PlayerReference
    ) -> PlayerMonthlySplits {
        let unique = deduplicatedSplits(from: response)
        func bat(_ code: String) -> BattingStats? {
            aggregateBattingStats(unique.filter { $0.split?.code == code }.map { battingStats(from: $0.stat) })
        }
        return PlayerMonthlySplits(
            march: bat("m3"), april: bat("m4"), may: bat("m5"), june: bat("m6"),
            july: bat("m7"), august: bat("m8"), september: bat("m9"), october: bat("m10")
        )
    }

    /// Builds pitcher monthly splits by deduplicating and aggregating across game types.
    static func pitcherMonthlySplits(
        from response: MLBPlayerStatsResponse,
        playerRef: PlayerReference
    ) -> PitcherMonthlySplits {
        let unique = deduplicatedSplits(from: response)
        func pit(_ code: String) -> PitchingStats? {
            aggregatePitchingStats(unique.filter { $0.split?.code == code }.map { pitchingStats(from: $0.stat) })
        }
        return PitcherMonthlySplits(
            march: pit("m3"), april: pit("m4"), may: pit("m5"), june: pit("m6"),
            july: pit("m7"), august: pit("m8"), september: pit("m9"), october: pit("m10")
        )
    }

    /// Builds batter runners-on-base splits by deduplicating and aggregating across game types.
    static func playerRunnersOnSplits(
        from response: MLBPlayerStatsResponse,
        playerRef: PlayerReference
    ) -> PlayerRunnersOnSplits {
        let unique = deduplicatedSplits(from: response)
        func bat(_ code: String) -> BattingStats? {
            aggregateBattingStats(unique.filter { $0.split?.code == code }.map { battingStats(from: $0.stat) })
        }
        return PlayerRunnersOnSplits(
            basesEmpty: bat("ne"),
            runnersOn: bat("ro"),
            risp: bat("ri"),
            rispTwoOut: bat("sf")
        )
    }

    /// Builds pitcher runners-on-base splits by deduplicating and aggregating across game types.
    static func pitcherRunnersOnSplits(
        from response: MLBPlayerStatsResponse,
        playerRef: PlayerReference
    ) -> PitcherRunnersOnSplits {
        let unique = deduplicatedSplits(from: response)
        func pit(_ code: String) -> PitchingStats? {
            aggregatePitchingStats(unique.filter { $0.split?.code == code }.map { pitchingStats(from: $0.stat) })
        }
        return PitcherRunnersOnSplits(
            basesEmpty: pit("ne"),
            runnersOn: pit("ro"),
            risp: pit("ri"),
            rispTwoOut: pit("sf")
        )
    }

    /// Builds batter leverage splits by deduplicating and aggregating across game types.
    static func playerLeverageSplits(
        from response: MLBPlayerStatsResponse,
        playerRef: PlayerReference
    ) -> PlayerLeverageSplits {
        let unique = deduplicatedSplits(from: response)
        func bat(_ code: String) -> BattingStats? {
            aggregateBattingStats(unique.filter { $0.split?.code == code }.map { battingStats(from: $0.stat) })
        }
        return PlayerLeverageSplits(low: bat("le"), medium: bat("lm"), high: bat("lh"))
    }

    /// Builds pitcher leverage splits by deduplicating and aggregating across game types.
    static func pitcherLeverageSplits(
        from response: MLBPlayerStatsResponse,
        playerRef: PlayerReference
    ) -> PitcherLeverageSplits {
        let unique = deduplicatedSplits(from: response)
        func pit(_ code: String) -> PitchingStats? {
            aggregatePitchingStats(unique.filter { $0.split?.code == code }.map { pitchingStats(from: $0.stat) })
        }
        return PitcherLeverageSplits(low: pit("le"), medium: pit("lm"), high: pit("lh"))
    }

    /// Removes duplicate splits produced by comma-separated gameType queries.
    ///
    /// The API returns identical `(splitCode, gameType)` pairs repeated once per
    /// requested game type. This keeps only the first occurrence of each pair.
    private static func deduplicatedSplits(
        from response: MLBPlayerStatsResponse
    ) -> [MLBStatSplit] {
        let allSplits = response.stats.flatMap(\.splits)
        var seen = Set<String>()
        return allSplits.filter { split in
            let code = split.split?.code ?? ""
            let gt = split.gameType ?? ""
            let key = "\(code)-\(gt)"
            guard !seen.contains(key) else { return false }
            seen.insert(key)
            return true
        }
    }

    /// Sums batting counting stats across game types and computes rate stats
    /// from the aggregated totals.
    private static func aggregateBattingStats(
        _ stats: [BattingStats]
    ) -> BattingStats? {
        guard !stats.isEmpty else { return nil }
        if stats.count == 1 { return stats[0] }

        var gp = 0, pa = 0, ab = 0, r = 0, h = 0
        var d = 0, t = 0, hr = 0, rbi = 0, sb = 0, cs = 0
        var bb = 0, ibb = 0, so = 0, hbp = 0, sf = 0, sac = 0
        var gidp = 0, tb = 0, lob = 0

        for s in stats {
            gp += s.gamesPlayed ?? 0
            pa += s.plateAppearances ?? 0
            ab += s.atBats ?? 0
            r += s.runs ?? 0
            h += s.hits ?? 0
            d += s.doubles ?? 0
            t += s.triples ?? 0
            hr += s.homeRuns ?? 0
            rbi += s.rbi ?? 0
            sb += s.stolenBases ?? 0
            cs += s.caughtStealing ?? 0
            bb += s.baseOnBalls ?? 0
            ibb += s.intentionalWalks ?? 0
            so += s.strikeOuts ?? 0
            hbp += s.hitByPitch ?? 0
            sf += s.sacFlies ?? 0
            sac += s.sacBunts ?? 0
            gidp += s.groundIntoDoublePlay ?? 0
            tb += s.totalBases ?? 0
            lob += s.leftOnBase ?? 0
        }

        let avg: Double? = ab > 0 ? Double(h) / Double(ab) : nil
        let obpDenom = ab + bb + hbp + sf
        let obp: Double? = obpDenom > 0 ? Double(h + bb + hbp) / Double(obpDenom) : nil
        let slg: Double? = ab > 0 ? Double(tb) / Double(ab) : nil
        let ops: Double? = if let obp, let slg { obp + slg } else { nil }
        // BABIP = (H - HR) / (AB - SO - HR + SF)
        let babipDenom = ab - so - hr + sf
        let babip: Double? = babipDenom > 0 ? Double(h - hr) / Double(babipDenom) : nil

        return BattingStats(
            gamesPlayed: gp, plateAppearances: pa, atBats: ab,
            runs: r, hits: h, doubles: d, triples: t, homeRuns: hr,
            rbi: rbi, stolenBases: sb, caughtStealing: cs,
            baseOnBalls: bb, intentionalWalks: ibb, strikeOuts: so,
            hitByPitch: hbp, sacFlies: sf, sacBunts: sac,
            groundIntoDoublePlay: gidp, totalBases: tb, leftOnBase: lob,
            avg: avg, obp: obp, slg: slg, ops: ops, babip: babip
        )
    }

    /// Sums pitching counting stats across game types and computes rate stats
    /// from the aggregated totals.
    private static func aggregatePitchingStats(
        _ stats: [PitchingStats]
    ) -> PitchingStats? {
        guard !stats.isEmpty else { return nil }
        if stats.count == 1 { return stats[0] }

        var gp = 0, gs = 0, w = 0, l = 0, sv = 0, svo = 0
        var hld = 0, bs = 0, cg = 0, sho = 0
        var h = 0, d = 0, t = 0, r = 0, er = 0, hr = 0
        var ab = 0, bb = 0, ibb = 0, so = 0, hbp = 0, sf = 0
        var wp = 0, bk = 0, bf = 0, np = 0
        var totalIP = 0.0

        for s in stats {
            gp += s.gamesPlayed ?? 0
            gs += s.gamesStarted ?? 0
            w += s.wins ?? 0
            l += s.losses ?? 0
            sv += s.saves ?? 0
            svo += s.saveOpportunities ?? 0
            hld += s.holds ?? 0
            bs += s.blownSaves ?? 0
            cg += s.completeGames ?? 0
            sho += s.shutouts ?? 0
            h += s.hits ?? 0
            d += s.doubles ?? 0
            t += s.triples ?? 0
            r += s.runs ?? 0
            er += s.earnedRuns ?? 0
            hr += s.homeRuns ?? 0
            ab += s.atBats ?? 0
            bb += s.baseOnBalls ?? 0
            ibb += s.intentionalWalks ?? 0
            so += s.strikeOuts ?? 0
            hbp += s.hitByPitch ?? 0
            sf += s.sacFlies ?? 0
            wp += s.wildPitches ?? 0
            bk += s.balks ?? 0
            bf += s.battersFaced ?? 0
            np += s.numberOfPitches ?? 0
            totalIP += s.inningsPitched ?? 0
        }

        let era: Double? = totalIP > 0 ? (Double(er) / totalIP) * 9.0 : nil
        let whip: Double? = totalIP > 0 ? Double(bb + h) / totalIP : nil
        let avg: Double? = bf > 0 ? Double(h) / Double(bf - bb - hbp) : nil
        let obpDenom = bf
        let obp: Double? = obpDenom > 0 ? Double(h + bb + hbp) / Double(obpDenom) : nil
        // For pitcher platoon, SLG and OPS require total bases which we don't
        // have as a counting stat on pitching splits. Use BF-weighted average
        // of per-split OPS values as a fallback.
        var weightedOPS = 0.0
        var opsBF = 0
        for s in stats {
            let sBF = s.battersFaced ?? 0
            guard sBF > 0, let sOPS = s.ops else { continue }
            weightedOPS += sOPS * Double(sBF)
            opsBF += sBF
        }
        let ops: Double? = opsBF > 0 ? weightedOPS / Double(opsBF) : nil
        // Approximate SLG from OPS - OBP
        let slg: Double? = if let ops, let obp { ops - obp } else { nil }

        return PitchingStats(
            gamesPlayed: gp, gamesStarted: gs,
            wins: w, losses: l, saves: sv,
            saveOpportunities: svo, holds: hld,
            blownSaves: bs, completeGames: cg, shutouts: sho,
            hits: h, doubles: d, triples: t, runs: r, earnedRuns: er, homeRuns: hr,
            atBats: ab, baseOnBalls: bb, intentionalWalks: ibb, strikeOuts: so,
            hitByPitch: hbp, sacFlies: sf, wildPitches: wp, balks: bk,
            battersFaced: bf,
            numberOfPitches: np > 0 ? np : nil,
            era: era, whip: whip, avg: avg,
            obp: obp, slg: slg, ops: ops,
            inningsPitched: totalIP
        )
    }

    private static func pitchingStats(from raw: MLBStatPayload) -> PitchingStats {
        PitchingStats(
            gamesPlayed: raw.gamesPlayed, gamesStarted: raw.gamesStarted,
            wins: raw.wins, losses: raw.losses, saves: raw.saves,
            saveOpportunities: raw.saveOpportunities, holds: raw.holds,
            blownSaves: raw.blownSaves, completeGames: raw.completeGames,
            shutouts: raw.shutouts, hits: raw.hits, doubles: raw.doubles,
            triples: raw.triples, runs: raw.runs,
            earnedRuns: raw.earnedRuns, homeRuns: raw.homeRunsAllowed ?? raw.homeRuns,
            atBats: raw.atBats, baseOnBalls: raw.baseOnBalls,
            intentionalWalks: raw.intentionalWalks,
            strikeOuts: raw.strikeOuts, hitByPitch: raw.hitByPitch,
            sacFlies: raw.sacFlies, wildPitches: raw.wildPitches, balks: raw.balks,
            battersFaced: raw.battersFaced,
            numberOfPitches: raw.numberOfPitches,
            era: raw.era.flatMap(Double.init), whip: raw.whip.flatMap(Double.init),
            avg: raw.avg.flatMap(Double.init),
            obp: raw.obp.flatMap(Double.init),
            slg: raw.slg.flatMap(Double.init),
            ops: raw.ops.flatMap(Double.init),
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

    // MARK: - Sabermetrics

    static func playerSabermetrics(
        from response: MLBSabermetricResponse,
        playerRef: PlayerReference
    ) -> [PlayerSeasonStats] {
        response.stats.flatMap { statGroup -> [PlayerSeasonStats] in
            statGroup.splits.map { split in
                PlayerSeasonStats(
                    player: split.player.map(playerReference) ?? playerRef,
                    team: split.team.map(teamReference),
                    season: split.season ?? "",
                    group: .batting,
                    batting: nil,
                    pitching: nil,
                    fielding: nil,
                    sabermetrics: sabermetricStats(from: split.stat),
                    sport: nil,
                    league: nil
                )
            }
        }
    }

    private static func sabermetricStats(from raw: MLBSabermetricPayload) -> SabermetricStats {
        SabermetricStats(
            woba: raw.woba, wRaa: raw.wRaa, wRc: raw.wRc, wRcPlus: raw.wRcPlus,
            rar: raw.rar, war: raw.war, batting: raw.batting, fielding: raw.fielding,
            baseRunning: raw.baseRunning, positional: raw.positional,
            wLeague: raw.wLeague, replacement: raw.replacement,
            spd: raw.spd, ubr: raw.ubr, wGdp: raw.wGdp, wSb: raw.wSb
        )
    }

    // MARK: - Play-by-Play

    static func playByPlay(from response: MLBPlayByPlayResponse) -> PlayByPlay {
        PlayByPlay(
            allPlays: response.allPlays.map(play),
            scoringPlays: response.scoringPlays
        )
    }

    private static func play(from raw: MLBPlay) -> Play {
        Play(
            result: playResult(from: raw.result),
            about: playAbout(from: raw.about),
            count: count(from: raw.count),
            matchup: playMatchup(from: raw.matchup),
            runners: raw.runners?.map(runner),
            playEvents: raw.playEvents?.map(playEvent)
        )
    }

    private static func playResult(from raw: MLBPlayResult?) -> PlayResult {
        PlayResult(
            type: raw?.type, event: raw?.event, eventType: raw?.eventType,
            description: raw?.description, rbi: raw?.rbi,
            awayScore: raw?.awayScore, homeScore: raw?.homeScore
        )
    }

    private static func playAbout(from raw: MLBPlayAbout?) -> PlayAbout {
        PlayAbout(
            atBatIndex: raw?.atBatIndex ?? 0,
            halfInning: raw?.halfInning,
            inning: raw?.inning ?? 0,
            isComplete: raw?.isComplete ?? false,
            isScoringPlay: raw?.isScoringPlay ?? false,
            hasOut: raw?.hasOut ?? false
        )
    }

    private static func count(from raw: MLBCount?) -> Count {
        Count(balls: raw?.balls ?? 0, strikes: raw?.strikes ?? 0, outs: raw?.outs ?? 0)
    }

    private static func playMatchup(from raw: MLBPlayMatchup?) -> PlayMatchup {
        PlayMatchup(
            batter: raw?.batter.map(playerReference) ?? PlayerReference(id: 0, fullName: ""),
            batSide: handSide(from: raw?.batSide?.code),
            pitcher: raw?.pitcher.map(playerReference) ?? PlayerReference(id: 0, fullName: ""),
            pitchHand: handSide(from: raw?.pitchHand?.code)
        )
    }

    private static func runner(from raw: MLBRunner) -> Runner {
        Runner(
            movement: raw.movement.map { m in
                RunnerMovement(
                    originBase: m.originBase, start: m.start, end: m.end,
                    outBase: m.outBase, isOut: m.isOut ?? false
                )
            },
            details: raw.details.map { d in
                RunnerDetails(event: d.event, runner: d.runner.map(playerReference))
            }
        )
    }

    private static func playEvent(from raw: MLBPlayEvent) -> PlayEvent {
        PlayEvent(
            details: raw.details.map { d in
                PlayEventDetails(
                    call: d.call.map { CodeDescription(code: $0.code, description: $0.description) },
                    description: d.description
                )
            },
            count: raw.count.map(count),
            pitchData: raw.pitchData.map { p in
                PitchData(
                    startSpeed: p.startSpeed, endSpeed: p.endSpeed, zone: p.zone,
                    strikeZoneTop: p.strikeZoneTop, strikeZoneBottom: p.strikeZoneBottom
                )
            },
            pitchNumber: raw.pitchNumber,
            isPitch: raw.isPitch,
            type: raw.type
        )
    }

    // MARK: - Game Log

    static func gameLogEntries(from response: MLBGameLogResponse) -> [GameLogEntry] {
        response.stats.flatMap { statGroup -> [GameLogEntry] in
            let groupName = statGroup.group?.displayName ?? ""
            let group = StatGroup(apiValue: groupName)
            return statGroup.splits.compactMap { split in
                guard let dateString = split.date,
                      let date = parseDate(dateString),
                      let gamePk = split.game?.gamePk else { return nil }

                let player = split.player.map(playerReference)
                    ?? PlayerReference(id: 0, fullName: "")
                let team = split.team.map(teamReference)
                    ?? TeamReference(id: 0, name: "")
                let opponent = split.opponent.map(teamReference)
                    ?? TeamReference(id: 0, name: "")

                return GameLogEntry(
                    player: player,
                    season: split.season ?? "",
                    date: date,
                    gamePk: gamePk,
                    team: team,
                    opponent: opponent,
                    isHome: split.isHome ?? false,
                    isWin: split.isWin ?? false,
                    gameType: GameType(rawValue: split.gameType ?? "") ?? .unknown,
                    group: group,
                    batting: group == .batting ? battingStats(from: split.stat) : nil,
                    pitching: group == .pitching ? pitchingStats(from: split.stat) : nil,
                    fielding: group == .fielding ? fieldingStats(from: split.stat) : nil
                )
            }
        }
    }

    // MARK: - Transactions

    static func transactions(from response: MLBTransactionsResponse) -> [Transaction] {
        response.transactions.map { raw in
            Transaction(
                id: raw.id,
                person: raw.person.map(playerReference),
                fromTeam: raw.fromTeam.map(teamReference),
                toTeam: raw.toTeam.map(teamReference),
                date: raw.date.flatMap(parseDateTime),
                effectiveDate: raw.effectiveDate.flatMap(parseDateTime),
                typeCode: raw.typeCode,
                typeDesc: raw.typeDesc,
                description: raw.description
            )
        }
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
        guard let raw else { return .unknown }
        // Try the abbreviation first so utility codes ("O"/"I") map to the
        // enum's "OF"/"IF" cases. Fall back to the numeric code for standard
        // positions ("1".."10").
        if let abbr = raw.abbreviation, let pos = Position(rawValue: abbr) {
            return pos
        }
        return Position(rawValue: raw.code) ?? .unknown
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

    private static func gameStatus(
        from detailedState: String?,
        abstractGameState: String?
    ) -> GameStatus {
        // Primary: exact match on detailedState raw value.
        if let state = detailedState, let status = GameStatus(rawValue: state) {
            return status
        }
        // Secondary: broad fallback via abstractGameState when detailedState is
        // unrecognized (e.g. "Completed Early (Rain)") or absent.
        switch abstractGameState {
        case "Final": return .final
        case "Live": return .inProgress
        default: return .scheduled
        }
    }

    private static func emptyBattingStats() -> BattingStats {
        .empty
    }

    private static func emptyPitchingStats() -> PitchingStats {
        .empty
    }

    private static func emptyFieldingStats() -> FieldingStats {
        .empty
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

    // MARK: - Venues

    static func venues(from response: MLBVenuesResponse) -> [Venue] {
        response.venues.map { venue(from: $0) }
    }

    static func venue(from raw: MLBVenueDetail) -> Venue {
        let dims: FieldDimensions? = raw.fieldInfo.map { fi in
            FieldDimensions(
                leftLine: fi.leftLine, left: fi.left, leftCenter: fi.leftCenter,
                center: fi.center, rightCenter: fi.rightCenter,
                right: fi.right, rightLine: fi.rightLine
            )
        }
        let coords: Coordinates? = raw.location?.defaultCoordinates.map { c in
            Coordinates(latitude: c.latitude, longitude: c.longitude)
        }
        return Venue(
            id: raw.id,
            name: raw.name,
            city: raw.location?.city,
            state: raw.location?.state,
            stateAbbrev: raw.location?.stateAbbrev,
            country: raw.location?.country,
            capacity: raw.fieldInfo?.capacity,
            surface: raw.fieldInfo?.turfType,
            roofType: raw.fieldInfo?.roofType,
            active: raw.active,
            dimensions: dims,
            coordinates: coords
        )
    }

    // MARK: - Draft

    static func draftPicks(from response: MLBDraftResponse, year: Int) -> [DraftPick] {
        response.drafts.rounds.flatMap { round in
            round.picks.compactMap { raw -> DraftPick? in
                guard let pickNumber = raw.pickNumber else { return nil }
                let school: School? = raw.school.map { s in
                    School(name: s.name, schoolClass: s.schoolClass,
                           city: s.city, state: s.state, country: s.country)
                }
                return DraftPick(
                    id: pickNumber,
                    year: year,
                    round: raw.pickRound ?? round.round,
                    roundPickNumber: raw.roundPickNumber,
                    team: raw.team.map(teamReference),
                    person: raw.person.map(playerReference),
                    school: school,
                    signingBonus: raw.signingBonus,
                    blurb: raw.blurb,
                    scoutingReport: raw.scoutingReport,
                    isDrafted: raw.isDrafted ?? false,
                    isPass: raw.isPass ?? false
                )
            }
        }
    }

    // MARK: - Awards

    static func awards(from response: MLBAwardsListResponse) -> [Award] {
        response.awards.map { raw in
            Award(
                id: raw.id,
                name: raw.name ?? raw.id,
                description: raw.description,
                active: raw.active ?? true,
                leagueId: raw.league?.id,
                sportId: raw.sport?.id
            )
        }
    }

    static func awardRecipients(from response: MLBAwardRecipientsResponse) -> [AwardRecipient] {
        response.awards.map { raw in
            let player: PlayerReference? = raw.player.map { p in
                PlayerReference(id: p.id, fullName: p.nameFirstLast ?? "")
            }
            return AwardRecipient(
                awardId: raw.id,
                awardName: raw.name ?? raw.id,
                season: raw.season,
                date: raw.date.flatMap { parseDate($0) },
                player: player,
                teamId: raw.team?.id
            )
        }
    }

    // MARK: - Game Highlights

    /// Converts an ``MLBGameContentResponse`` into a ``GameHighlights`` value.
    static func gameHighlights(from response: MLBGameContentResponse) -> GameHighlights {
        let gameCenterItems = response.highlights?.gameCenter?.items ?? []
        let scoreboardItems = response.highlights?.scoreboard?.items ?? []
        return GameHighlights(
            highlights: gameCenterItems.compactMap(highlight(from:)),
            scoreboardHighlights: scoreboardItems.compactMap(highlight(from:))
        )
    }

    private static func highlight(from raw: MLBHighlightItem) -> Highlight? {
        guard let id = raw.id, !id.isEmpty else { return nil }
        return Highlight(
            id: id,
            date: raw.date.flatMap { parseDateTime($0) },
            title: raw.title,
            headline: raw.headline,
            blurb: raw.blurb,
            duration: raw.duration,
            playbacks: (raw.playbacks ?? []).compactMap(videoPlayback(from:)),
            image: raw.image.map(highlightImage(from:))
        )
    }

    private static func videoPlayback(from raw: MLBVideoPlayback) -> VideoPlayback? {
        guard let name = raw.name, !name.isEmpty else { return nil }
        return VideoPlayback(
            name: name,
            url: raw.url.flatMap { URL(string: $0) },
            width: raw.width.flatMap { Int($0) },
            height: raw.height.flatMap { Int($0) }
        )
    }

    private static func highlightImage(from raw: MLBHighlightImage) -> HighlightImage {
        HighlightImage(
            altText: raw.altText,
            cuts: (raw.cuts ?? []).compactMap(imageCut(from:))
        )
    }

    private static func imageCut(from raw: MLBImageCut) -> ImageCut? {
        guard let w = raw.width, let h = raw.height else { return nil }
        return ImageCut(
            aspectRatio: raw.aspectRatio,
            width: w,
            height: h,
            src: raw.src.flatMap { URL(string: $0) }
        )
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

// MARK: - Live Game Feed converter

extension MLBResponseConverters {
    static func liveGameFeed(from response: MLBLiveGameFeedResponse) -> LiveGameFeed {
        let liveData = liveData(from: response.liveData)
        // Lift per-team current scores from the linescore into teams so callers
        // can read both sides of the scoreboard off gameData.teams directly.
        let gameData = liveGameData(
            from: response.gameData,
            awayScore: liveData.linescore.teams.away.runs,
            homeScore: liveData.linescore.teams.home.runs
        )
        return LiveGameFeed(
            gamePk: response.gamePk,
            meta: liveFeedMeta(from: response.metaData),
            gameData: gameData,
            liveData: liveData
        )
    }

    private static func liveFeedMeta(from raw: MLBLiveFeedMeta) -> LiveFeedMeta {
        LiveFeedMeta(
            wait: raw.wait ?? 0,
            timeStamp: raw.timeStamp ?? "",
            gameEvents: raw.gameEvents ?? [],
            logicalEvents: raw.logicalEvents ?? []
        )
    }

    private static func liveGameData(
        from raw: MLBLiveGameData,
        awayScore: Int?,
        homeScore: Int?
    ) -> LiveGameData {
        let players: [Int: LivePlayer] = Dictionary(uniqueKeysWithValues:
            (raw.players ?? [:]).compactMap { key, value -> (Int, LivePlayer)? in
                let trimmed = key.hasPrefix("ID") ? String(key.dropFirst(2)) : key
                guard let id = Int(trimmed) else { return nil }
                return (id, livePlayer(from: value))
            })
        return LiveGameData(
            game: liveGameInfo(from: raw.game),
            datetime: liveGameDatetime(from: raw.datetime),
            status: liveGameStatus(from: raw.status),
            teams: LiveGameTeams(
                away: liveGameTeam(from: raw.teams.away, score: awayScore),
                home: liveGameTeam(from: raw.teams.home, score: homeScore)
            ),
            players: players,
            venue: venueReference(from: raw.venue),
            weather: raw.weather.map(gameWeather),
            gameInfo: raw.gameInfo.map(gameInfo),
            flags: gameFlags(from: raw.flags),
            probablePitchers: probablePitchers(from: raw.probablePitchers)
        )
    }

    private static func liveGameInfo(from raw: MLBLiveGameInfo) -> LiveGameInfo {
        LiveGameInfo(
            pk: raw.pk,
            type: GameType(rawValue: raw.type ?? "") ?? .unknown,
            doubleHeader: raw.doubleHeader ?? "N",
            season: raw.season ?? "",
            seasonDisplay: raw.seasonDisplay ?? raw.season ?? ""
        )
    }

    private static func liveGameDatetime(from raw: MLBLiveGameDatetime) -> LiveGameDatetime {
        LiveGameDatetime(
            dateTime: raw.dateTime.flatMap(parseDateTime),
            originalDate: raw.originalDate.flatMap(parseDate),
            officialDate: raw.officialDate.flatMap(parseDate),
            dayNight: DayNight(rawValue: raw.dayNight ?? "") ?? .unknown,
            time: raw.time ?? "",
            ampm: raw.ampm ?? ""
        )
    }

    private static func liveGameStatus(from raw: MLBLiveGameStatus) -> LiveGameStatus {
        LiveGameStatus(
            abstractGameState: AbstractGameState(rawValue: raw.abstractGameState ?? "") ?? .unknown,
            codedGameState: raw.codedGameState ?? "",
            detailedState: raw.detailedState ?? "",
            statusCode: raw.statusCode ?? "",
            startTimeTBD: raw.startTimeTBD ?? false
        )
    }

    private static func liveGameTeam(from raw: MLBLiveTeam, score: Int?) -> LiveGameTeam {
        LiveGameTeam(
            team: TeamReference(id: raw.id, name: raw.name ?? raw.teamName ?? ""),
            leagueRecord: liveLeagueRecord(from: raw.record?.leagueRecord),
            score: score
        )
    }

    private static func liveLeagueRecord(from raw: MLBLiveLeagueRecord?) -> LeagueRecord {
        LeagueRecord(
            wins: raw?.wins ?? 0,
            losses: raw?.losses ?? 0,
            ties: raw?.ties ?? 0,
            pct: raw?.pct ?? ""
        )
    }

    private static func livePlayer(from raw: MLBLivePlayer) -> LivePlayer {
        LivePlayer(
            id: raw.id,
            fullName: raw.fullName ?? "",
            primaryNumber: raw.primaryNumber,
            currentAge: raw.currentAge,
            primaryPosition: Position(rawValue: raw.primaryPosition?.code ?? "") ?? .unknown,
            batSide: HandSide(rawValue: raw.batSide?.code ?? "") ?? .unknown,
            pitchHand: HandSide(rawValue: raw.pitchHand?.code ?? "") ?? .unknown,
            active: raw.active
        )
    }

    private static func gameWeather(from raw: MLBGameWeather) -> GameWeather {
        GameWeather(
            condition: raw.condition ?? "",
            temp: raw.temp ?? "",
            wind: raw.wind ?? ""
        )
    }

    private static func gameInfo(from raw: MLBGameInfo) -> GameInfo {
        GameInfo(
            attendance: raw.attendance,
            firstPitch: raw.firstPitch,
            gameDurationMinutes: raw.gameDurationMinutes
        )
    }

    private static func gameFlags(from raw: MLBGameFlags?) -> GameFlags {
        GameFlags(
            noHitter: raw?.noHitter ?? false,
            perfectGame: raw?.perfectGame ?? false,
            awayTeamNoHitter: raw?.awayTeamNoHitter ?? false,
            awayTeamPerfectGame: raw?.awayTeamPerfectGame ?? false,
            homeTeamNoHitter: raw?.homeTeamNoHitter ?? false,
            homeTeamPerfectGame: raw?.homeTeamPerfectGame ?? false
        )
    }

    private static func probablePitchers(from raw: MLBProbablePitchers?) -> ProbablePitchers {
        ProbablePitchers(
            away: raw?.away.map(playerReference),
            home: raw?.home.map(playerReference)
        )
    }

    private static func liveData(from raw: MLBLiveData) -> LiveData {
        LiveData(
            plays: livePlays(from: raw.plays),
            linescore: raw.linescore,
            boxscore: boxscore(from: raw.boxscore),
            decisions: raw.decisions.map(gameDecisions)
        )
    }

    private static func livePlays(from raw: MLBLivePlays) -> LivePlays {
        LivePlays(
            allPlays: raw.allPlays.map(play),
            currentPlay: raw.currentPlay.map(play),
            scoringPlays: raw.scoringPlays ?? [],
            playsByInning: (raw.playsByInning ?? []).enumerated().map { index, item in
                InningPlays(
                    inning: index + 1,
                    startIndex: item.startIndex,
                    endIndex: item.endIndex,
                    top: item.top ?? [],
                    bottom: item.bottom ?? []
                )
            }
        )
    }

    private static func gameDecisions(from raw: MLBGameDecisions) -> GameDecisions {
        GameDecisions(
            winner: raw.winner.map(playerReference),
            loser: raw.loser.map(playerReference),
            save: raw.save.map(playerReference)
        )
    }

    // MARK: - Win Probability

    static func winProbability(from response: [MLBWinProbabilityPlay]) -> [PlayWinProbability] {
        response.map { raw in
            PlayWinProbability(
                atBatIndex: raw.atBatIndex ?? raw.about?.atBatIndex ?? 0,
                homeTeamWinProbability: raw.homeTeamWinProbability ?? 0,
                awayTeamWinProbability: raw.awayTeamWinProbability ?? 0,
                homeTeamWinProbabilityAdded: raw.homeTeamWinProbabilityAdded ?? 0,
                result: playResult(from: raw.result),
                about: playAbout(from: raw.about),
                matchup: playMatchup(from: raw.matchup)
            )
        }
    }

    // MARK: - Context Metrics

    static func contextMetrics(from response: MLBContextMetricsResponse) -> GameContextMetrics {
        GameContextMetrics(
            gamePk: response.game.gamePk,
            homeWinProbability: response.homeWinProbability ?? 0,
            awayWinProbability: response.awayWinProbability ?? 0
        )
    }
}
