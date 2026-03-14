# Changelog

All notable changes to SwiftBaseball will be documented in this file.

This project adheres to [Semantic Versioning](https://semver.org/).

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
