# SwiftBaseball Implementation Plan

## Vision

A comprehensive Swift library for MLB data access — the Swift equivalent of Python's pybaseball. Type-safe, async, protocol-oriented, with a fluent query API.

### Guiding Principles

1. **Zero third-party dependencies** — Foundation and URLSession only
2. **async/await throughout** — built on Swift concurrency
3. **Typed models over raw dictionaries** — every response is a Codable struct
4. **Protocol-oriented for testability** — mock any layer
5. **Fluent API** — chainable queries discoverable via autocomplete
6. **Cross-platform** — Apple platforms + Linux from day one

---

## Module Architecture

```
SwiftBaseball (umbrella — public fluent API)
├── Core
│   ├── APIClient protocol + URLSession implementation
│   ├── QueryBuilder<T> (generic fluent builder)
│   ├── Configuration
│   └── SwiftBaseballError
├── Models (shared Codable structs)
│   ├── Player, Team, Game, Venue
│   ├── BattingStats, PitchingStats, FieldingStats
│   ├── StandingsRecord, LeaderEntry
│   └── Enums: Position, HandSide, League, Division, GameType, StatGroup
├── Endpoints
│   ├── Players   — search, bio, roster lookups
│   ├── Teams     — team info, rosters, coaches
│   ├── Schedule  — games by date/team/season
│   ├── Games     — boxscore, linescore, play-by-play
│   ├── Stats     — batting, pitching, fielding aggregates
│   ├── Standings — division/league/wildcard
│   └── Leaders   — league leaders by stat category
└── Cache
    └── Actor-based response cache with configurable TTL
```

### Module Dependencies

```
SwiftBaseball (public API)
    │
    ├── Endpoints/* ──→ Core, Models
    │
    ├── Cache ──→ Core
    │
    ├── Models (leaf — no dependencies)
    │
    └── Core (leaf — Foundation only)
```

---

## Target Directory Structure

```
SwiftBaseball/
├── Package.swift
├── README.md
├── CLAUDE.md
├── LICENSE
├── .gitignore
├── Sources/
│   └── SwiftBaseball/
│       ├── SwiftBaseball.swift              — Public namespace enum, fluent entry points
│       ├── Core/
│       │   ├── APIClient.swift              — Protocol + URLSession implementation
│       │   ├── QueryBuilder.swift           — Generic fluent query builder
│       │   ├── Configuration.swift          — Library-wide settings
│       │   ├── SwiftBaseballError.swift      — Typed error enum
│       │   └── Endpoint.swift               — URL construction helpers
│       ├── Models/
│       │   ├── Player.swift
│       │   ├── Team.swift
│       │   ├── Game.swift
│       │   ├── Stats.swift                  — BattingStats, PitchingStats, FieldingStats
│       │   ├── Standings.swift
│       │   ├── Schedule.swift
│       │   ├── Leaders.swift
│       │   ├── Venue.swift
│       │   ├── Enums.swift                  — Position, HandSide, League, Division, etc.
│       │   └── References.swift             — Lightweight nested refs (TeamRef, LeagueRef)
│       ├── Endpoints/
│       │   ├── PlayersEndpoint.swift
│       │   ├── TeamsEndpoint.swift
│       │   ├── ScheduleEndpoint.swift
│       │   ├── GamesEndpoint.swift
│       │   ├── StatsEndpoint.swift
│       │   ├── StandingsEndpoint.swift
│       │   └── LeadersEndpoint.swift
│       ├── Cache/
│       │   └── CacheManager.swift           — Actor with TTL and LRU eviction
│       └── Internal/
│           ├── MLBAPIResponses.swift         — Raw Codable types mirroring MLB API JSON
│           └── MLBResponseConverters.swift   — Internal → public model converters
├── Tests/
│   └── SwiftBaseballTests/
│       ├── Fixtures/
│       │   ├── player_660271.json           — Ohtani player response
│       │   ├── player_search_ohtani.json
│       │   ├── teams_2024.json
│       │   ├── schedule_2024_07_04.json
│       │   ├── standings_2024_al.json
│       │   ├── game_boxscore.json
│       │   └── stats_batting_2024.json
│       ├── Mocks/
│       │   └── MockAPIClient.swift          — Mock HTTP client for unit tests
│       ├── PlayerTests.swift
│       ├── TeamTests.swift
│       ├── ScheduleTests.swift
│       ├── GameTests.swift
│       ├── StatsTests.swift
│       ├── StandingsTests.swift
│       ├── LeaderTests.swift
│       ├── QueryBuilderTests.swift
│       ├── CacheTests.swift
│       └── IntegrationTests/
│           └── MLBAPIIntegrationTests.swift  — Real API calls (env-gated)
└── docs/
    └── IMPLEMENTATION_PLAN.md
```

---

## Phase 1 — Foundation

**Goal**: Package.swift compiles, core types defined, networking layer functional, query builder works.

### 1.1 Package.swift

```swift
// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "SwiftBaseball",
    platforms: [.macOS(.v13), .iOS(.v16), .tvOS(.v16), .watchOS(.v9)],
    products: [
        .library(name: "SwiftBaseball", targets: ["SwiftBaseball"])
    ],
    targets: [
        .target(name: "SwiftBaseball"),
        .testTarget(
            name: "SwiftBaseballTests",
            dependencies: ["SwiftBaseball"],
            resources: [.copy("Fixtures")]
        )
    ]
)
```

Single target to start — internal module separation via directories, not SPM targets. This keeps the dependency graph simple and avoids import boilerplate. Can split into separate targets later if needed.

### 1.2 Core Types

**APIClient protocol** — abstracts HTTP for testability:
```swift
public protocol APIClient: Sendable {
    func fetch<T: Decodable>(_ endpoint: Endpoint) async throws -> T
    func fetchRaw(_ endpoint: Endpoint) async throws -> Data
}
```

**URLSessionAPIClient** — production implementation:
```swift
struct URLSessionAPIClient: APIClient {
    let session: URLSession
    let baseURL: URL
    let decoder: JSONDecoder
    // Handles: request construction, response validation, JSON decoding, error mapping
}
```

**QueryBuilder\<T\>** — the fluent chain that every query produces:
```swift
public struct QueryBuilder<T: Decodable & Sendable>: Sendable {
    // Internal state accumulated by fluent methods
    var endpoint: Endpoint
    var parameters: [String: String]

    // Terminal operation — executes the query
    public func fetch() async throws -> T

    // Chainable modifiers (available on specific T types via constrained extensions)
    public func season(_ year: Int) -> QueryBuilder<T>
    public func team(_ abbreviation: String) -> QueryBuilder<T>
    public func league(_ league: League) -> QueryBuilder<T>
    public func dateRange(start: String, end: String) -> QueryBuilder<T>
    public func limit(_ count: Int) -> QueryBuilder<T>
}
```

**SwiftBaseballError** — typed error enum:
```swift
public enum SwiftBaseballError: Error, Sendable {
    case networkError(URLError)
    case decodingError(DecodingError)
    case invalidDateRange(start: String, end: String)
    case playerNotFound(String)
    case rateLimited(retryAfter: TimeInterval?)
    case invalidResponse(statusCode: Int)
    case configurationError(String)
}
```

**Configuration**:
```swift
public struct Configuration: Sendable {
    public var cacheEnabled: Bool = false
    public var cacheTTL: TimeInterval = 3600
    public var maxConcurrentRequests: Int = 5
    public var userAgent: String = "SwiftBaseball/0.1.0"
}
```

### 1.3 Models

All models are structs conforming to `Codable, Sendable, Equatable, Identifiable` (where applicable).

**Player**:
```swift
public struct Player: Codable, Sendable, Equatable, Identifiable {
    public let id: Int
    public let fullName: String
    public let firstName: String
    public let lastName: String
    public let primaryPosition: Position
    public let birthDate: Date?
    public let batSide: HandSide
    public let pitchHand: HandSide
    public let active: Bool
    public let currentTeam: TeamReference?
}
```

**Team**:
```swift
public struct Team: Codable, Sendable, Equatable, Identifiable {
    public let id: Int
    public let name: String
    public let abbreviation: String
    public let teamName: String
    public let locationName: String
    public let league: LeagueReference
    public let division: DivisionReference
    public let venue: VenueReference
    public let active: Bool
}
```

Additional models: `Game`, `BattingStats`, `PitchingStats`, `StandingsRecord`, `LeaderEntry`, `ScheduleEntry`, `Boxscore`, `Linescore`, and supporting enums (`Position`, `HandSide`, `League`, `Division`, `GameType`, `StatGroup`).

### 1.4 Testing Foundation

- `MockAPIClient` conforming to `APIClient` — returns fixture data
- JSON fixtures captured from real MLB Stats API responses
- Swift Testing framework (`@Test`, `#expect`)
- `swift test` passes with initial model decoding tests

### Phase 1 Deliverables

- [ ] `Package.swift` compiles with `swift build`
- [ ] All core model structs defined with Codable conformance
- [ ] `APIClient` protocol and `URLSessionAPIClient` implementation
- [ ] `QueryBuilder<T>` fluent builder with `.fetch()` terminal
- [ ] `SwiftBaseballError` covers all expected error cases
- [ ] `MockAPIClient` + JSON fixtures for testing
- [ ] `swift test` passes with model decode round-trip tests

---

## Phase 2 — Player & Team Data

**Goal**: First real MLB Stats API integration. Players and teams fully queryable.

### MLB Stats API Endpoints Used

| Endpoint | URL Pattern | Returns |
|---|---|---|
| Player search | `/api/v1/people/search?names={name}` | `[Player]` |
| Player by ID | `/api/v1/people/{id}` | `Player` |
| All teams | `/api/v1/teams?sportId=1&season={year}` | `[Team]` |
| Team by ID | `/api/v1/teams/{id}` | `Team` |
| Team roster | `/api/v1/teams/{id}/roster?season={year}` | `[RosterEntry]` |

### Fluent API Surface

```swift
// Player queries
let players = try await SwiftBaseball.players(.search("Ohtani")).fetch()        // [Player]
let player  = try await SwiftBaseball.player(id: 660271).fetch()               // Player

// Team queries
let teams  = try await SwiftBaseball.teams(.season(2024)).fetch()              // [Team]
let team   = try await SwiftBaseball.team(id: 147).fetch()                    // Team (NYY)
let roster = try await SwiftBaseball.teams(.roster(teamId: 147)).season(2024).fetch()  // [RosterEntry]
```

### Internal Architecture

Each endpoint module contains:
1. **Endpoint definitions** — URL paths and parameter mapping
2. **Raw response types** — `internal` Codable structs mirroring exact MLB API JSON
3. **Converters** — transform raw responses into public model types

This two-layer approach insulates the public API from MLB Stats API JSON changes.

### Phase 2 Deliverables

- [ ] Player search by name (fuzzy)
- [ ] Player lookup by MLB ID
- [ ] Team listing by season
- [ ] Team detail by ID
- [ ] Team roster by season
- [ ] JSON fixtures for all endpoints
- [ ] Unit tests with >90% coverage on endpoint module

---

## Phase 3 — Game Data & Schedules

**Goal**: Query game schedules, box scores, and line scores.

### MLB Stats API Endpoints Used

| Endpoint | URL Pattern | Returns |
|---|---|---|
| Schedule | `/api/v1/schedule?sportId=1&date={date}&season={year}&teamId={id}` | `[ScheduleEntry]` |
| Game feed | `/api/v1/game/{gamePk}/feed/live` | `GameDetail` |
| Box score | `/api/v1/game/{gamePk}/boxscore` | `Boxscore` |
| Line score | `/api/v1/game/{gamePk}/linescore` | `Linescore` |

### Fluent API Surface

```swift
// Schedule queries
let games = try await SwiftBaseball.schedule(.date("2024-07-04")).fetch()           // [ScheduleEntry]
let season = try await SwiftBaseball.schedule(.season(2024)).team("NYY").fetch()    // [ScheduleEntry]

// Game detail
let box  = try await SwiftBaseball.game(gamePk: 745612).boxscore().fetch()         // Boxscore
let line = try await SwiftBaseball.game(gamePk: 745612).linescore().fetch()        // Linescore
```

### Key Models

**ScheduleEntry**: date, home/away teams, score, status, venue, game PK
**Boxscore**: team batting/pitching lines, individual player lines
**Linescore**: inning-by-inning runs/hits/errors

### Phase 3 Deliverables

- [ ] Schedule query by date, date range, season, team
- [ ] Box score retrieval by game PK
- [ ] Line score retrieval by game PK
- [ ] JSON fixtures for schedule and game endpoints
- [ ] Unit tests covering all game data paths

---

## Phase 4 — Statistics, Standings & Leaders

**Goal**: Full statistical querying — the core value proposition matching pybaseball.

### MLB Stats API Endpoints Used

| Endpoint | URL Pattern | Returns |
|---|---|---|
| Player stats | `/api/v1/people/{id}/stats?stats=season&season={year}&group={group}` | `PlayerStats` |
| Team stats | `/api/v1/teams/{id}/stats?stats=season&season={year}&group={group}` | `TeamStats` |
| Standings | `/api/v1/standings?leagueId={id}&season={year}` | `[StandingsRecord]` |
| League leaders | `/api/v1/stats/leaders?leaderCategories={cat}&season={year}&limit={n}` | `[LeaderEntry]` |

### Fluent API Surface

```swift
// Batting & pitching stats
let batting = try await SwiftBaseball
    .stats(.batting)
    .season(2024)
    .team("NYY")
    .fetch()  // [PlayerBattingStats]

let pitching = try await SwiftBaseball
    .stats(.pitching)
    .season(2024)
    .fetch()  // [PlayerPitchingStats]

// Individual player stats
let ohtaniStats = try await SwiftBaseball
    .playerStats(id: 660271)
    .season(2024)
    .group(.batting)
    .fetch()  // PlayerSeasonStats

// Standings
let alEast = try await SwiftBaseball
    .standings(.season(2024))
    .league(.american)
    .fetch()  // [StandingsRecord]

// League leaders
let hrLeaders = try await SwiftBaseball
    .leaders(.homeRuns)
    .season(2024)
    .limit(10)
    .fetch()  // [LeaderEntry]
```

### Key Models

**PlayerBattingStats**: games, PA, AB, R, H, 2B, 3B, HR, RBI, SB, BB, SO, BA, OBP, SLG, OPS
**PlayerPitchingStats**: W, L, ERA, G, GS, SV, IP, H, R, ER, BB, SO, WHIP, AVG
**StandingsRecord**: team, W, L, pct, GB, division rank, wildcard rank, streak, L10
**LeaderEntry**: player, team, stat value, rank

### Phase 4 Deliverables

- [ ] Season batting/pitching stats by team or league-wide
- [ ] Individual player season stats
- [ ] Division/league standings
- [ ] League leaders by category
- [ ] JSON fixtures for all stat endpoints
- [ ] Unit tests with comprehensive stat decoding validation

---

## Phase 5 — Polish & Advanced Features

**Goal**: Production-ready quality. Caching, performance, documentation, CI/CD.

### 5.1 Actor-Based Caching

```swift
public actor CacheManager {
    func get<T: Codable & Sendable>(key: String) -> T?
    func set<T: Codable & Sendable>(key: String, value: T, ttl: TimeInterval)
    func invalidate(key: String)
    func purgeAll()
}
```

- In-memory LRU cache for hot data
- Configurable TTL per query type (standings = 5 min, historical stats = 24 hr)
- Enabled via `SwiftBaseball.configure(.init(cacheEnabled: true))`

### 5.2 Batch Queries

```swift
// Fetch stats for multiple players concurrently
let stats = try await SwiftBaseball
    .stats(.batting)
    .players([660271, 592450, 665487])
    .season(2024)
    .fetch()  // [PlayerBattingStats]
```

Uses `TaskGroup` for concurrent fetching with rate limit awareness.

### 5.3 Rate Limiting & Retry

- Token bucket rate limiter (actor-based)
- Exponential backoff for transient failures
- Configurable via `Configuration.maxConcurrentRequests`

### 5.4 Documentation

- DocC documentation catalog with tutorials
- Inline documentation comments on all public API
- Usage examples for common workflows

### 5.5 CI/CD

- GitHub Actions workflow: build + test on macOS and Linux
- Swift 5.9 and 6.0 matrix
- Automated test runs on PR

### 5.6 Optional: CLI Tool

```swift
// Package.swift addition:
.executableTarget(name: "baseball-cli", dependencies: ["SwiftBaseball"])
```

```
$ swift run baseball-cli players search "Ohtani"
$ swift run baseball-cli standings --season 2024 --league AL
$ swift run baseball-cli stats batting --season 2024 --team NYY --limit 10
```

### Phase 5 Deliverables

- [ ] Actor-based caching with TTL
- [ ] Batch query support via TaskGroup
- [ ] Rate limiter with exponential backoff
- [ ] DocC documentation catalog
- [ ] GitHub Actions CI (macOS + Linux)
- [ ] Optional CLI tool
- [ ] Example project or Swift Playground

---

## Testing Strategy

| Layer | Approach | Fixtures |
|---|---|---|
| Models | Codable round-trip decoding | JSON files from real API |
| QueryBuilder | Verify URL/parameter construction | None (unit logic) |
| Endpoints | Mock APIClient returns fixture data | JSON per endpoint |
| Cache | Actor isolation, TTL expiry, LRU eviction | Synthetic data |
| Integration | Real MLB Stats API calls (env-gated) | Live responses |

### Running Tests

```bash
swift test                                      # All unit tests
swift test --filter PlayerTests                 # Specific suite
SWIFTBASEBALL_INTEGRATION=1 swift test          # Include integration tests
```

---

## MLB Stats API Reference

Base URL: `https://statsapi.mlb.com/api/v1`

| Category | Key Endpoints |
|---|---|
| People | `/people/{id}`, `/people/search?names=` |
| Teams | `/teams?sportId=1`, `/teams/{id}`, `/teams/{id}/roster` |
| Schedule | `/schedule?sportId=1&date=&season=&teamId=` |
| Game | `/game/{gamePk}/feed/live`, `/game/{gamePk}/boxscore`, `/game/{gamePk}/linescore` |
| Stats | `/people/{id}/stats?stats=season&group=hitting&season=` |
| Standings | `/standings?leagueId=&season=&standingsTypes=regularSeason` |
| Leaders | `/stats/leaders?leaderCategories=&season=&limit=` |
| Meta | `/statGroups`, `/statTypes`, `/leagueLeaderTypes`, `/positions`, `/gameTypes` |

No authentication required. JSON responses. Date format: `YYYY-MM-DD`.

---

## Future Data Sources (Post-v1.0)

These are not in scope for the initial release but are part of the long-term vision:

| Source | Integration Type | Complexity | Value |
|---|---|---|---|
| **Statcast / Baseball Savant** | CSV download + parsing | High (90 columns, 25k limit, rate limiting) | Very high |
| **Baseball Reference** | HTML scraping | Medium (table extraction) | High |
| **FanGraphs** | HTML scraping / undocumented JSON API | Medium | High |
| **Lahman Database** | CSV/SQLite download | Low | Medium |

Each future source would add a new internal data provider conforming to the same protocols, keeping the public fluent API consistent.

---

## Risk Mitigation

| Risk | Mitigation |
|---|---|
| MLB Stats API rate limiting | Token bucket rate limiter, exponential backoff, request queuing |
| API response format changes | Internal raw response types + converters insulate public models |
| Large response payloads | Pagination support, streaming where possible |
| Swift 6 strict concurrency | All types `Sendable` from day one, actors for mutable state |
| Linux compatibility | Avoid Apple-only APIs, test on Linux in CI |
| Date handling across platforms | ISO8601DateFormatter only, no locale-dependent formatting |
