# CLAUDE.md — SwiftBaseball Development Context

## Project Overview
Swift library for accessing MLB statistics via the MLB Stats API (statsapi.mlb.com).
Swift equivalent of Python's pybaseball. MIT licensed. Author: Joseph Kelly.

## Tech Stack
- Swift 5.9+ (targeting Swift 6 strict concurrency compliance)
- Swift Package Manager — no CocoaPods/Carthage
- Networking: URLSession with async/await (no third-party HTTP libraries)
- JSON decoding: Foundation JSONDecoder with Codable models
- Caching: custom actor-based cache (no third-party)
- Testing: Swift Testing framework (`@Test`, `#expect`) — NOT XCTest
- Platforms: macOS 13+, iOS 16+, tvOS 16+, watchOS 9+, Linux

## Project Structure
```
Sources/
  SwiftBaseball/           — Public fluent query API (SwiftBaseball.players(...).fetch())
    Core/                  — APIClient protocol, QueryBuilder, errors, configuration
    Models/                — Codable structs: Player, Team, Game, Stats, Standings
    Endpoints/             — Players, Teams, Schedule, Games, Stats, Standings, Leaders
    Cache/                 — Actor-based response cache with TTL
Tests/
  SwiftBaseballTests/      — Unit + integration tests
    Fixtures/              — Mock JSON responses from MLB Stats API
docs/                      — Implementation plan, API design notes
```

## Code Style
- Follow Swift API Design Guidelines — clarity at the point of use
- Fluent/chainable query API: `SwiftBaseball.stats(.batting).season(2024).fetch()`
- All public query methods are `async throws`
- Models are structs (value semantics), not classes
- All models conform to `Codable`, `Sendable`, `Equatable`
- Use `Date` internally, not date strings — convert at API boundaries
- Errors use typed `SwiftBaseballError` enum, not generic `Error`
- No force unwraps (`!`) in production code
- No third-party dependencies — Foundation only
- Idiomatic Swift

## Essential Commands
```
swift build                          # Build all targets
swift test                           # Run all tests
swift build --configuration release  # Release build
swift test --filter PlayerTests      # Run specific test suite
```

## Key Design Decisions
- `SwiftBaseball` is an enum namespace (not instantiated) — provides the fluent API
- `QueryBuilder<T>` is the generic builder that all fluent chains produce
- Internal `APIClient` protocol allows injecting mock HTTP responses in tests
- Raw MLB API response types are internal — public models are clean, stable structs
- MLB Stats API base URL: `https://statsapi.mlb.com/api/v1/`

## Testing
- Unit tests use mock HTTP client with JSON fixture files in `Tests/Fixtures/`
- Integration tests hit real MLB API — gated behind `SWIFTBASEBALL_INTEGRATION=1` env var
- Naming: `[Feature]Tests.swift` (e.g., `PlayerTests.swift`, `StandingsTests.swift`)
- Every endpoint gets fixture JSON captured from real API responses

## Data Source Gotchas
- MLB Stats API: free, no auth, but has undocumented rate limits
- API date format is `"YYYY-MM-DD"`
- Some API fields use empty string `""` instead of null — handle in custom decoding
- Player IDs differ across sources (MLB ID != FanGraphs ID != BREF ID)
- Use DateFormatter with en_US_POSIX
- Statcast (future): CSV format, ~90 columns, 25k row limit per query, aggressive rate limiting

## Documentation
- All public API must have DocC comments (`///`)
- Use `/// - Parameters:`, `/// - Returns:`, `/// - Throws:` format
- Cross-reference related types with double-backtick syntax: ``TypeName``
- Never use `//` for public-facing symbols
- Group related symbols using `/// - SeeAlso:`

## DocC Structure
- Articles go in `Sources/SwiftBaseball/Documentation.docc/`
- Top-level catalog file: `SwiftBaseball.md`
- Add new types to the Topics section in the catalog

## Testing
- Framework: Swift Testing (not XCTest) unless target is < iOS 16
- All public methods require unit tests before a PR is mergeable
- Test file naming: `{TypeName}Tests.swift` in `Tests/SwiftBaseballTests/`
- Aim for edge cases: empty responses, malformed JSON, network errors, 
  stat boundary values (0 PA, 162 G, .400 AVG etc.)
- Mock all network calls — never hit live MLB Stats API in tests
- Use `#expect` and `#require` macros, not `XCTAssert`
- Parameterized tests preferred for stat calculation coverage

## Test Coverage Targets
- Models: 100%
- Networking/parsing: 100%  
- Utilities: 90%+
- Run coverage: Product → Test (⌘U) with coverage enabled

## Test Structure (AAA)
- Arrange / Act / Assert pattern, separated by blank lines
- Each test tests exactly one behavior
- Test names: camelCase with `@Test` attribute (e.g., `@Test func fetchPlayerById()`)

## Mock Pattern
- Use protocol-based mocking:

    protocol HTTPClient {
        func data(for request: URLRequest) async throws -> (Data, URLResponse)
    }
    
    struct MockHTTPClient: HTTPClient { ... }

- Never use third-party mocking libraries.

## Project Management
- Use Plan mode with Claude
- Keep documentation up to date
- Build and test with comprehensive Unit Tests before every commit
- Always update the README.md, CLAUDE.md, and the implementation plan whenever applicable.
- Commit and push after after testing and updating the documentation.
