# SwiftBaseball

> A Swift-native library for MLB statistics — like [pybaseball](https://github.com/jldbc/pybaseball), but Swift.

[![Swift CI](https://github.com/josephskelly/SwiftBaseball/actions/workflows/swift.yml/badge.svg?branch=main)](https://github.com/josephskelly/SwiftBaseball/actions/workflows/swift.yml)
[![codecov](https://codecov.io/gh/josephskelly/SwiftBaseball/branch/main/graph/badge.svg)](https://codecov.io/gh/josephskelly/SwiftBaseball)
[![Swift Versions](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fjosephskelly%2FSwiftBaseball%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/josephskelly/SwiftBaseball)
[![Platforms](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fjosephskelly%2FSwiftBaseball%2Fbadge%3Ftype%3Dplatforms)](https://swiftpackageindex.com/josephskelly/SwiftBaseball)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## Overview

SwiftBaseball provides typed, async access to MLB data through a fluent query API. Built on the [MLB Stats API](https://statsapi.mlb.com), it gives Swift developers first-class access to player info, game schedules, standings, statistics, and more — with zero third-party dependencies.

No DataFrames, no untyped dictionaries. Just Swift structs, async/await, and autocomplete.

## Features

- **Fluent query API** — chainable, type-safe, discoverable via autocomplete
- **async/await** — built on Swift concurrency from the ground up
- **Codable models** — every response is a typed Swift struct
- **Cross-platform** — macOS, iOS, iPadOS, tvOS, watchOS, visionOS, and Linux
- **Zero dependencies** — only Foundation and URLSession
- **Actor-based caching** — optional response caching with configurable TTL
- **Protocol-oriented** — mockable and testable by design

## API Preview

```swift
import SwiftBaseball

// Look up a player
let players = try await SwiftBaseball.players(.search("Ohtani")).fetch()

// Get season batting stats for a player
let stats = try await SwiftBaseball.playerStats(id: 592450).season(2024).fetch()

// Spring training stats
let spring = try await SwiftBaseball.playerStats(id: 592450)
    .season(2025)
    .gameType(.springTraining)
    .group(.batting)
    .fetch()

// Exhibition game stats (e.g. MLB vs minor-league affiliate)
let exhibition = try await SwiftBaseball.playerStats(id: 592450)
    .season(2025)
    .gameType(.exhibition)
    .group(.batting)
    .fetch()

// Minor league stats — Triple-A batting stats for a player
let aaaStats = try await SwiftBaseball.playerStats(id: 605141)
    .season(2024)
    .group(.batting)
    .sport(.tripleA)
    .fetch()

// Minor league schedule — all Triple-A games on a date
let aaaGames = try await SwiftBaseball
    .schedule(.date("2024-07-04"))
    .sport(.tripleA)
    .fetch()

// Fetch today's schedule
let games = try await SwiftBaseball
    .schedule(.date("2024-07-04"))
    .fetch()

// Get AL standings
let standings = try await SwiftBaseball
    .standings(.season(2024))
    .league(.american)
    .fetch()

// Batting leaders
let hrLeaders = try await SwiftBaseball
    .leaders(.homeRuns)
    .season(2024)
    .limit(10)
    .fetch()
hrLeaders.first?.leaders.first.map { print($0.player.fullName, $0.value) }  // "Shohei Ohtani 54"

// Pitching leaders — ERA, WHIP, strikeouts, wins, saves, innings pitched, K/9
let eraLeaders = try await SwiftBaseball.leaders(.earnedRunAverage).season(2024).limit(10).fetch()
let whipLeaders = try await SwiftBaseball.leaders(.whip).season(2024).limit(10).fetch()
let kLeaders   = try await SwiftBaseball.leaders(.strikeouts).season(2024).limit(10).fetch()
let winLeaders = try await SwiftBaseball.leaders(.wins).season(2024).limit(10).fetch()
let saveLeaders = try await SwiftBaseball.leaders(.saves).season(2024).limit(10).fetch()
let ipLeaders  = try await SwiftBaseball.leaders(.inningsPitched).season(2024).limit(10).fetch()
let k9Leaders  = try await SwiftBaseball.leaders(.strikeoutsPer9Inn).season(2024).limit(10).fetch()

// Player detail
let judge = try await SwiftBaseball.player(id: 592450).fetch()

// Batch stats for multiple players
let batch = try await SwiftBaseball
    .batchStats([660271, 592450], group: .batting)
    .season(2024)
    .fetch()

// Platoon splits — OPS vs LHP / vs RHP
let splits = try await SwiftBaseball
    .playerPlatoonStats(id: 660271)
    .season(2024)
    .fetch()

// Sabermetrics — wOBA, wRC+, WAR
let saber = try await SwiftBaseball
    .playerSabermetrics(id: 660271)
    .season(2024)
    .fetch()

// Team sabermetrics — wOBA, wRC+, WAR for every player on a team in one call
let teamSaber = try await SwiftBaseball
    .teamSabermetrics(teamId: 147)
    .season(2025)
    .fetch()
teamSaber.first.map { print($0.player.fullName, $0.sabermetrics?.woba ?? 0) }

// Team season stats — batting stats for every player on a team in one call
let teamBatting = try await SwiftBaseball
    .teamStats(teamId: 147, group: .batting)
    .season(2025)
    .gameType("R")
    .fetch()

// Pitcher platoon splits — OPS against vs LHB / vs RHB
let pitcherSplits = try await SwiftBaseball
    .pitcherPlatoonStats(id: 660271)
    .season(2023)
    .fetch()

// Career platoon splits — pre-aggregated career totals vs LHP / vs RHP (no season filter needed)
let careerSplits = try await SwiftBaseball
    .playerCareerPlatoonStats(id: 660271)
    .fetch()
print(careerSplits.vsLeft?.ops)   // career OPS vs LHP
print(careerSplits.vsRight?.ops)  // career OPS vs RHP

// Career pitcher platoon splits — pre-aggregated career totals vs LHB / vs RHB
let careerPitcherSplits = try await SwiftBaseball
    .pitcherCareerPlatoonStats(id: 543037)
    .fetch()

// Game log — per-game stat lines
let log = try await SwiftBaseball
    .gameLog(playerId: 660271)
    .season(2024)
    .group(.batting)
    .fetch()

// Play-by-play with pitch data
let pbp = try await SwiftBaseball
    .playByPlay(gamePk: 745612)
    .fetch()

// Live game feed — composite real-time snapshot (v1.1 endpoint)
let feed = try await SwiftBaseball.liveGameFeed(gamePk: 745612).fetch()
print(feed.gameData.status.abstractGameState)          // .final / .live / .preview
print(feed.gameData.teams.away.team.name,
      feed.gameData.teams.away.score ?? 0,
      "@",
      feed.gameData.teams.home.team.name,
      feed.gameData.teams.home.score ?? 0)
// During a live game, poll using the server's recommended interval:
//   try await Task.sleep(for: .seconds(feed.meta.wait))

// Per-at-bat win probability (home-team convention)
let wp = try await SwiftBaseball.winProbability(gamePk: 745612).fetch()
let biggestSwing = wp.max { abs($0.homeTeamWinProbabilityAdded) < abs($1.homeTeamWinProbabilityAdded) }
print(biggestSwing?.result.event ?? "")                  // e.g. "Home Run"
print(biggestSwing?.homeTeamWinProbabilityAdded ?? 0)    // WPA in percentage points

// Current game context metrics snapshot (updates live)
let ctx = try await SwiftBaseball.contextMetrics(gamePk: 745612).fetch()
print("Home WP: \(ctx.homeWinProbability)%  Away WP: \(ctx.awayWinProbability)%")

// Team personnel — trainers, physicians, equipment, clubhouse, travel, security
let personnel = try await SwiftBaseball.teamPersonnel(teamId: 147).fetch()
let trainers = personnel.filter { $0.jobId == "HATR" || $0.jobId == "AATR" }
for p in trainers {
    print(p.title ?? p.job, "-", p.person.fullName)
}

// Team coaching staff — filter by stable jobId codes (MNGR, COAB, COAP, …)
let staff = try await SwiftBaseball.teamCoaches(teamId: 147).fetch()
let manager = staff.first { $0.jobId == "MNGR" }
print(manager?.person.fullName ?? "")

// Team alumni for a given season — Player values carry alumniLastSeason
let alumni = try await SwiftBaseball.teamAlumni(teamId: 147, season: 2024).fetch()
for player in alumni {
    print("\(player.fullName) — last season with team: \(player.alumniLastSeason ?? "?")")
}

// Game pace — compare team vs league average time-per-game (TimeInterval seconds)
let teamPace = try await SwiftBaseball.gamePace(teamId: 147, season: 2024).fetch()
let leaguePace = try await SwiftBaseball.leagueGamePace(season: 2024).fetch()
let gap = (teamPace.timePerGame ?? 0) - (leaguePace.timePerGame ?? 0)
print("Yankees play \(Int(gap / 60))m longer than the MLB average")

// Team leaders — one category entry per stat group (hitting, pitching, catching, ...)
let hr = try await SwiftBaseball
    .teamLeaders(teamId: 147, category: .homeRuns)
    .season(2024)
    .fetch()
let batters = hr.first { $0.statGroup == .batting }
print(batters?.leaders.first?.player.fullName ?? "")   // "Aaron Judge"
print(batters?.leaders.first?.value ?? "")              // "58"

// Season attendance — one record per gameType (regular season, postseason, ...)
let gate = try await SwiftBaseball.attendance(teamId: 147, season: 2024).fetch()
let regular = gate.first { $0.gameType == .regularSeason }
print(regular?.attendanceAverageHome ?? 0)       // 41897
print(regular?.attendanceHigh ?? 0,
      regular?.attendanceHighGamePk ?? 0)        // 48760 745716

// Umpire pool on duty for a date (not a per-game crew)
let umps = try await SwiftBaseball.umpires(date: "2024-07-04").fetch()
let crewChiefs = umps.filter { $0.jobId != "UMPR" }

// Catalogs — sports, leagues, divisions (lookup tables with IDs and metadata)
let sports = try await SwiftBaseball.sports().fetch()
let mlbLeagues = try await SwiftBaseball.leagues(sportId: 1).fetch()
let al = mlbLeagues.first { $0.id == 103 }
print(al?.seasonDates?.regularSeasonStart ?? Date())   // 2026-03-25
let divisions = try await SwiftBaseball.divisions(sportId: 1).fetch()

// Game highlights — key-play clips and condensed game
let content = try await SwiftBaseball.gameHighlights(gamePk: 745612).fetch()
for clip in content.highlights {
    print(clip.title ?? "", clip.duration ?? "")
}
// Best quality stream URL:
let videoURL = content.highlights.first?.playbacks.first?.url
// Condensed game clip:
let condensed = content.scoreboardHighlights.first

// Statcast batted ball profile — GB%, FB%, exit velo, barrel rate
// Use .gameType("R") to restrict to regular-season events only (Baseball Savant
// ignores the game_type URL parameter; filtering is applied client-side on the CSV rows).
let statcast = try await SwiftBaseball
    .statcastBatting(playerId: 660271)
    .dateRange(start: "2024-01-01", end: "2025-04-10")
    .gameType("R")
    .fetch()
print(statcast.gbPercent, statcast.avgExitVelocity, statcast.barrelRate)

// Statcast pitching — batted ball against, pitch arsenal, whiff rate
let pitching = try await SwiftBaseball
    .statcastPitching(playerId: 543037)
    .dateRange(start: "2024-01-01", end: "2025-04-10")
    .gameType("R")
    .fetch()
print(pitching.whiffRate, pitching.avgFastballVelo, pitching.pitchMix)

// Career Statcast splits vs LHP / RHP — full Statcast era (2015–present), no date filter needed
let careerSplits = try await SwiftBaseball
    .statcastCareerSplits(playerId: 660271)
    .fetch()
print(careerSplits.vsLHP.xwOBA)   // career xwOBA vs left-handed pitchers
print(careerSplits.vsRHP.pa)      // career plate appearances vs right-handed pitchers

// Batch career splits for a roster
let rosterSplits = try await SwiftBaseball
    .statcastBatchCareerSplits([660271, 592450, 665742])
    .fetch()
print(rosterSplits[660271]?.vsLHP.xwOBA)   // Ohtani vs LHP

// Computed wOBA from counting stats (FanGraphs linear weights)
// Returns nil if any required field is missing or the denominator is zero
let stats: BattingStats = ...
print(stats.woba)  // Optional(0.424)

// Minor league farm system — all affiliates of an MLB team
let affiliates = try await SwiftBaseball.affiliates(teamId: 147, season: 2024).fetch()
let aaaTeam = affiliates.first { $0.sportName == "Triple-A" }!
print(aaaTeam.name)             // "Scranton/Wilkes-Barre RailRiders"
print(aaaTeam.parentOrgName!)   // "New York Yankees"

// Minor league roster — full season (everyone who appeared)
let mibRoster = try await SwiftBaseball
    .roster(teamId: aaaTeam.id, season: 2024, rosterType: .fullSeason)
    .fetch()

// List all Triple-A teams
let aaaTeams = try await SwiftBaseball.teams(.all(season: 2024)).sport(.tripleA).fetch()

// Award recipients — AL MVP winners
let mvpWinners = try await SwiftBaseball
    .awardRecipients(awardId: "ALMVP")
    .season(2024)
    .fetch()
print(mvpWinners.first?.player?.fullName)  // Optional("Aaron Judge")

// All defined MLB awards
let allAwards = try await SwiftBaseball.awards().fetch()
let active = allAwards.filter(\.active)

// Trade deadline transactions
let trades = try await SwiftBaseball
    .transactions()
    .dateRange(start: "2024-07-01", end: "2024-07-31")
    .fetch()

// Catcher framing leaderboard — framing runs added above average
let framing = try await SwiftBaseball
    .catcherFraming()
    .season(2024)
    .fetch()
print(framing.first?.playerName, framing.first?.framingRunsAdded)

// Catcher pop time — reaction/exchange time and arm strength
let popTimes = try await SwiftBaseball
    .catcherPopTime()
    .season(2024)
    .fetch()
print(popTimes.first?.popTimeTo2B, popTimes.first?.exchangeTime)
```

## Data Sources

| Source | Status | Auth | Data Available |
|---|---|---|---|
| **MLB Stats API** | Supported | None (free) | Players, teams, schedules, standings, box scores, stats, sabermetrics (wOBA/wRC+/WAR), game logs, play-by-play, transactions, awards |
| **Baseball Savant / Statcast** | Supported | None (free) | Batted ball profile (GB%/FB%/LD%), exit velocity, launch angle, barrel rate, xBA/xSLG/xwOBA; career splits vs LHP/RHP (xwOBA + PA); computed wOBA from counting stats; pitcher arsenal (velocity, spin, whiff%, CSW, pitch mix); sprint speed, outs above average, catcher framing |
| Baseball Reference | Planned | None (scraped) | Historical season stats |
| FanGraphs | Planned | None (scraped) | WAR, wRC+, FIP, advanced metrics |

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    SwiftBaseball                         │
│              (Fluent Query API Layer)                    │
├─────────────────────────────────────────────────────────┤
│  Players  │  Teams  │  Schedule  │  Stats  │  Standings │
│           │         │   Games    │ Leaders │            │
├─────────────────────────────────────────────────────────┤
│                  Core / Networking                       │
│  QueryBuilder  │  APIClient  │  Cache  │  Error Types   │
├─────────────────────────────────────────────────────────┤
│                    Data Sources                          │
│  MLB Stats API  │  Baseball Savant    │  BREF (future)  │
└─────────────────────────────────────────────────────────┘
```

All queries flow through the fluent `QueryBuilder`, which constructs the appropriate API request, sends it via the `APIClient`, decodes the response into typed models, and optionally caches the result.

## Installation

Add SwiftBaseball to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/josephskelly/SwiftBaseball.git", from: "0.1.0")
]
```

Then add it as a dependency to your target:

```swift
.target(name: "YourApp", dependencies: ["SwiftBaseball"])
```

## Requirements

| SwiftBaseball | Swift | Platforms |
|---|---|---|
| 0.1.x | 6.0+ | macOS 14+, iOS 17+, iPadOS 17+, tvOS 17+, watchOS 10+, visionOS 1+, Linux |

## Modules

| Module | Description |
|---|---|
| **Core** | APIClient protocol, QueryBuilder, error types, configuration |
| **Models** | Shared Codable structs: Player, Team, Game, Stats, Standings |
| **Endpoints/Players** | Player search, bios, roster lookups |
| **Endpoints/Teams** | Team info, rosters, coaches |
| **Endpoints/Schedule** | Game schedules by date, team, or season |
| **Endpoints/Games** | Box scores, line scores, play-by-play |
| **Endpoints/GameLog** | Per-game stat lines for a player |
| **Endpoints/PlayByPlay** | Pitch-level play-by-play with runner and matchup data |
| **Endpoints/Transactions** | Trades, signings, and roster moves |
| **Endpoints/Stats** | Batting, pitching, fielding, sabermetric statistics |
| **Endpoints/Statcast** | Batted ball profile, exit velocity, launch angle, barrel rate (via Baseball Savant CSV) |
| **Endpoints/Standings** | Division, league, and wildcard standings |
| **Endpoints/Leaders** | League leaders by stat category |
| **Endpoints/Awards** | Award definitions and season recipients |
| **Cache** | Actor-based response caching with TTL |

## Comparison with pybaseball

| pybaseball | SwiftBaseball |
|---|---|
| `batting_stats(2024)` | `SwiftBaseball.playerStats(id: 592450).season(2024).fetch()` |
| `pitching_stats(2024)` | `SwiftBaseball.playerStats(id: 477132).season(2024).fetch()` |
| `playerid_lookup("ohtani")` | `SwiftBaseball.players(.search("Ohtani")).fetch()` |
| `standings(2024)` | `SwiftBaseball.standings(.season(2024)).fetch()` |
| `schedule_and_record(2024)` | `SwiftBaseball.schedule(.season(2024)).teamId(147).fetch()` |

## Roadmap

See [docs/IMPLEMENTATION_PLAN.md](docs/IMPLEMENTATION_PLAN.md) for the full phased roadmap.

- **Phase 1** — Foundation: Package.swift, core types, networking layer, query builder
- **Phase 2** — Player & team data endpoints
- **Phase 3** — Game data, schedules, box scores
- **Phase 4** — Statistics, standings, league leaders
- **Phase 5** — Caching, batch queries, CI/CD, documentation polish

## Contributing

Contributions are welcome! Please open an issue to discuss proposed changes before submitting a pull request.

## License

SwiftBaseball is released under the MIT License. See [LICENSE](LICENSE) for details.

## Acknowledgments

- Inspired by [pybaseball](https://github.com/jldbc/pybaseball) by James LeDoux
- Data provided by the [MLB Stats API](https://statsapi.mlb.com)
