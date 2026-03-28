# SwiftBaseball

> A Swift-native library for MLB statistics — like [pybaseball](https://github.com/jldbc/pybaseball), but Swift.

[![Swift 5.9+](https://img.shields.io/badge/Swift-5.9+-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-macOS%20|%20iOS%20|%20tvOS%20|%20watchOS%20|%20Linux-blue.svg)](https://swift.org)
[![License: MIT](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## Overview

SwiftBaseball provides typed, async access to MLB data through a fluent query API. Built on the [MLB Stats API](https://statsapi.mlb.com), it gives Swift developers first-class access to player info, game schedules, standings, statistics, and more — with zero third-party dependencies.

No DataFrames, no untyped dictionaries. Just Swift structs, async/await, and autocomplete.

## Features

- **Fluent query API** — chainable, type-safe, discoverable via autocomplete
- **async/await** — built on Swift concurrency from the ground up
- **Codable models** — every response is a typed Swift struct
- **Cross-platform** — macOS, iOS, tvOS, watchOS, and Linux
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

// Pitcher platoon splits — OPS against vs LHB / vs RHB
let pitcherSplits = try await SwiftBaseball
    .pitcherPlatoonStats(id: 660271)
    .season(2023)
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

// Statcast batted ball profile — GB%, FB%, exit velo, barrel rate
let statcast = try await SwiftBaseball
    .statcastBatting(playerId: 660271)
    .season(2024)
    .fetch()
print(statcast.gbPercent, statcast.avgExitVelocity, statcast.barrelRate)

// Statcast pitching — batted ball against, pitch arsenal, whiff rate
let pitching = try await SwiftBaseball
    .statcastPitching(playerId: 543037)
    .season(2024)
    .fetch()
print(pitching.whiffRate, pitching.avgFastballVelo, pitching.pitchMix)

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
| **MLB Stats API** | Supported | None (free) | Players, teams, schedules, standings, box scores, stats, sabermetrics (wOBA/wRC+/WAR), game logs, play-by-play, transactions |
| **Baseball Savant / Statcast** | Supported | None (free) | Batted ball profile (GB%/FB%/LD%), exit velocity, launch angle, barrel rate, xBA/xSLG/xwOBA; pitcher arsenal (velocity, spin, whiff%, CSW, pitch mix); sprint speed, outs above average, catcher framing |
| Baseball Reference | Planned | None (scraped) | Historical season stats, awards |
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
| 0.1.x | 5.9+ | macOS 13+, iOS 16+, tvOS 16+, watchOS 9+, Linux |

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
