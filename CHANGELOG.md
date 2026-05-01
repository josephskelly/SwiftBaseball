# Changelog

All notable changes to SwiftBaseball will be documented in this file.

This project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Added

- **Statcast active-spin leaderboard**: `SwiftBaseball.activeSpin()` returns `[ActiveSpinEntry]` from Savant's `leaderboard/active-spin`. Active spin is the share of a pitch's total spin that produces movement (Magnus effect) versus gyro spin. The upstream CSV is wide — one row per pitcher with one column per pitch type — and the parser flattens it to one entry per (pitcher × pitch type) the pitcher actually throws, skipping empty cells. Values are reported on the **0–100 scale** matching the Savant CSV
- **Statcast running-splits leaderboard**: `SwiftBaseball.runningSplits()` returns `[RunningSplitsEntry]` from Savant's `leaderboard/running_splits`. Surfaces cumulative seconds elapsed at every 5-foot mark from contact through 90 ft (home-to-first), useful for reconstructing acceleration profiles. Switch-hitters appear once per side of the plate
- **Statcast bat-tracking leaderboard (2024+)**: `SwiftBaseball.batTracking()` returns `[BatTrackingEntry]` from Savant's `leaderboard/bat-tracking`. Surfaces the swing mechanics first lit up by Statcast in 2024 — average bat speed (mph), swing length (ft), hard-swing rate, squared-up rate (per contact and per swing), blast rate, sword counts, batter run value, and whiff / batted-ball rates. Rate fields on this board are reported on the **0–1 fraction scale** (e.g. `0.85` means 85%), unlike most other Savant leaderboards. Older seasons return empty data

## [0.4.0] — 2026-05-01

### Added

- **Raw Statcast pitch-level access**: four new endpoints expose un-aggregated pitch data from Baseball Savant. `SwiftBaseball.statcastRaw(start:end:)` returns `[StatcastPitch]` across an arbitrary date range, splitting the request into 7-day chunks internally (dispatched concurrently) so each response stays under Savant's 25 000-row CSV cap. `SwiftBaseball.statcastBatterRaw(playerId:)` and `SwiftBaseball.statcastPitcherRaw(playerId:)` filter to a single player with the same `.season(_:)` / `.dateRange(start:end:)` builders the aggregator queries already use. `SwiftBaseball.statcastGame(gamePk:)` returns every pitch from a single game by `game_pk`. `StatcastPitch` exposes typed fields for every documented Savant CSV column — pitch identification, release / movement / location, batted-ball outcome, expected stats, win-probability deltas, fielding alignment, scoring state, player ages and rest, plus the 2024+ bat-tracking surface (`batSpeed`, `swingLength`, `attackAngle`, `attackDirection`, `swingPathTilt`, `armAngle`, intercept-position offsets) — together with a `raw: [String: String]` escape hatch carrying every column verbatim, including any Savant adds in the future
- **Statcast pitch-arsenals leaderboard**: `SwiftBaseball.pitchArsenal()` returns `[PitchArsenalEntry]` from Savant's `leaderboard/pitch-arsenals`. The upstream board is wide (one row per pitcher, one column per pitch type); the parser flattens it to one entry per (pitcher × pitch type) so all metric views share the same row layout. Chain `.metric(.velocity)` (default) or `.metric(.spin)` to choose between average release velocity (mph) and average spin rate (rpm). The board's HTML usage view exists, but the CSV export returns empty cells for usage; per-pitch usage and pitch counts are exposed via `pitchArsenalStats()` instead
- **Statcast pitch-arsenal-stats leaderboard**: `SwiftBaseball.pitchArsenalStats()` returns `[PitchArsenalStatsEntry]` from Savant's `leaderboard/pitch-arsenal-stats`. One row per pitcher × pitch type with run value (per 100 and total), pitches thrown, pitch usage %, plate appearances, BA / SLG / wOBA actual and expected against, whiff %, K %, put-away %, and hard-hit %. Chain `.minPlateAppearances(_:)` to relax the default 25-PA-per-pitch-type cutoff
- **Statcast pitch-movement leaderboard**: `SwiftBaseball.pitchMovement()` returns `[PitchMovementEntry]` from Savant's `leaderboard/pitch-movement`. One row per pitcher × pitch type with raw vertical break (gravity-included and induced), horizontal break, league averages at the same pitch type and velocity, signed differentials (`diffZ` / `diffX`), Savant's integer rise / tail readings, and percentile ranks of the differentials. The CSV's `year` column populates `season`, falling back to the query's `.season(_:)` value if absent
- **Statcast expected-stats leaderboards**: `SwiftBaseball.expectedStatsBatter()` returns `[ExpectedStatsBatterEntry]` and `SwiftBaseball.expectedStatsPitcher()` returns `[ExpectedStatsPitcherEntry]` from Baseball Savant's `leaderboard/expected_statistics`. Each entry pairs actual BA / SLG / wOBA with their Statcast-derived expected counterparts (xBA / xSLG / xwOBA) plus actual-vs-expected diffs; pitcher entries additionally carry actual ERA, xERA, and the ERA / xERA diff
- **Statcast percentile-rankings leaderboards**: `SwiftBaseball.percentileRanksBatter()` returns `[PercentileRanksBatterEntry]` and `SwiftBaseball.percentileRanksPitcher()` returns `[PercentileRanksPitcherEntry]` from Savant's `leaderboard/percentile-rankings`. Each value is a 1–99 rank within the qualifying batter / pitcher pool. Batter entries cover xwOBA / xBA / xSLG / xISO / xOBP, exit velocity, hard-hit, K%, BB%, whiff, chase, arm strength, sprint speed, OAA, and (2024+) bat speed / squared-up rate / swing length. Pitcher entries replace running and bat-tracking ranks with xERA, fastball velocity / spin, and curveball spin
- **Statcast exit-velo & barrels leaderboards**: `SwiftBaseball.exitVeloBarrelsBatter()` returns `[ExitVeloBarrelsBatterEntry]` and `SwiftBaseball.exitVeloBarrelsPitcher()` returns `[ExitVeloBarrelsPitcherEntry]` from Savant's `leaderboard/statcast` board. Surfaces full contact-quality summary: average / max EV, EV50, sweet-spot rate, FB-LD vs GB EV split, max / average / HR distance, hard-hit count and rate, barrels, barrel rate per BBE, and barrels per PA. Percent fields are reported on a 0–100 scale matching the Savant CSV

## [0.3.0] — 2026-04-30

### Changed

- **Swift 6 language mode**: `Package.swift` now advertises `swiftLanguageModes: [.v6]`, asserting full strict-concurrency compliance for every target
- **Platform floor**: minimum supported platforms are now iOS 17 / iPadOS 17 / macOS 14 / tvOS 17 / watchOS 10 / visionOS 1 / Linux. Advertised platform claims in README, `CLAUDE.md`, and docs aligned to the manifest
- **`SwiftBaseball` state holder**: `@unchecked Sendable` now backed by real `NSLock` serialization for reads and writes instead of unsynchronized access, making `configure(_:)` safe under concurrent callers while preserving its synchronous signature

### Added

- **Sports / leagues / divisions catalogs**: three new lookup endpoints — `SwiftBaseball.sports()` returns `[SportCatalog]` via `GET /sports` (MLB, minor league levels, KBO/NPB, Olympic competition, Negro Leagues); `SwiftBaseball.leagues(sportId:)` returns `[LeagueCatalog]` via `GET /leagues` with full `seasonDates` (spring/regular/postseason/All-Star dates parsed to `Date`); `SwiftBaseball.divisions(sportId:)` returns `[DivisionCatalog]` via `GET /divisions`. Types intentionally suffixed to avoid collision with the existing ``Sport``/``League``/``Division`` query enums
- **visionOS support**: `.visionOS(.v1)` added to `Package.swift` platforms
- **Platoon splits endpoint**: `SwiftBaseball.playerPlatoonStats(id:)` returns `PlayerPlatoonStats` with vs-LHP and vs-RHP batting stats via `stats=statSplits&sitCodes=vl,vr`
- **Pitcher platoon splits endpoint**: `SwiftBaseball.pitcherPlatoonStats(id:)` returns `PitcherPlatoonStats` with vs-LHB and vs-RHB pitching stats (OPS against, WHIP, K, etc.)
- **Pitching opponent rates**: `obp`, `slg`, `ops` on `PitchingStats` (on-base, slugging, OPS against)
- **Configuration thread-safety tests**: `ConfigurationTests` exercises concurrent `configure(_:)` callers and the caching-client toggle path
- **Public release plan**: `docs/PUBLIC_RELEASE_PLAN.md` — roadmap to full MLB Stats API + Baseball Savant coverage and `v1.0.0` GA
- **DocC → GitHub Pages workflow**: `.github/workflows/docs.yml` builds the `SwiftBaseball` target docs with `xcodebuild docbuild` and deploys to GitHub Pages on push to `main` and on release
- **Lint & format CI**: `.github/workflows/lint.yml` runs `swiftlint lint --strict` and `swiftformat --lint Sources Tests`; matching `.swiftlint.yml` and `.swiftformat` configs checked in
- **Code coverage**: macOS CI job now runs `swift test --enable-code-coverage`, exports lcov via `llvm-cov`, and uploads to Codecov; Swift CI and Codecov badges added to the README
- **Nightly integration tests**: `.github/workflows/nightly-integration.yml` runs the `SWIFTBASEBALL_INTEGRATION=1` suite against live MLB Stats API + Baseball Savant at 07:00 UTC with `workflow_dispatch` for manual runs
- **Governance docs**: `CONTRIBUTING.md`, `SECURITY.md`, `CODE_OF_CONDUCT.md` (Contributor Covenant 2.1), targeted issue forms (bug, endpoint request, stat-decoding bug), and a PR template mirroring the pre-PR checklist
- **Swift Package Index prep**: `.spi.yml` declaring the DocC target and Swift 6.0 builder; SPI platform + Swift-version badges on the README; release and PackageList-submission instructions in `CONTRIBUTING.md`
- **Live game feed endpoint**: `SwiftBaseball.liveGameFeed(gamePk:)` returns a composite ``LiveGameFeed`` covering game metadata, all plays, current play, linescore, boxscore, and winning/losing/save decisions via the v1.1 endpoint `GET /api/v1.1/game/{gamePk}/feed/live`. Per-team current score is lifted from the linescore into ``LiveGameTeam/score`` for direct access
- **Win probability endpoint**: `SwiftBaseball.winProbability(gamePk:)` returns one ``PlayWinProbability`` per completed at-bat, carrying home/away win-probability percentages and the per-play WPA (``PlayWinProbability/homeTeamWinProbabilityAdded``) via `GET /game/{gamePk}/winProbability`
- **Context metrics endpoint**: `SwiftBaseball.contextMetrics(gamePk:)` returns a ``GameContextMetrics`` snapshot of current home/away win probability for a game via `GET /game/{gamePk}/contextMetrics`
- **Team coaches endpoint**: `SwiftBaseball.teamCoaches(teamId:)` returns the team's current coaching staff as `[TeamStaff]` — manager plus field coaches, each with person ref, jersey number, free-form job title, and stable ``TeamStaff/jobId`` code (e.g. `"MNGR"`, `"COAB"`, `"COAP"`) — via `GET /teams/{id}/coaches`
- **Team personnel endpoint**: `SwiftBaseball.teamPersonnel(teamId:)` returns off-field support staff as `[TeamStaff]` — trainers, team physicians, strength and conditioning, dietitians, equipment and clubhouse, travel, security, and media relations. Identical response shape to `teamCoaches`; role distinguished via ``TeamStaff/jobId`` (e.g. `"HATR"` head athletic trainer, `"EQUP"` equipment manager, `"TSEC"` team security) — via `GET /teams/{id}/personnel`
- **`TeamStaff` doc broadening**: type doc now covers both on-field (``teamCoaches(teamId:)``) and off-field (``teamPersonnel(teamId:)``) staff
- **Team alumni endpoint**: `SwiftBaseball.teamAlumni(teamId:season:)` returns former players associated with the team for a given season as `[Player]`, via `GET /teams/{id}/alumni?season=N` (season is required by the upstream API)
- **Umpires endpoint**: `SwiftBaseball.umpires(date:)` returns the MLB umpire pool eligible to work on a given calendar date as `[Umpire]`, via `GET /jobs/umpires?date=YYYY-MM-DD`. Standard pool entries carry ``Umpire/jobId`` `"UMPR"`; crew chiefs and umpire-desk roles use distinct codes
- **Attendance endpoint**: `SwiftBaseball.attendance(teamId:season:)` returns `[TeamAttendance]` with season paid-gate totals, averages, and high/low games (with flattened ``TeamAttendance/attendanceHighGamePk`` and ``TeamAttendance/attendanceLowGamePk``), via `GET /attendance?teamId=N&season=Y`
- **Team leaders endpoint**: `SwiftBaseball.teamLeaders(teamId:category:)` returns `[TeamLeaderCategory]` — one category per stat group (hitting/pitching/catching/...) so the same leader category (e.g. `.homeRuns`) can surface both batter and pitcher boards in a single call. Chain `.season(_:)` to scope to a year. Via `GET /teams/{id}/leaders?leaderCategories=X`
- **Game pace endpoints**: `SwiftBaseball.gamePace(teamId:season:)` and `SwiftBaseball.leagueGamePace(season:)` return `GamePace` — time-per-game, time-per-pitch, pitch/PA counts, and ancillary pace figures. Upstream `H:MM:SS` duration strings are parsed to `TimeInterval` seconds at decode time (hours may exceed 24 since these are durations, not clock times). Throws `SwiftBaseballError.notFound` if the expected record is absent. Via `GET /gamePace?teamIds=N&season=Y` / `GET /gamePace?sportId=1&season=Y`
- **`Player.alumniLastSeason`**: new optional `String?` field populated only by the team alumni endpoint; carries the last season the player appeared with the queried team (e.g. `"2022"`). `nil` for all other player queries, so the addition is backward-compatible
- **v1.1 API version support**: `Endpoint` now carries a `version` field (default `"v1"`) and transparently rewrites the trailing version segment of the base URL, so a single configured base URL can serve both v1 and v1.1 endpoints
- **`LeagueRecord.ties`**: added to support the live feed payload; decodes as `0` when the upstream API omits it, preserving compatibility with existing schedule payloads

### Fixed

- **Stats group routing**: `MLBStatGroup` now decodes `type`/`group` via `MLBDisplayName` instead of `MLBCodeDescription`, fixing pitching and fielding stats silently misrouting to batting against the live API (which omits the `code` field)

### Moved

- `LIVE_GAME_FEED_PLAN.md` relocated from repo root to `docs/LIVE_GAME_FEED_PLAN.md`

## [0.1.0] — 2026-03-13

### Added

- **Fluent query API** via `SwiftBaseball` enum namespace with chainable `QueryBuilder<T>`
- **Player endpoints**: search, lookup by ID, roster queries
- **Team endpoints**: team info, rosters, coaches
- **Schedule endpoint**: games by date, date range, team, or season
- **Game endpoints**: box scores, line scores, play-by-play with pitch data
- **Game log endpoint**: per-game stat lines for batting, pitching, and fielding
- **Stats endpoint**: season batting, pitching, and fielding statistics
- **Standings endpoint**: division, league, and wildcard standings
- **Leaders endpoint**: league leaders by stat category
- **Transactions endpoint**: trades, signings, and roster moves
- **Batch stats query**: concurrent multi-player stat fetching with `BatchStatsQuery`
- **Actor-based caching**: `CacheManager` with configurable TTL and `CachingAPIClient` wrapper
- **Rate limiter**: actor-based semaphore with FIFO waiter queue
- **Retry logic**: exponential back-off for 429 and 5xx responses
- **Cross-platform support**: macOS 13+, iOS 16+, tvOS 16+, watchOS 9+, Linux
- **Zero dependencies**: Foundation-only, no third-party libraries
- **Swift concurrency**: full async/await and Sendable compliance
- **194 tests** across 20 test suites
