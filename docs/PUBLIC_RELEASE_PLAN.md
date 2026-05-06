# SwiftBaseball — Public Release & API Coverage Plan

> Roadmap to take SwiftBaseball from its current `v0.1.x` pre-release state to a
> professional, publicly-consumable Swift package that provides **full coverage
> of the MLB Stats API and Baseball Savant** — the Swift analogue of pybaseball,
> scoped deliberately to these two data sources (no Baseball Reference, no
> FanGraphs, no Retrosheet, no Lahman DB).

**Authored:** 2026-04-21 · Target: `v1.0.0` GA.

> **Status:** All scoping questions resolved 2026-04-21 (see `docs/ANSWERS.md`).
> Decisions baked into this document — no open questions remain.

---

## 0. Scope & Non-Goals

### In scope
- **MLB Stats API** (`statsapi.mlb.com/api/v1/` + `/api/v1.1/`) — complete public-endpoint coverage.
- **Baseball Savant** (`baseballsavant.mlb.com`) — Statcast search CSV and every public leaderboard CSV.
- First-class Swift ergonomics: fluent API, `async/await`, strict-concurrency clean, `Sendable` throughout, cross-platform (Apple + Linux).
- DocC site, SemVer discipline, CI on macOS + Linux, source stability.

### Out of scope (explicitly)
- Baseball Reference scraping (blocked: ToS + brittle scraping).
- FanGraphs scraping or their private API.
- Retrosheet event files / Lahman SQLite database.
- Chadwick register (player ID crosswalks between external systems).
- Any feature requiring authentication / paid feeds (MLB Gameday Auth, BAM).
- Plotting/visualization helpers (pybaseball's `spraychart`, `plot_strike_zone`). UI is consumers' concern.
- Data science glue (DataFrame bridges). Consumers use Swift-native types.

---

## 1. Current State Audit (April 2026)

### Package
- Swift tools `6.0`, platforms macOS 14 / iOS 17 / tvOS 17 / watchOS 10 + Linux.
- 3 targets: `SwiftBaseball` (library), `CLISupport`, `baseball-cli` (executable demo).
- **Zero third-party dependencies** — Foundation-only.
- Released tag `v0.1.0` (2026-03-13). Unreleased section in `CHANGELOG.md` has platoon splits + pitching opponent rates.

### Coverage already shipped
**MLB Stats API:**
- People: search, single player, sabermetrics on a player.
- Teams: teams list (by sport/level), single team, affiliates, roster (all roster types + historical date).
- Schedule: by date, range, season + hydrations, sport-scoped.
- Games: boxscore, linescore, play-by-play (pitch-level), game highlights/content.
- Game log: per-game stats by group.
- Stats: season, career, year-by-year, projected, sabermetrics; team-wide season + sabermetrics; splits — home/away, day/night, monthly, runners-on, leverage, platoon (season + career).
- Standings (with league filter), leaders (batting + key pitching categories).
- Awards (list + recipients), draft, transactions, venues.
- Batch stats (concurrent fan-out by player IDs).

**Baseball Savant:**
- Statcast batted-ball aggregation for batters & pitchers (season / date range).
- Career split aggregation vs LHP / RHP.
- Batch variants for both.
- Leaderboards: sprint speed, OAA, catcher framing, catcher pop time.

### Infrastructure
- Actor-based `CacheManager` with TTL.
- `RateLimiter` (slot + `CheckedContinuation` FIFO waiters).
- Exponential-backoff retries for 429/5xx/network.
- `MockAPIClient` + JSON fixtures.
- **241 tests** (225 unit across 22 suites + 16 env-gated integration).
- GitHub Actions: build/test on macOS 14 and Ubuntu (Swift 5.9 + 6.0).

### Known deficits (independent of new-endpoint work)
- No DocC hosting (catalog exists but not published).
- No `.swiftlint.yml` or `.swiftformat` config checked in; style is implicit.
- No symbol-stability guarantees declared anywhere.
- `CHANGELOG.md` is short; no migration notes for the platoon + pitching-opponent-rate additions queued for unreleased.
- `LIVE_GAME_FEED_PLAN.md` at repo root — should move under `docs/` and reflect delivery status.
- No public issue templates, no `CONTRIBUTING.md`, no `CODE_OF_CONDUCT.md`.
- No release-engineering doc for tagging, Swift Package Index listing, or pre-1.0 API-freeze checklist.

---

## 2. pybaseball Parity Matrix (MLB Stats API + Savant only)

pybaseball is a superset; we only mirror the subset that can be served by the two allowed data sources. `✅` = shipped · `🟡` = partial · `❌` = missing · `🚫` = out of scope.

### MLB Stats API surface
| pybaseball / MLB Stats API concept | SwiftBaseball equivalent | Status |
|---|---|---|
| Player search / bio | `players(.search:)`, `player(id:)` | ✅ |
| Active roster / 40-man / non-roster / full-season / historical-date roster | `roster(...)` | ✅ |
| All teams (MLB + MiLB by sport) | `teams(.all(season:)).sport(_:)` | ✅ |
| Team affiliates | `affiliates(teamId:season:)` | ✅ |
| Schedule (date / range / season / hydrations) | `schedule(...)` | ✅ |
| Boxscore, linescore, play-by-play, highlights | `boxscore/linescore/playByPlay/gameHighlights` | ✅ |
| Game log | `gameLog(playerId:)` | ✅ |
| Season / career / year-by-year / projected / sabermetric stats | `playerStats` family | ✅ |
| Team-wide stats + sabermetrics | `teamStats`, `teamSabermetrics` | ✅ |
| Platoon / home-away / day-night / monthly / RISP / leverage / career platoon splits | `*Splits` endpoints | ✅ |
| Batch multi-player stats | `batchStats(_:group:)` | ✅ |
| Standings (+ league filter) | `standings(...)` | ✅ |
| League leaders (batting + core pitching categories) | `leaders(...)` | 🟡 — only a curated category set is wired into `LeaderStatCategory` |
| Transactions | `transactions()` | ✅ |
| Awards + recipients | `awards()`, `awardRecipients(awardId:)` | ✅ |
| Venues | `venues()`, `venue(id:)` | ✅ |
| Amateur draft | `draft(year:)` | ✅ |
| **Live game feed** (`v1.1/game/{pk}/feed/live`) | — | ❌ (plan exists) |
| **Win probability** (`game/{pk}/winProbability`) | — | ❌ |
| **Context metrics** (LI, WPA, cWPA) | — | ❌ |
| **Game timestamps / diff-patch** (incremental feeds) | — | ❌ |
| **Game color commentary** (`game/{pk}/color`) | — | ❌ |
| **Game pace** (`gamePace`) | — | ❌ |
| **Team leaders** (`teams/{id}/leaders` — single season) | — | ❌ |
| **Team stat leaders history** (`teams/{id}/stats/leaders`) | — | ❌ |
| **Team history / franchise** (`teams/history`) | — | ❌ |
| **Team alumni** (`teams/{id}/alumni`) | — | ❌ |
| **Team coaches** (`teams/{id}/coaches`) | — | ❌ |
| **Team personnel** (trainers, scouts) | — | ❌ |
| **Sport-wide player dump** (`sports/{id}/players`) | — | ❌ |
| **League metadata** (`leagues`, `leagues/{id}`) | — | ❌ |
| **Division metadata** (`divisions`, `divisions/{id}`) | — | ❌ |
| **Umpire assignments** (`jobs/umpires`) | — | ❌ |
| **Official scorers** (`jobs/officialScorers`) | — | ❌ |
| **Attendance** (`attendance`) | — | ❌ |
| **High-low splits** (`highLow/{orgType}`) | — | ❌ |
| **Home Run Derby** (bracket + pool) | — | ❌ |
| **Draft prospects** (`draft/prospects/{year}`) | — | ❌ |
| **Draft latest-in-progress** (`draft/{year}/latest`) | — | ❌ |
| Player hydrations catalog, stat-type / stat-group / stat-fields / sit-codes / pitch-codes / pitch-types / event-types / roster-types / standings-types / review-reasons / wind-directions metadata | — | ❌ — today we hard-code the enums consumers need |
| Postseason schedule & series | `schedule` works via gameType but no dedicated `schedule.postseason` path | 🟡 |

### Baseball Savant surface (Statcast)
| pybaseball function / Savant page | SwiftBaseball equivalent | Status |
|---|---|---|
| `statcast(start, end)` — raw pitch-level rows | — (we aggregate only) | ❌ |
| `statcast_batter(start, end, pid)` — pitch-level for one batter | aggregator form only | 🟡 |
| `statcast_pitcher(start, end, pid)` — pitch-level for one pitcher | aggregator form only | 🟡 |
| `statcast_single_game(gamepk)` | — | ❌ |
| Batted-ball profile aggregation (GB%/FB%/LD%/EV/barrel/xBA/xSLG/xwOBA) | `statcastBatting`, `statcastPitching` | ✅ |
| Career split vs LHP/RHP | `statcastCareerSplits` (+ batch) | ✅ |
| `statcast_sprint_speed` | `sprintSpeed()` | ✅ |
| `statcast_outs_above_average` | `outsAboveAverage()` | ✅ |
| `statcast_catcher_framing` | `catcherFraming()` | ✅ |
| `statcast_catcher_poptime` | `catcherPopTime()` | ✅ |
| `statcast_batter_expected_stats` / `statcast_pitcher_expected_stats` | — | ❌ |
| `statcast_batter_percentile_ranks` / `statcast_pitcher_percentile_ranks` | — | ❌ |
| `statcast_batter_exitvelo_barrels` / `statcast_pitcher_exitvelo_barrels` | — | ❌ |
| `statcast_pitcher_pitch_arsenal` (velo/spin per pitch) | — | ❌ |
| `statcast_pitcher_arsenal_stats` (per-pitch outcomes) | — | ❌ |
| `statcast_pitcher_pitch_movement` (IVB/HB) | — | ❌ |
| `statcast_pitcher_active_spin` | — | ❌ |
| `statcast_batter_pitch_arsenal` (vs each pitch type) | — | ❌ |
| `statcast_batter_bat_tracking` (bat speed, swing length — 2024+) | — | ❌ |
| `statcast_pitcher_bat_tracking` | — | ❌ |
| `statcast_running_splits` | — | ❌ |
| `statcast_outfield_catch_prob` | — | ❌ |
| `statcast_outfielder_jump` | — | ❌ |
| `statcast_fielding_run_value` | — | ❌ |
| `statcast_baserunning_value` (newer) | — | ❌ |
| Swing-take (run-value decomposition) | — | ❌ |
| Pitch-tilt leaderboard | — | ❌ |
| Umpire-scorecards / services | — | ❌ |
| `spraychart`, `plot_strike_zone` | — | 🚫 |
| pybaseball BREF / FanGraphs / Retrosheet / Lahman / Chadwick | — | 🚫 |

---

## 3. Coverage Gap Plan

Endpoints below are grouped by effort band. Each bullet names the public entry
point we will add on the `SwiftBaseball` namespace and the upstream source.

### 3.1 MLB Stats API — tranche A (high-value, owner-requested)

1. **Live game feed** — `/api/v1.1/game/{pk}/feed/live` + `diffPatch` + `timestamps`.
   - Entry: `liveFeed(gamePk:)`, `liveFeedChanges(gamePk:since:)`.
   - Model: `LiveGameFeed` (metadata + liveData.plays + liveData.linescore + gameData).
   - Use-case: a consumer building a real-time scoreboard / Gameday clone.
   - Already-scoped in `LIVE_GAME_FEED_PLAN.md` — absorb that plan here and execute.
2. **Win probability** — `/game/{pk}/winProbability` → `[WinProbability]` per at-bat.
3. **Context metrics** — `/game/{pk}/contextMetrics` → `ContextMetrics` (LI, WPA, cWPA).
4. **Game pace** — `/gamePace` → `GamePaceSeason` aggregated per season.
5. **Team coaches / alumni / personnel** — `teams/{id}/coaches`, `/alumni`, `/personnel`.
   Entries: `teamCoaches(teamId:season:)`, `teamAlumni(teamId:season:)`, `teamPersonnel(teamId:)`.
6. **Team leaders (in-season)** — `teams/{id}/leaders?leaderCategories=...`.
   Entry: `teamLeaders(teamId:category:season:)`.
7. **Umpire assignments** — `jobs/umpires?date=...`.
   Entry: `umpires(date:)`, `umpires(dateRange:)`.
8. **Attendance** — `/attendance?teamId=&season=`.
   Entry: `attendance(teamId:season:)`.
9. **League / division / sport metadata endpoints** — surface first-class getters (even though the enums are hard-coded today), so consumers can discover historical leagues (Negro Leagues, defunct independent leagues) that ship in the API.

### 3.2 MLB Stats API — tranche B (completeness)

10. **Sport-wide players** — `sports/{sportId}/players?season=` → bulk `[Player]`. Needed for minor-league roster aggregation.
11. **Team history / franchise** — `teams/history?teamIds=` → franchise-history rows.
12. **Team stat-leaders history** — `teams/{id}/stats/leaders`.
13. **High-low splits** — `highLow/player`, `highLow/team`.
14. **Home Run Derby** — bracket + pool endpoints (seasonal but part of MLB's canonical API). **Deferred:** path is `homeRunDerby/{gamePk}` per toddrob99's spec, but the derby `gamePk` is not surfaced via `schedule?gameTypes=` (no gameType code returns derby games) and probing gamePks adjacent to the All-Star Game returns "Game data couldn't be found." Will revisit if MLB adds a gameType for it or if the gamePk becomes discoverable through another endpoint.
15. **Postseason schedule** — ✅ `SwiftBaseball.postseasonSchedule(season:)` + `SwiftBaseball.postseasonSeries(season:)` shipped 2026-05-02.
16. **Draft prospects** — ✅ `SwiftBaseball.draftProspects(year:)` + `SwiftBaseball.draftLatest(year:)` shipped 2026-05-02.
17. **Official scorers** — ✅ `SwiftBaseball.officialScorers(date:)` shipped 2026-05-02.
18. **Play-by-play color commentary** — `game/{pk}/color` (text events with timestamps). **Deferred:** the upstream endpoint is documented as `game/{pk}/feed/color` (per toddrob99) but every gamePk probed (regular season, ASG, postseason finals) returns HTTP 404. Endpoint appears to be deprecated. Will revisit if MLB restores it.

### 3.3 MLB Stats API — tranche C (metadata catalogs) ✅ shipped 2026-05-05

Single umbrella namespace: `SwiftBaseball.meta.*`. Ships small typed structs for every
catalog endpoint. Not all consumers need these, but library completeness demands them:

- ✅ `meta.statTypes()`, `meta.statGroups()`, `meta.statFields()`, `meta.rosterTypes()`,
  `meta.gameTypes()`, `meta.standingsTypes()`, `meta.situationCodes()`,
  `meta.pitchTypes()`, `meta.pitchCodes()`, `meta.eventTypes()`, `meta.positions()`,
  `meta.leagueLeaderTypes()`, `meta.reviewReasons()`,
  `meta.hitTrajectories()`, `meta.logicalEvents()`, `meta.jobTypes()`, `meta.languages()`,
  `meta.baseballStats()` — 18 catalogs total
- **Deferred:** `meta.sitCodes()` and `meta.windDirections()` — both endpoints return HTTP 404 (deprecated upstream; the corresponding situation codes are exposed via `situationCodes()` instead)

### 3.4 Baseball Savant — tranche A (high-value)

1. **Raw Statcast rows** — expose pitch-level output without aggregation.
   - Entries: `statcastRaw(dateRange:)`, `statcastBatterRaw(playerId:dateRange:)`,
     `statcastPitcherRaw(playerId:dateRange:)`, `statcastGame(gamePk:)`.
   - Model: `StatcastPitch` — a strongly-typed struct for all ~100 CSV columns
     (pitch type, velo, spin, release, location, hit data, result, xMetrics, etc.).
   - Chunked internally to stay under the 25k-row cap — iterate by date slices
     and concatenate.
2. **Expected stats leaderboards** — `/leaderboard/expected_statistics?type=batter|pitcher`.
   Entries: `expectedStatsBatter(season:)`, `expectedStatsPitcher(season:)`.
3. **Percentile ranks** — `/leaderboard/percentile-rankings`.
   Entries: `percentileRanksBatter(season:)`, `percentileRanksPitcher(season:)`.
4. **Exit-velo / barrels leaderboard** — `/leaderboard/statcast` variants.
   Entries: `exitVeloBarrelsBatter(season:)`, `exitVeloBarrelsPitcher(season:)`.
5. **Pitch arsenal (velo/spin per pitch)** — `/leaderboard/pitch-arsenal`.
6. **Pitch arsenal stats (per-pitch outcomes)** — `/leaderboard/pitch-arsenal-stats`.
7. **Pitch movement (IVB/HB)** — `/leaderboard/pitch-movement`.

### 3.5 Baseball Savant — tranche B

8. **Active spin** — `/leaderboard/active-spin`.
9. **Running splits** (90ft splits) — `/leaderboard/running_splits`.
10. **Bat tracking** (2024+) — `/leaderboard/bat-tracking` (bat speed, swing length).
11. **Outfield catch probability** — `/leaderboard/outfield-catch-prob`.
12. **Outfielder jumps** — `/leaderboard/outfielder_jumps`.
13. **Fielding run value** — `/leaderboard/fielding-run-value`.
14. **Baserunning run value** — `/leaderboard/baserunning-value`.
15. **Swing / take** — `/leaderboard/swing-take`.
16. **Pitch tilt** — `/leaderboard/pitch-tilt`.

### 3.6 Baseball Savant — tranche C (nice-to-have)

17. **Umpire scorecards** — `/leaderboard/services`. Public but format drifts seasonally; keep behind an `ExperimentalAPI` availability marker.
18. **Statcast illustrator / animations** — skip: requires browser rendering.

---

## 4. Polish Plan (everything orthogonal to new endpoints)

### 4.1 API stability for v1.0

- Declare the `SwiftBaseball` namespace and every `public` symbol as the v1 contract.
- Audit for types that are public today but should not be once the crate goes 1.0:
  - `CodeDescription`, `SplitCode`, any raw-API helpers that leaked to `public`.
  - Mark those `@_spi(Internal) public` or move to `Internal/` before 1.0.
- Stand up a `SwiftBaseball/API.md` "public-symbol inventory" and a CI check
  that `jazzy` / `swift-symbolgraph-extract` output is stable between PRs.
- Add **`@available` markers** where behaviour differs by OS. Today all types
  use `TimeInterval`; if `Duration` is adopted we are covered by the iOS 17 floor.

### 4.2 Ergonomics

- **Consistency sweep** on fluent methods:
  - Every query accepts `.season(_:)`, `.dateRange(start:end:)`, `.gameType(_:)`
    where meaningful. Today `gameType` is a `String` in some places and a typed
    enum in others — standardize on `GameType` everywhere, accept `String`
    only as an escape hatch.
  - `Position`, `League`, `Sport`, `Division` already CaseIterable — audit
    every other user-facing enum for the same.
- **Date handling**: accept `Date` on every public method that currently takes
  `"YYYY-MM-DD"` strings, retaining the string overloads for backward compat.
  Under the hood continue to format with `en_US_POSIX`.
- **Pagination / streaming**: Savant raw Statcast can return 25k-row pages.
  Add `AsyncSequence` forms (`statcastPitches(dateRange:).stream()`) that
  auto-chunk date windows and yield `StatcastPitch` values one-at-a-time.
  Keeps memory bounded for multi-season pulls.
- **Typed stat categories**: expand `LeaderStatCategory` to the full
  `meta.leagueLeaderTypes` catalog. Currently it only covers the curated
  subset needed by 0.1.x demos.
- **Better errors**: convert `SwiftBaseballError.invalidResponse(statusCode:)`
  to carry the decoded MLB error envelope (`messageNumber`, `message`) when
  present — today the error drops context.

### 4.3 Concurrency / Sendable

- Turn on **`SWIFT_STRICT_CONCURRENCY=complete`** in `Package.swift`
  `swiftSettings` and clear the warning backlog. Today we build clean at
  `6.0` tools but strict-complete has not been asserted.
- Audit the `@unchecked Sendable` `State` wrapper on `SwiftBaseball` — the
  Swift-5.9 compat reason is no longer binding now that the package targets
  `swift-tools-version: 6.0`. Replace with an `actor` or a `Mutex`-guarded
  holder.

### 4.4 Testing

- **Raise target coverage** to 95% on Models + Networking (from today's
  "Models 100%, Networking/parsing 100%" per CLAUDE.md, which is aspirational
  and not measured in CI).
- Add **coverage report** to CI and publish to Codecov.
- **Contract tests** for every new endpoint: one fixture per happy path,
  one for an empty response, one for a malformed row, and one integration
  test gated on `SWIFTBASEBALL_INTEGRATION=1`.
- **Snapshot tests** for CSV parsing: pin a Savant fixture and assert
  column-for-column decoding.
- **Property-based tests** for stat-rate computations (`woba` derivation,
  etc.) using `swift-testing` parameterized tests.
- **CLI tests** — keep `InlineTableFormatter` mirror in sync; add golden-file
  diffing for the CLI commands.

### 4.5 Documentation

- **DocC site published** to GitHub Pages on every tag:
  - Add a `Deploy DocC` workflow that runs `swift package --allow-writing-to-directory ./docs-build generate-documentation --target SwiftBaseball --output-path ./docs-build --transform-for-static-hosting --hosting-base-path SwiftBaseball`.
  - Link from README badge.
- **DocC catalog expansion** — write articles for:
  - `GettingStarted.md` (install, first query).
  - `DataSources.md` (MLB Stats API vs Savant trade-offs, rate limits).
  - `Caching.md`, `RateLimiting.md`, `ErrorHandling.md`.
  - `MinorLeagues.md` (how sport scoping + roster types interact).
  - `Statcast.md` (aggregation vs raw, barrel definition, date-chunking).
  - `MigratingFrom_pybaseball.md` (cheat-sheet table).
- **Symbol coverage gate**: CI fails if any `public` symbol lacks a DocC `///` comment. (Today `swiftlint` can flag this; add the rule.)
- Move `LIVE_GAME_FEED_PLAN.md` into `docs/` and convert to a DocC article once shipped.
- Extend `README.md` "Comparison with pybaseball" table to reflect actual parity.

### 4.6 Tooling / style

- Check in `.swiftlint.yml` (rules: no `force_unwrapping`, `missing_docs`,
  `explicit_init`, `closure_body_length` reasonable) and `.swiftformat`.
- Add a `Makefile` or `Justfile` with targets: `make test`, `make lint`,
  `make docs`, `make integration`.
- Replace the hand-rolled `swiftBaseballVersion` constant with a
  generated-from-git version (build-plugin) — or at minimum assert in CI
  that the constant matches the latest git tag.

### 4.7 Release engineering

- Adopt **SemVer strictly**:
  - `0.x` for everything before the coverage work lands.
  - Cut `1.0.0-rc.1` when tranches 3.1 and 3.4 land + polish items 4.1–4.5.
  - `1.0.0` after one month of RC with no breaking feedback.
- **Swift Package Index** submission + badges in README.
- Signed git tags; release notes generated from `CHANGELOG.md`.
- Publish `git log`-style migration notes for every breaking change.

### 4.8 Governance

- `CONTRIBUTING.md` (fork → feature branch → test → PR), issue templates
  (`bug_report.yml`, `endpoint_request.yml`, `stat_decoding_bug.yml`),
  `CODE_OF_CONDUCT.md` (Contributor Covenant 2.1).
- `SECURITY.md` — mostly boilerplate, but add a note that MLB API errors
  or Savant HTML-error pages can leak internal paths; report privately.
- `MAINTAINERS.md` listing Joseph Kelly as sole maintainer, with the
  triage cadence.

---

## 5. Phased Roadmap

| Phase | Theme | Ships as | Time-box |
|---|---|---|---|
| **P6** | Release-readiness polish (§4.1–4.6) + close out Unreleased changelog | `0.2.0` | 2 weeks |
| **P7** | MLB Stats API tranche A (§3.1) — live feed, win prob, context metrics, coaches, team leaders, umpires, attendance | `0.3.0` | 3 weeks |
| **P8** | Savant tranche A (§3.4) — raw Statcast, expected stats, percentile ranks, exit-velo/barrels, pitch arsenal, pitch movement | `0.4.0` | 3 weeks |
| **P9** | MLB tranche B (§3.2) + Savant tranche B (§3.5) | `0.5.0` | 3 weeks |
| **P10** | Metadata catalogs (§3.3) + Savant tranche C (§3.6) + `AsyncSequence` streaming | `0.6.0` | 2 weeks |
| **P11** | API-freeze, final polish, migration guide, DocC site live, `1.0.0-rc.1` | `1.0.0-rc.1` | 1 week |
| **P12** | Bake period, bug-fix-only RCs | `1.0.0-rc.N` | 2–4 weeks |
| **P13** | **GA** | `1.0.0` | — |

Total: ~14 weeks of focused work.

---

## 6. Success Criteria for `1.0.0`

1. Every MLB Stats API public `v1`/`v1.1` endpoint listed in §2 has a typed entry point on `SwiftBaseball` (or an intentional "skipped — see §0") entry.
2. Every Savant CSV endpoint listed in §2 has a typed entry point.
3. `swift build -Xswiftc -strict-concurrency=complete` is clean on Linux and macOS.
4. DocC coverage gate passes: 100% of `public` symbols documented.
5. `>=95%` line coverage on `Sources/SwiftBaseball/` by Codecov.
6. CI matrix: macOS 14+15, Ubuntu 22.04 / 24.04, Swift 6.0 + 6.1 (language mode `.v6`).
7. Sub-200ms decode for every fixture in `Tests/Fixtures/`.
8. Swift Package Index health check shows all 4 Apple platforms + Linux green.
9. `CHANGELOG.md` records every public-API change since 0.1.0.
10. Tagged `1.0.0`, release notes published, README "Roadmap" section replaced by a stability statement.

---

## 7. Resolved Decisions Log (2026-04-21)

- **Rate-stat storage**: `Double`. `Decimal` is a money-precision tool; rate stats are presentation-rounded ratios derived from integer counts. Display precision is handled by formatters, not the storage type.
- **Date vs String**: `Date` is the primary public type. `String` (`"YYYY-MM-DD"`) convenience overloads ship alongside and are `@available(*, deprecated)` by `v1.1`.
- **Strict concurrency**: full Swift 6 language mode (`swiftLanguageModes: [.v6]`) on every target. Flag-gated opt-in is not used.
- **Platform floor (1.0)**: iOS 17 · iPadOS 17 (via `.iOS`) · macOS 14 · tvOS 17 · watchOS 10 · visionOS 1 · Linux. README, manifest, and CI matrix all align to this floor.
- **Raw Statcast model**: typed struct for every documented CSV column plus a `raw: [String: String]` escape hatch for unrecognized columns. Future-proofs against Savant adding columns mid-season.
- **Savant concurrency**: hard cap of 1 in-flight request. The existing single-permit `RateLimiter` is the 1.0 ceiling.
- **Live feed**: in scope for **P7** as nice-to-have; if it slips, it moves to a 1.1 "streaming" milestone without blocking 1.0.
- **Live-feed delivery model**: still to design *during* P7 — `diffPatch` polling wrapped in an `AsyncSequence` is the working proposal.
- **Repo ownership**: personal account `josephskelly/SwiftBaseball`. MIT license. DocC hosted on GitHub Pages of the same repo. SPI submission is a blocking 1.0 criterion.
- **Work cadence**: one PR per tranche/phase, small commits inside each PR.

### Items retained as follow-ups (non-blocking for 1.0 scoping)

- `Sport` enum expansion to Negro Leagues / Women's Pro / Independent / international amateur — reassess during P7 when `meta.leagues` lands.
- `SwiftBaseballLive` separate SPM product — only if measured watchOS binary size regresses once `LiveGameFeed` ships.

---

## 8. Appendix — pybaseball → SwiftBaseball cheat sheet (target state at `1.0.0`)

| pybaseball | SwiftBaseball |
|---|---|
| `playerid_lookup("Ohtani")` | `SwiftBaseball.players(.search("Ohtani")).fetch()` |
| `batting_stats(2024)` | `SwiftBaseball.leaders(.battingAverage).season(2024).limit(1000).fetch()` (or `teamStats` aggregated across teams) |
| `pitching_stats(2024)` | same with pitching categories |
| `standings(2024)` | `SwiftBaseball.standings(.season(2024)).fetch()` |
| `schedule_and_record(2024, "NYY")` | `SwiftBaseball.schedule(.season(2024)).teamId(147).fetch()` |
| `statcast("2024-07-01", "2024-07-31")` | `SwiftBaseball.statcastRaw(dateRange: .init(...)).fetch()` (post-P8) |
| `statcast_batter(...)` | `SwiftBaseball.statcastBatterRaw(playerId:dateRange:).fetch()` (post-P8) |
| `statcast_pitcher(...)` | `SwiftBaseball.statcastPitcherRaw(playerId:dateRange:).fetch()` (post-P8) |
| `statcast_single_game(gamepk)` | `SwiftBaseball.statcastGame(gamePk:).fetch()` (post-P8) |
| `statcast_sprint_speed(2024)` | `SwiftBaseball.sprintSpeed().season(2024).fetch()` |
| `statcast_outs_above_average(2024)` | `SwiftBaseball.outsAboveAverage().season(2024).fetch()` |
| `statcast_catcher_framing(2024)` | `SwiftBaseball.catcherFraming().season(2024).fetch()` |
| `statcast_catcher_poptime(2024)` | `SwiftBaseball.catcherPopTime().season(2024).fetch()` |
| `statcast_batter_expected_stats(2024)` | `SwiftBaseball.expectedStatsBatter(season: 2024).fetch()` (post-P8) |
| `statcast_pitcher_percentile_ranks(2024)` | `SwiftBaseball.percentileRanksPitcher(season: 2024).fetch()` (post-P8) |
| `statcast_pitcher_pitch_arsenal(2024)` | `SwiftBaseball.pitchArsenal(season: 2024).fetch()` (post-P8) |
| `statcast_pitcher_pitch_movement(2024)` | `SwiftBaseball.pitchMovement(season: 2024).fetch()` (post-P8) |
| `statcast_running_splits(2024)` | `SwiftBaseball.runningSplits(season: 2024).fetch()` (post-P9) |
| `statcast_batter_bat_tracking(2024)` | `SwiftBaseball.batTracking(season: 2024).fetch()` (post-P9) |
| `statcast_outfield_catch_prob(2024)` | `SwiftBaseball.outfieldCatchProbability(season: 2024).fetch()` (post-P9) |
| `statcast_fielding_run_value(2024)` | `SwiftBaseball.fieldingRunValue(season: 2024).fetch()` (post-P9) |
| pybaseball BREF / FanGraphs / Retrosheet / Lahman / Chadwick | 🚫 out of scope |

