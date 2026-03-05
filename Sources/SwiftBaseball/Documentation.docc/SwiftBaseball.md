# ``SwiftBaseball``

A Swift library for accessing MLB statistics via the MLB Stats API.

## Overview

SwiftBaseball provides a fluent, type-safe API for querying MLB player, team, game, and statistical data. All queries use async/await and return strongly-typed Swift models.

```swift
// Fetch a player by ID
let player = try await SwiftBaseball.players(id: 660271).fetch()

// Get today's schedule
let games = try await SwiftBaseball.schedule().fetch()

// Look up league leaders
let leaders = try await SwiftBaseball.leaders(.homeRuns)
    .season(2024)
    .fetch()
```

## Topics

### Essentials

- ``SwiftBaseball``
- ``Configuration``
- ``QueryBuilder``

### Players

- ``Player``
- ``RosterEntry``
- ``PlayerReference``

### Teams

- ``Team``
- ``TeamReference``

### Games & Schedule

- ``ScheduleEntry``
- ``ScheduleTeams``
- ``ScheduleTeamEntry``
- ``LeagueRecord``
- ``Boxscore``
- ``BoxscoreTeams``
- ``BoxscoreTeam``
- ``BoxscoreTeamStats``
- ``BoxscorePlayer``
- ``BoxscorePlayerStats``
- ``Official``
- ``BoxscoreInfoItem``
- ``Linescore``
- ``InningLine``
- ``InningScore``
- ``LinescoreTeams``
- ``LinescoreTeamTotals``
- ``LinescoreOffense``
- ``LinescoreDefense``

### Statistics

- ``BattingStats``
- ``PitchingStats``
- ``FieldingStats``
- ``PlayerSeasonStats``
- ``StatGroup``
- ``StatType``

### Standings

- ``DivisionStandings``
- ``StandingsRecord``
- ``Streak``
- ``LastTen``

### Leaders

- ``LeaderCategory``
- ``LeaderEntry``
- ``LeaderStatCategory``

### Enumerations

- ``Position``
- ``HandSide``
- ``League``
- ``Division``
- ``GameType``
- ``GameStatus``

### References

- ``LeagueReference``
- ``DivisionReference``
- ``VenueReference``
- ``Venue``

### Errors

- ``SwiftBaseballError``

### Caching

- ``CacheManager``
