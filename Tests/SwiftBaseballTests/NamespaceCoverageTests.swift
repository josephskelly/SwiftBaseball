import Foundation
@testable import SwiftBaseball
import Testing

/// Coverage tests for the `SwiftBaseball` enum namespace.
///
/// Every public static func on ``SwiftBaseball`` is a 1–3 line trampoline that
/// forwards to a `QueryBuilder<T>` factory or `Query` struct. Existing test
/// files exercise the underlying builders directly, so these trampolines never
/// run — they show up at ~35% line coverage.
///
/// This suite invokes every namespace method without `.fetch()`, which is
/// enough to mark the trampoline lines covered. The Swift type system already
/// enforces that each method returns a value of the documented generic type;
/// the only remaining runtime fact is "the trampoline doesn't crash and
/// returns a non-nil value." That is what these tests verify.
@Suite("SwiftBaseball Namespace Coverage")
struct NamespaceCoverageTests {
    // MARK: - Players

    @Test("Player namespace funcs build queries")
    func playerNamespaceFuncs() {
        _ = SwiftBaseball.players(.search("Ohtani"))
        _ = SwiftBaseball.player(id: 592_450)
        _ = SwiftBaseball.sportPlayers(season: 2024)
        _ = SwiftBaseball.sportPlayers(sport: .tripleA, season: 2024)
    }

    // MARK: - Teams

    @Test("Team namespace funcs build queries")
    func teamNamespaceFuncs() {
        _ = SwiftBaseball.teams(.all(season: 2024))
        _ = SwiftBaseball.team(id: 147)
        _ = SwiftBaseball.teamHistory(teamIds: [147])
        _ = SwiftBaseball.teamCoaches(teamId: 147)
        _ = SwiftBaseball.teamPersonnel(teamId: 147)
        _ = SwiftBaseball.teamAlumni(teamId: 147, season: 2024)
        _ = SwiftBaseball.attendance(teamId: 147, season: 2024)
        _ = SwiftBaseball.affiliates(teamId: 147, season: 2024)
    }

    // MARK: - Roster, Schedule, Postseason

    @Test("Roster, schedule, and postseason namespace funcs build queries")
    func rosterScheduleNamespaceFuncs() {
        _ = SwiftBaseball.roster(teamId: 147, season: 2024)
        _ = SwiftBaseball.roster(teamId: 147, season: 2024, rosterType: .fortyMan, date: "2024-07-04")
        _ = SwiftBaseball.schedule(.date("2024-07-04"))
        _ = SwiftBaseball.schedule(.season(2024), hydrate: [.probablePitcher])
        _ = SwiftBaseball.postseasonSchedule(season: 2024)
        _ = SwiftBaseball.postseasonSeries(season: 2024)
    }

    // MARK: - Game data

    @Test("Game-data namespace funcs build queries")
    func gameDataNamespaceFuncs() {
        _ = SwiftBaseball.boxscore(gamePk: 745_612)
        _ = SwiftBaseball.playByPlay(gamePk: 745_612)
        _ = SwiftBaseball.linescore(gamePk: 745_612)
        _ = SwiftBaseball.liveGameFeed(gamePk: 745_612)
        _ = SwiftBaseball.winProbability(gamePk: 745_612)
        _ = SwiftBaseball.contextMetrics(gamePk: 745_612)
        _ = SwiftBaseball.gameHighlights(gamePk: 745_612)
    }

    // MARK: - Game log, transactions

    @Test("Game-log and transactions namespace funcs build queries")
    func gameLogTransactionsNamespaceFuncs() {
        _ = SwiftBaseball.gameLog(playerId: 660_271)
        _ = SwiftBaseball.transactions()
    }

    // MARK: - Umpires, Official Scorers

    @Test("Umpires and official-scorers namespace funcs build queries")
    func umpiresScorersNamespaceFuncs() {
        let date = Date(timeIntervalSince1970: 1_720_051_200)
        _ = SwiftBaseball.umpires(date: "2024-07-04")
        _ = SwiftBaseball.umpires(date: date)
        _ = SwiftBaseball.officialScorers(date: "2024-07-04")
        _ = SwiftBaseball.officialScorers(date: date)
    }

    // MARK: - Player stats

    @Test("Player-stats namespace funcs build queries")
    func playerStatsNamespaceFuncs() {
        _ = SwiftBaseball.playerStats(id: 660_271)
        _ = SwiftBaseball.playerCareerStats(id: 660_271)
        _ = SwiftBaseball.playerYearByYear(id: 660_271)
        _ = SwiftBaseball.playerProjectedStats(id: 660_271)
        _ = SwiftBaseball.playerSabermetrics(id: 660_271)
        _ = SwiftBaseball.teamSabermetrics(teamId: 147)
        _ = SwiftBaseball.teamStats(teamId: 147, group: .batting)
    }

    // MARK: - Splits

    @Test("Split-stats namespace funcs build queries")
    func splitsNamespaceFuncs() {
        _ = SwiftBaseball.playerHomeAwaySplits(id: 660_271)
        _ = SwiftBaseball.pitcherHomeAwaySplits(id: 543_037)
        _ = SwiftBaseball.playerDayNightSplits(id: 660_271)
        _ = SwiftBaseball.pitcherDayNightSplits(id: 543_037)
        _ = SwiftBaseball.playerMonthlySplits(id: 660_271)
        _ = SwiftBaseball.pitcherMonthlySplits(id: 543_037)
        _ = SwiftBaseball.playerRunnersOnSplits(id: 660_271)
        _ = SwiftBaseball.pitcherRunnersOnSplits(id: 543_037)
        _ = SwiftBaseball.playerLeverageSplits(id: 660_271)
        _ = SwiftBaseball.pitcherLeverageSplits(id: 543_037)
        _ = SwiftBaseball.playerPlatoonStats(id: 660_271)
        _ = SwiftBaseball.pitcherPlatoonStats(id: 660_271)
        _ = SwiftBaseball.playerCareerPlatoonStats(id: 660_271)
        _ = SwiftBaseball.pitcherCareerPlatoonStats(id: 543_037)
    }

    // MARK: - Batch stats

    @Test("Batch-stats namespace func builds query")
    func batchStatsNamespaceFunc() {
        _ = SwiftBaseball.batchStats([660_271, 592_450], group: .batting)
    }

    // MARK: - Statcast (player)

    @Test("Statcast player namespace funcs build queries")
    func statcastPlayerNamespaceFuncs() {
        _ = SwiftBaseball.statcastBatting(playerId: 660_271)
        _ = SwiftBaseball.statcastPitching(playerId: 543_037)
        _ = SwiftBaseball.statcastBatchBatting(playerIds: [660_271, 592_450])
        _ = SwiftBaseball.statcastBatchPitching(playerIds: [543_037, 808_967])
        _ = SwiftBaseball.statcastCareerSplits(playerId: 660_271)
        _ = SwiftBaseball.statcastBatchCareerSplits([660_271, 592_450])
    }

    // MARK: - Raw Statcast

    @Test("Raw-Statcast namespace funcs build queries")
    func statcastRawNamespaceFuncs() {
        let start = Date(timeIntervalSince1970: 1_716_249_600)
        let end = Date(timeIntervalSince1970: 1_716_336_000)
        _ = SwiftBaseball.statcastRaw(start: "2024-05-21", end: "2024-05-21")
        _ = SwiftBaseball.statcastRaw(start: start, end: end)
        _ = SwiftBaseball.statcastBatterRaw(playerId: 660_271)
        _ = SwiftBaseball.statcastPitcherRaw(playerId: 543_037)
        _ = SwiftBaseball.statcastGame(gamePk: 746_309)
    }

    // MARK: - Statcast leaderboards

    @Test("Statcast leaderboard namespace funcs build queries")
    func statcastLeaderboardNamespaceFuncs() {
        _ = SwiftBaseball.sprintSpeed()
        _ = SwiftBaseball.outsAboveAverage()
        _ = SwiftBaseball.catcherFraming()
        _ = SwiftBaseball.catcherPopTime()
        _ = SwiftBaseball.expectedStatsBatter()
        _ = SwiftBaseball.expectedStatsPitcher()
        _ = SwiftBaseball.percentileRanksBatter()
        _ = SwiftBaseball.percentileRanksPitcher()
        _ = SwiftBaseball.exitVeloBarrelsBatter()
        _ = SwiftBaseball.exitVeloBarrelsPitcher()
        _ = SwiftBaseball.pitchArsenal()
        _ = SwiftBaseball.pitchArsenalStats()
        _ = SwiftBaseball.pitchMovement()
        _ = SwiftBaseball.activeSpin()
        _ = SwiftBaseball.runningSplits()
        _ = SwiftBaseball.batTracking()
        _ = SwiftBaseball.outfieldCatchProbability()
        _ = SwiftBaseball.outfielderJumps()
        _ = SwiftBaseball.pitcherFieldingRunValue()
        _ = SwiftBaseball.baserunningRunValue()
        _ = SwiftBaseball.swingTake()
        _ = SwiftBaseball.pitchTilt()
    }

    // MARK: - Venues, Draft, Awards, Catalogs

    @Test("Venues, draft, awards, catalogs namespace funcs build queries")
    func venuesDraftAwardsCatalogsNamespaceFuncs() {
        _ = SwiftBaseball.venues()
        _ = SwiftBaseball.venue(id: 3313)
        _ = SwiftBaseball.draft(year: 2024)
        _ = SwiftBaseball.draftProspects(year: 2023)
        _ = SwiftBaseball.draftLatest(year: 2024)
        _ = SwiftBaseball.awardRecipients(awardId: "ALMVP")
        _ = SwiftBaseball.awards()
        _ = SwiftBaseball.sports()
        _ = SwiftBaseball.leagues()
        _ = SwiftBaseball.leagues(sportId: 1)
        _ = SwiftBaseball.divisions()
        _ = SwiftBaseball.divisions(sportId: 1)
    }

    // MARK: - Standings, Leaders, High-Low, Game Pace

    @Test("Standings, leaders, high-low, game-pace namespace funcs build queries")
    func standingsLeadersGamePaceNamespaceFuncs() {
        _ = SwiftBaseball.standings(.season(2024))
        _ = SwiftBaseball.leaders(.homeRuns)
        _ = SwiftBaseball.teamLeaders(teamId: 147, category: .homeRuns)
        _ = SwiftBaseball.highLowPlayer(group: .batting, sortStat: .homeRuns, season: 2024)
        _ = SwiftBaseball.highLowPlayer(group: .batting, sortStat: .homeRuns, season: 2024, direction: .low)
        _ = SwiftBaseball.highLowTeam(group: .batting, sortStat: .homeRuns, season: 2024)
        _ = SwiftBaseball.highLowTeam(group: .batting, sortStat: .homeRuns, season: 2024, direction: .low)
        _ = SwiftBaseball.gamePace(teamId: 147, season: 2024)
        _ = SwiftBaseball.leagueGamePace(season: 2024)
    }

    // MARK: - Meta catalogs

    @Test("Meta catalog namespace funcs build queries")
    func metaCatalogNamespaceFuncs() {
        _ = SwiftBaseball.meta
        _ = SwiftBaseball.Meta.statTypes()
        _ = SwiftBaseball.Meta.statGroups()
        _ = SwiftBaseball.Meta.statFields()
        _ = SwiftBaseball.Meta.leagueLeaderTypes()
        _ = SwiftBaseball.Meta.baseballStats()
        _ = SwiftBaseball.Meta.gameTypes()
        _ = SwiftBaseball.Meta.rosterTypes()
        _ = SwiftBaseball.Meta.standingsTypes()
        _ = SwiftBaseball.Meta.pitchTypes()
        _ = SwiftBaseball.Meta.pitchCodes()
        _ = SwiftBaseball.Meta.eventTypes()
        _ = SwiftBaseball.Meta.situationCodes()
        _ = SwiftBaseball.Meta.positions()
        _ = SwiftBaseball.Meta.reviewReasons()
        _ = SwiftBaseball.Meta.hitTrajectories()
        _ = SwiftBaseball.Meta.logicalEvents()
        _ = SwiftBaseball.Meta.jobTypes()
        _ = SwiftBaseball.Meta.languages()
    }
}
