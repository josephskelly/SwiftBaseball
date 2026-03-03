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

// Get season batting stats
let battingStats = try await SwiftBaseball
    .stats(.batting)
    .season(2024)
    .team("NYY")
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

// Player detail with stats
let judge = try await SwiftBaseball.player(id: 592450).fetch()
```

## Data Sources

| Source | Status | Auth | Data Available |
|---|---|---|---|
| **MLB Stats API** | Supported | None (free) | Players, teams, schedules, standings, box scores, stats |
| Baseball Savant / Statcast | Planned | None | Pitch-level data, exit velocity, spin rate, launch angle |
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
│  MLB Stats API  │  Statcast (future)  │  BREF (future)  │
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
| **Endpoints/Stats** | Batting, pitching, fielding statistics |
| **Endpoints/Standings** | Division, league, and wildcard standings |
| **Endpoints/Leaders** | League leaders by stat category |
| **Cache** | Actor-based response caching with TTL |

## Comparison with pybaseball

| pybaseball | SwiftBaseball |
|---|---|
| `batting_stats(2024)` | `SwiftBaseball.stats(.batting).season(2024).fetch()` |
| `pitching_stats(2024)` | `SwiftBaseball.stats(.pitching).season(2024).fetch()` |
| `playerid_lookup("ohtani")` | `SwiftBaseball.players(.search("Ohtani")).fetch()` |
| `standings(2024)` | `SwiftBaseball.standings(.season(2024)).fetch()` |
| `schedule_and_record(2024, "NYY")` | `SwiftBaseball.schedule(.season(2024)).team("NYY").fetch()` |

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
