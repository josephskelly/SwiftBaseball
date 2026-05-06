# Migrating from pybaseball

A function-by-function map for users coming from the Python library.

## Overview

If you've used [pybaseball](https://github.com/jldbc/pybaseball), the SwiftBaseball API will feel familiar. Most concepts translate directly — both libraries wrap the MLB Stats API and Baseball Savant — but Swift's stronger type system reshapes a few corners.

The biggest shift: pybaseball returns `pandas.DataFrame` from almost everything, leaving column names and dtypes as runtime concerns. SwiftBaseball returns typed structs (``Player``, ``StatcastBatting``, ``StatcastPitch``, …) so column drift surfaces at compile time, not in row 14 230 of an aggregation.

## Players and rosters

| pybaseball | SwiftBaseball |
|---|---|
| `playerid_lookup("trout", "mike")` | ``SwiftBaseball/players(_:)`` with ``PlayerQuery/search(_:)`` |
| `playerid_reverse_lookup([545361])` | ``SwiftBaseball/player(id:)`` |
| `team_results(team, year)` | ``SwiftBaseball/schedule(_:)`` chained with ``QueryBuilder/teamId(_:)`` |
| `roster(team, year)` | ``SwiftBaseball/roster(teamId:season:rosterType:date:)`` |

```swift
// pybaseball: playerid_lookup("trout", "mike")
let trout = try await SwiftBaseball.players(.search("Mike Trout")).fetch().first
```

## Batting and pitching stats

| pybaseball | SwiftBaseball |
|---|---|
| `batting_stats(2024)` | ``SwiftBaseball/playerStats(id:)`` per player, or ``SwiftBaseball/batchStats(_:group:)`` for many |
| `pitching_stats(2024)` | same, with `group: .pitching` |
| `batting_stats_bref(2024)` | not implemented (BREF is a separate scrape; SwiftBaseball stays on official sources) |
| `team_batting(2024)` | ``SwiftBaseball/teamStats(teamId:group:)`` |
| `pitching_stats_range(start, end)` | ``SwiftBaseball/playerStats(id:)`` chained with ``QueryBuilder/dateRange(start:end:)`` |

The pybaseball "all batters in a season" call returns one DataFrame for everyone. The SwiftBaseball idiom is to fetch the season roster (``SwiftBaseball/sportPlayers(sport:season:)``) and then ``SwiftBaseball/batchStats(_:group:)`` the IDs — the batch internally fans out concurrently within the rate limit.

```swift
let all = try await SwiftBaseball.sportPlayers(season: 2024).fetch()
let lines = try await SwiftBaseball.batchStats(all.map(\.id), group: .batting).fetch()
```

## Sabermetrics (wOBA / wRC+ / WAR)

| pybaseball | SwiftBaseball |
|---|---|
| `fg_batting_data(2024)` (FanGraphs) | ``SwiftBaseball/playerSabermetrics(id:)`` (MLB-published WAR) |
| `fg_pitching_data(2024)` | same; check `sabermetrics` field on result |

Note that pybaseball pulls FanGraphs values; SwiftBaseball pulls the MLB Stats API's `sabermetrics` view, which uses MLB's own WAR computation and returns a slightly smaller column set (no batted-ball profile — see <doc:Statcast> for the Savant route to that data).

## Statcast

| pybaseball | SwiftBaseball |
|---|---|
| `statcast(start_dt, end_dt)` | ``SwiftBaseball/statcastRaw(start:end:)`` |
| `statcast_batter(start, end, player_id)` | ``SwiftBaseball/statcastBatterRaw(playerId:)`` chained with `dateRange` |
| `statcast_pitcher(start, end, player_id)` | ``SwiftBaseball/statcastPitcherRaw(playerId:)`` |
| `statcast_single_game(game_pk)` | ``SwiftBaseball/statcastGame(gamePk:)`` |
| `statcast_batter_expected_stats(year)` | ``SwiftBaseball/expectedStatsBatter()`` |
| `statcast_pitcher_expected_stats(year)` | ``SwiftBaseball/expectedStatsPitcher()`` |
| `statcast_batter_percentile_ranks(year)` | ``SwiftBaseball/percentileRanksBatter()`` |
| `statcast_pitcher_percentile_ranks(year)` | ``SwiftBaseball/percentileRanksPitcher()`` |
| `statcast_batter_exitvelo_barrels(year)` | ``SwiftBaseball/exitVeloBarrelsBatter()`` |
| `statcast_pitcher_exitvelo_barrels(year)` | ``SwiftBaseball/exitVeloBarrelsPitcher()`` |
| `statcast_pitcher_arsenal_stats(year)` | ``SwiftBaseball/pitchArsenalStats()`` |
| `statcast_pitcher_pitch_movement(year)` | ``SwiftBaseball/pitchMovement()`` |
| `statcast_pitcher_active_spin(year)` | ``SwiftBaseball/activeSpin()`` |
| `statcast_running_splits_90_ft(year)` | ``SwiftBaseball/runningSplits()`` |
| `statcast_batter_bat_tracking(year)` | ``SwiftBaseball/batTracking()`` |
| `statcast_outfield_catch_prob(year)` | ``SwiftBaseball/outfieldCatchProbability()`` |
| `statcast_outfielder_jump(year)` | ``SwiftBaseball/outfielderJumps()`` |
| `statcast_fielding_run_value(year)` | ``SwiftBaseball/pitcherFieldingRunValue()`` (pitcher-centric, see article) |
| `statcast_baserunning_run_value(year)` | ``SwiftBaseball/baserunningRunValue()`` |
| `statcast_swing_take_run_value(year)` | ``SwiftBaseball/swingTake()`` |
| `statcast_pitcher_spin_dir_comp(year)` | ``SwiftBaseball/pitchTilt()`` |
| `statcast_sprint_speed(year)` | ``SwiftBaseball/sprintSpeed()`` |
| `statcast_outs_above_average(year)` | ``SwiftBaseball/outsAboveAverage()`` |
| `statcast_catcher_framing(year)` | ``SwiftBaseball/catcherFraming()`` |
| `statcast_catcher_poptime(year)` | ``SwiftBaseball/catcherPopTime()`` |

The shape of the Swift call is the same across every leaderboard:

```swift
// pybaseball: statcast_batter_percentile_ranks(year=2024)
let pcts = try await SwiftBaseball.percentileRanksBatter().season(2024).fetch()
```

For raw pitch-level data, SwiftBaseball does the 7-day chunking automatically when the date range exceeds Savant's 25 000-row cap, where pybaseball requires the user to chunk manually. SwiftBaseball also offers an ``StatcastRawQuery/stream()`` form that yields one ``StatcastPitch`` at a time — pybaseball has no streaming equivalent.

## Standings, schedule, leaders

| pybaseball | SwiftBaseball |
|---|---|
| `standings(year)` | ``SwiftBaseball/standings(_:)`` |
| `schedule_and_record(year, team)` | ``SwiftBaseball/schedule(_:)`` + ``QueryBuilder/teamId(_:)`` |
| `top_prospects(team)` | not 1:1 (use ``SwiftBaseball/draftProspects(year:)`` for draft pool) |
| `pitching_leaders` / `batting_leaders` | ``SwiftBaseball/leaders(_:)`` with a ``LeaderStatCategory`` |

## Lahman / Retrosheet / Chadwick

pybaseball exposes the Lahman database, Retrosheet event files, and the Chadwick Bureau's name register through `lahman_*`, `retrosheet_*`, and `chadwick_*` modules. SwiftBaseball does not. The MLB Stats API and Savant cover everything from 1903 forward (Stats API) and 2015 forward (Savant) — historical eras before that aren't yet wired up.

If you need pre-1903 data or per-game event files in the Retrosheet schema, those data sources are out of scope for this library.

## Calling style

pybaseball is mostly side-effecting: import → call → get a DataFrame. SwiftBaseball uses async/await and a fluent builder:

```python
# pybaseball
from pybaseball import statcast_batter
df = statcast_batter("2024-04-01", "2024-09-30", 660271)
```

```swift
// SwiftBaseball
let pitches = try await SwiftBaseball
    .statcastBatterRaw(playerId: 660_271)
    .dateRange(start: "2024-04-01", end: "2024-09-30")
    .fetch()
```

The builder is chainable: `.season(_:)`, `.dateRange(start:end:)`, `.gameType(_:)`, `.sport(_:)`, `.limit(_:)`, etc. all return a refined builder; `.fetch()` is the terminal `await`.

## Caching

pybaseball ships an opt-in disk cache (`pybaseball.cache.enable()`). SwiftBaseball ships an opt-in in-memory cache (``Configuration/cacheEnabled``). See <doc:Caching> for the trade-offs — the on-disk story is left to the caller because iOS sandboxing makes "where to cache" an app-level decision.

## Topics

### Related articles

- <doc:GettingStarted>
- <doc:DataSources>
- <doc:Statcast>
- <doc:Caching>
