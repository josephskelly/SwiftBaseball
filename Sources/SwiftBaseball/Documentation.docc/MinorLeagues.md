# Minor Leagues

Querying Triple-A, Double-A, High-A, Single-A, Rookie, and the Complex League.

## Overview

Most SwiftBaseball methods default to MLB (`sportId=1`), but the same MLB Stats API endpoints serve every affiliated level of professional baseball. The ``Sport`` enum enumerates them; chain ``QueryBuilder/sport(_:)`` on any query that accepts it to retarget.

| Case | Sport ID | Level |
|---|---|---|
| `.mlb` | 1 | Major League Baseball |
| `.tripleA` | 11 | Triple-A (International / Pacific Coast) |
| `.doubleA` | 12 | Double-A (Eastern / Southern / Texas) |
| `.highA` | 13 | High-A (Northwest / South Atlantic / Midwest) |
| `.singleA` | 14 | Single-A (California / Carolina / Florida State) |
| `.rookie` | 16 | Rookie ball |
| `.complexLeague` | 17 | Complex League (Arizona / Florida) |

## Common queries

Schedules, rosters, player stats, and team rosters all accept a sport modifier:

```swift
// Triple-A schedule for opening week 2024
let aaa = try await SwiftBaseball.schedule(.dateRange(start: "2024-03-29", end: "2024-04-05"))
    .sport(.tripleA)
    .fetch()

// Player's Triple-A batting line
let stats = try await SwiftBaseball.playerStats(id: 605_141)
    .season(2024)
    .group(.batting)
    .sport(.tripleA)
    .fetch()
```

For a league-wide enumeration of every player active at a given level, use ``SwiftBaseball/sportPlayers(sport:season:)``:

```swift
let aaaPlayers = try await SwiftBaseball.sportPlayers(sport: .tripleA, season: 2024).fetch()
print(aaaPlayers.count)  // ~1,200 across all 30 organizations
```

## What works the same as MLB

Schedules, standings, rosters, players, transactions, awards (where awarded), team-history endpoints, and the seasonal stat endpoints all accept the sport modifier and return the same shapes you already know from MLB queries. Player IDs stay consistent across levels — a prospect's MLB ID at Triple-A is the same one they'll keep on debut.

## What's different at the minor-league level

A handful of upstream features are unavailable below MLB. The library does not warn at compile time, so know these going in:

- **No Statcast.** Baseball Savant's tracking is MLB-only. Calls into ``StatcastQuery`` / ``StatcastPitcherQuery`` / leaderboards return empty data for minor-league players' minor-league seasons. Some affiliates run trackman demos in Triple-A spring training, but the public Savant exports do not include them.
- **No advanced sabermetrics.** The `sabermetrics` view (``SabermetricStats`` — wOBA / wRC+ / WAR / etc.) is published only for MLB seasons. Minor-league ``PlayerSeasonStats`` queries return the standard counting and rate stats but a `nil` `sabermetrics` field.
- **Sparser play-by-play.** ``SwiftBaseball/liveGameFeed(gamePk:)`` and ``SwiftBaseball/playByPlay(gamePk:)`` are populated for affiliated minor-league games, but pitch-call density and batted-ball metadata are coarser than MLB.
- **Team metadata varies.** Some Complex League and Rookie affiliates lack venue references or league objects in `teams/history` snapshots. The library tolerates the missing fields (see `MLBEntityRef`'s tolerant decode), but consumers should expect optionals where the MLB equivalent is non-nil.

## Discovering the sport / league hierarchy

The `Sport`/`League`/`Division` enums above cover the queryable sport IDs, but the upstream also publishes catalog endpoints listing every league/division at every level — useful when you need to show users a picker that mirrors `MiLB.com`. The ``SportCatalog``, ``LeagueCatalog``, and ``DivisionCatalog`` types (note the `-Catalog` suffix to avoid colliding with the query enums) are the canonical way to enumerate.

```swift
let all = try await SwiftBaseball.sports().fetch()
for sport in all where sport.id >= 11 && sport.id <= 17 {
    print(sport.name, sport.id)
}
```

## Tips

- Pass `.sport(.tripleA)` to a `QueryBuilder` chain *before* any filter that depends on the level — `season(_:)`, `teamId(_:)` etc. land on the same builder regardless of order, but reading the chain is easier with the level set first.
- Spring training games at every level use `gameType: "S"`; pre-season exhibition uses `"E"`. Both are filterable via ``QueryBuilder/gameType(_:)``.
- Triple-A seasons are usually 150 games (vs. 162 MLB). Double-A and below are 132 games. Sanity-check schedule lengths in test fixtures.

## Topics

### Related articles

- <doc:GettingStarted>
- <doc:DataSources>

### Related types

- ``Sport``
- ``SportCatalog``
- ``LeagueCatalog``
