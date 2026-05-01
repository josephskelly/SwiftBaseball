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
- ``TeamStaff``
- ``TeamAttendance``

### Officials

- ``Umpire``

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

### Play-by-Play

- ``PlayByPlay``
- ``Play``
- ``PlayResult``
- ``PlayAbout``
- ``Count``
- ``PlayMatchup``
- ``Runner``
- ``RunnerMovement``
- ``RunnerDetails``
- ``PlayEvent``
- ``PlayEventDetails``
- ``CodeDescription``
- ``PitchData``

### Game Log

- ``GameLogEntry``

### Transactions

- ``Transaction``

### Statistics

- ``BattingStats``
- ``PitchingStats``
- ``FieldingStats``
- ``SabermetricStats``
- ``PlayerSeasonStats``
- ``StatGroup``
- ``StatType``

### Statcast

- ``StatcastBatting``
- ``StatcastQuery``
- ``StatcastPitch``
- ``StatcastRawQuery``
- ``StatcastBatterRawQuery``
- ``StatcastPitcherRawQuery``
- ``StatcastGameRawQuery``

### Statcast Leaderboards

- ``SprintSpeedEntry``
- ``OutsAboveAverageEntry``
- ``CatcherFramingEntry``
- ``PopTimeEntry``
- ``ExpectedStatsBatterEntry``
- ``ExpectedStatsPitcherEntry``
- ``PercentileRanksBatterEntry``
- ``PercentileRanksPitcherEntry``
- ``ExitVeloBarrelsBatterEntry``
- ``ExitVeloBarrelsPitcherEntry``
- ``PitchArsenalEntry``
- ``PitchArsenalMetric``
- ``PitchArsenalStatsEntry``
- ``PitchMovementEntry``
- ``ActiveSpinEntry``
- ``RunningSplitsEntry``
- ``BatTrackingEntry``
- ``OutfieldCatchProbabilityEntry``
- ``OutfielderJumpEntry``
- ``PitcherFieldingRunValueEntry``
- ``BaserunningRunValueEntry``
- ``SwingTakeEntry``
- ``PitchTiltEntry``

### Standings

- ``DivisionStandings``
- ``StandingsRecord``
- ``Streak``
- ``LastTen``

### Leaders

- ``LeaderCategory``
- ``LeaderEntry``
- ``LeaderStatCategory``
- ``TeamLeaderCategory``
- ``GamePace``

### Catalogs

- ``SportCatalog``
- ``LeagueCatalog``
- ``LeagueSeasonDates``
- ``DivisionCatalog``

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
