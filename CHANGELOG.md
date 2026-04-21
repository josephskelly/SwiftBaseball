# Changelog

All notable changes to SwiftBaseball will be documented in this file.

This project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

### Changed

- **Swift 6 language mode**: `Package.swift` now advertises `swiftLanguageModes: [.v6]`, asserting full strict-concurrency compliance for every target
- **Platform floor**: minimum supported platforms are now iOS 17 / iPadOS 17 / macOS 14 / tvOS 17 / watchOS 10 / visionOS 1 / Linux. Advertised platform claims in README, `CLAUDE.md`, and docs aligned to the manifest
- **`SwiftBaseball` state holder**: `@unchecked Sendable` now backed by real `NSLock` serialization for reads and writes instead of unsynchronized access, making `configure(_:)` safe under concurrent callers while preserving its synchronous signature

### Added

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
