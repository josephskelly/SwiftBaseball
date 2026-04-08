# Live Game Feed — Implementation Plan

**Endpoint:** `GET /v1.1/game/{gamePk}/feed/live`
**Public API:** `SwiftBaseball.liveGameFeed(gamePk:).fetch()`

---

## Overview

The live game feed is MLB's canonical real-time game state endpoint. A single call returns a
composite payload covering everything: game metadata, current play, all prior plays, linescore,
boxscore, and decisions. It is the same feed the MLB app polls during games.

Notable differences from all existing endpoints:
- Uses **`/api/v1.1/`** (not `/api/v1/`) — the base URL handling must account for this.
- The response is large (~500 KB mid-game). Model design should be selective.
- Designed for **polling** — clients call it every few seconds during live games. Rate limiting
  matters.

---

## MLB API Response Shape

```
MLBLiveGameFeedResponse
├── gamePk: Int
├── metaData
│   ├── wait: Int                  — recommended polling interval in seconds
│   └── timeStamp: String          — e.g. "20240715_223456"
├── gameData
│   ├── game
│   │   ├── pk: Int
│   │   ├── type: String           — "R", "P", "S", "W", "L", "D"
│   │   ├── doubleHeader: String
│   │   ├── season: String
│   │   └── seasonDisplay: String
│   ├── datetime
│   │   ├── dateTime: String       — ISO8601
│   │   ├── originalDate: String   — "YYYY-MM-DD"
│   │   ├── dayNight: String       — "day" | "night"
│   │   ├── time: String           — "7:10"
│   │   └── ampm: String
│   ├── status
│   │   ├── abstractGameState: String  — "Preview" | "Live" | "Final"
│   │   ├── codedGameState: String
│   │   ├── detailedState: String      — "Scheduled" | "In Progress" | "Final" | "Postponed" …
│   │   ├── statusCode: String
│   │   ├── startTimeTBD: Bool
│   │   └── abstractGameCode: String
│   ├── teams
│   │   ├── away: { team: MLBEntityRef, leagueRecord: MLBRecord, score: Int? }
│   │   └── home: { team: MLBEntityRef, leagueRecord: MLBRecord, score: Int? }
│   ├── players: [String: MLBLivePlayer]   — keyed "ID{id}"
│   ├── venue: MLBEntityRef
│   ├── weather
│   │   ├── condition: String
│   │   ├── temp: String           — "72"
│   │   └── wind: String           — "10 mph, Out to CF"
│   ├── gameInfo
│   │   ├── attendance: Int?
│   │   ├── firstPitch: String?    — ISO8601 or time string
│   │   └── gameDurationMinutes: Int?
│   ├── flags
│   │   ├── noHitter: Bool
│   │   └── perfectGame: Bool
│   └── probablePitchers
│       ├── away: MLBEntityRef?
│       └── home: MLBEntityRef?
└── liveData
    ├── plays
    │   ├── allPlays: [MLBPlay]        — reuse existing MLBPlay type
    │   ├── currentPlay: MLBPlay?
    │   ├── scoringPlays: [Int]
    │   └── playsByInning: [MLBInningPlays]
    ├── linescore: MLBLinescore        — already decoded; can reuse Linescore model
    ├── boxscore: MLBBoxscoreResponse  — already decoded; can reuse Boxscore model
    └── decisions
        ├── winner: MLBEntityRef?
        ├── loser: MLBEntityRef?
        └── save: MLBEntityRef?
```

---

## Public Model Design

### Core type

```swift
/// Complete live game state returned by the MLB live game feed.
public struct LiveGameFeed: Codable, Sendable, Equatable {
    public let gamePk: Int
    public let meta: LiveFeedMeta
    public let gameData: LiveGameData
    public let liveData: LiveData
}
```

### Meta

```swift
public struct LiveFeedMeta: Codable, Sendable, Equatable {
    /// Recommended polling interval in seconds.
    public let wait: Int
    /// Server-side timestamp of this snapshot.
    public let timeStamp: String
}
```

### GameData subtypes

```swift
public struct LiveGameData: Codable, Sendable, Equatable {
    public let game: LiveGameInfo
    public let datetime: LiveGameDatetime
    public let status: GameStatus
    public let teams: LiveGameTeams
    /// All players participating in the game, keyed by MLB player ID.
    public let players: [Int: LivePlayer]
    public let venue: VenueReference
    public let weather: GameWeather?
    public let gameInfo: GameInfo?
    public let flags: GameFlags
    public let probablePitchers: ProbablePitchers
}

public struct LiveGameInfo: Codable, Sendable, Equatable {
    public let pk: Int
    public let type: GameType
    public let doubleHeader: String
    public let season: String
}

public struct LiveGameDatetime: Codable, Sendable, Equatable {
    /// Scheduled start time (UTC).
    public let dateTime: Date?
    public let originalDate: Date
    public let dayNight: DayNight
    public let time: String
    public let ampm: String
}

/// Whether a game is scheduled during the day or at night.
public enum DayNight: String, Codable, Sendable, Equatable {
    case day
    case night
    case unknown
}

/// High-level game state.
public struct GameStatus: Codable, Sendable, Equatable {
    public let abstractGameState: AbstractGameState
    public let detailedState: String
    public let statusCode: String
    public let startTimeTBD: Bool
}

/// Coarse game lifecycle phase.
public enum AbstractGameState: String, Codable, Sendable, Equatable {
    case preview  = "Preview"
    case live     = "Live"
    case final    = "Final"
}

public struct LiveGameTeams: Codable, Sendable, Equatable {
    public let away: LiveGameTeamData
    public let home: LiveGameTeamData
}

public struct LiveGameTeamData: Codable, Sendable, Equatable {
    public let team: TeamReference
    public let leagueRecord: LeagueRecord
    /// Current score. `nil` before the game starts.
    public let score: Int?
}

public struct LeagueRecord: Codable, Sendable, Equatable {
    public let wins: Int
    public let losses: Int
    public let pct: String
}

/// A player as listed in the game's roster.
public struct LivePlayer: Codable, Sendable, Equatable {
    public let id: Int
    public let fullName: String
    public let primaryNumber: String?
    public let currentAge: Int?
    public let primaryPosition: Position
    public let batSide: HandSide
    public let pitchHand: HandSide
}

public struct GameWeather: Codable, Sendable, Equatable {
    public let condition: String
    /// Temperature in Fahrenheit.
    public let temp: String
    public let wind: String
}

public struct GameInfo: Codable, Sendable, Equatable {
    public let attendance: Int?
    public let firstPitch: String?
    public let gameDurationMinutes: Int?
}

public struct GameFlags: Codable, Sendable, Equatable {
    public let noHitter: Bool
    public let perfectGame: Bool
}

public struct ProbablePitchers: Codable, Sendable, Equatable {
    public let away: PlayerReference?
    public let home: PlayerReference?
}
```

### LiveData subtypes

```swift
public struct LiveData: Codable, Sendable, Equatable {
    public let plays: LivePlays
    public let linescore: Linescore       // reuse existing type
    public let boxscore: Boxscore         // reuse existing type
    public let decisions: GameDecisions?
}

public struct LivePlays: Codable, Sendable, Equatable {
    public let allPlays: [Play]           // reuse existing Play type
    public let currentPlay: Play?
    public let scoringPlays: [Int]
    public let playsByInning: [InningPlays]
}

public struct InningPlays: Codable, Sendable, Equatable {
    public let inning: Int
    public let top: [Int]                 // indices into allPlays
    public let bottom: [Int]
}

public struct GameDecisions: Codable, Sendable, Equatable {
    public let winner: PlayerReference?
    public let loser: PlayerReference?
    public let save: PlayerReference?
}
```

---

## Internal Response Types

Add to `MLBAPIResponses.swift`:

```swift
struct MLBLiveGameFeedResponse: Decodable {
    let gamePk: Int
    let metaData: MLBLiveFeedMeta
    let gameData: MLBLiveGameData
    let liveData: MLBLiveData
}

struct MLBLiveFeedMeta: Decodable {
    let wait: Int
    let timeStamp: String
}

struct MLBLiveGameData: Decodable {
    let game: MLBLiveGameInfo
    let datetime: MLBLiveGameDatetime
    let status: MLBGameStatus
    let teams: MLBLiveTeams
    let players: [String: MLBLivePlayer]   // keys are "ID{playerId}"
    let venue: MLBEntityRef
    let weather: MLBGameWeather?
    let gameInfo: MLBGameInfo?
    let flags: MLBGameFlags
    let probablePitchers: MLBProbablePitchers
}

// ... (full declarations for each nested struct)

struct MLBLiveData: Decodable {
    let plays: MLBLivePlays
    let linescore: MLBLinescore             // already exists
    let boxscore: MLBBoxscoreResponse       // already exists
    let decisions: MLBGameDecisions?
}

struct MLBLivePlays: Decodable {
    let allPlays: [MLBPlay]                 // already exists
    let currentPlay: MLBPlay?
    let scoringPlays: [Int]
    let playsByInning: [MLBInningPlays]
}

struct MLBInningPlays: Decodable {
    let inning: Int
    let top: [Int]
    let bottom: [Int]
}
```

### Player dictionary key decoding

The `players` dictionary is keyed `"ID{id}"` (e.g., `"ID660271"`). Decode it as
`[String: MLBLivePlayer]` and strip the `"ID"` prefix during conversion.

---

## File Changes

| File | Change |
|------|--------|
| `Sources/SwiftBaseball/Models/LiveGameFeed.swift` | **New** — all public model types listed above |
| `Sources/SwiftBaseball/Internal/MLBAPIResponses.swift` | **Add** `MLBLiveGameFeedResponse` and subtypes |
| `Sources/SwiftBaseball/Internal/MLBResponseConverters.swift` | **Add** `liveGameFeed(from:)` converter |
| `Sources/SwiftBaseball/Endpoints/LiveGameFeedEndpoint.swift` | **New** — `QueryBuilder<LiveGameFeed>` factory |
| `Sources/SwiftBaseball/Core/Endpoint.swift` | **Check** v1.1 path support (see below) |
| `Sources/SwiftBaseball/SwiftBaseball.swift` | **Add** `liveGameFeed(gamePk:)` static method |
| `Tests/SwiftBaseballTests/Fixtures/live_game_feed_745612.json` | **New** — captured fixture |
| `Tests/SwiftBaseballTests/LiveGameFeedTests.swift` | **New** — unit tests |
| `README.md` | **Update** — document new endpoint |
| `TODO.md` | **Update** |

---

## v1.1 Base Path

The live feed uses `/api/v1.1/game/{gamePk}/feed/live`, not `/api/v1/`.

**Option A (preferred):** Add a `version` field to `Endpoint` (default `"v1"`). The live feed
endpoint passes `version: "v1.1"`. `Endpoint.url(baseURL:)` uses the version when constructing the
URL.

**Option B:** Hardcode the full path in the live feed endpoint and bypass `Endpoint` path
construction. Simpler but inconsistent.

Go with Option A — it keeps the door open for other v1.1 endpoints without hacks.

---

## Endpoint Definition

```swift
// LiveGameFeedEndpoint.swift
extension QueryBuilder where T == LiveGameFeed {
    static func liveGameFeed(gamePk: Int, client: any APIClient) -> QueryBuilder<LiveGameFeed> {
        let endpoint = Endpoint(path: "game/\(gamePk)/feed/live", version: "v1.1")
        return QueryBuilder(endpoint: endpoint, client: client) { data in
            let response = try JSONDecoder.mlb.decode(MLBLiveGameFeedResponse.self, from: data)
            return MLBResponseConverters.liveGameFeed(from: response)
        }
    }
}
```

---

## Converter Sketch

```swift
// MLBResponseConverters.swift additions
static func liveGameFeed(from response: MLBLiveGameFeedResponse) -> LiveGameFeed {
    LiveGameFeed(
        gamePk: response.gamePk,
        meta: liveFeedMeta(from: response.metaData),
        gameData: liveGameData(from: response.gameData),
        liveData: liveData(from: response.liveData)
    )
}

private static func liveGameData(from raw: MLBLiveGameData) -> LiveGameData {
    // strip "ID" prefix from player dictionary keys, convert each player
    let players: [Int: LivePlayer] = Dictionary(
        uniqueKeysWithValues: raw.players.compactMap { key, value -> (Int, LivePlayer)? in
            guard let id = Int(key.dropFirst(2)) else { return nil }
            return (id, livePlayer(from: value))
        }
    )
    return LiveGameData(
        game: liveGameInfo(from: raw.game),
        datetime: liveGameDatetime(from: raw.datetime),
        status: gameStatus(from: raw.status),
        teams: liveGameTeams(from: raw.teams),
        players: players,
        venue: VenueReference(id: raw.venue.id, name: raw.venue.name ?? ""),
        weather: raw.weather.map(gameWeather),
        gameInfo: raw.gameInfo.map(gameInfo),
        flags: gameFlags(from: raw.flags),
        probablePitchers: probablePitchers(from: raw.probablePitchers)
    )
}

private static func liveData(from raw: MLBLiveData) -> LiveData {
    LiveData(
        plays: livePlays(from: raw.plays),
        linescore: linescore(from: raw.linescore),    // existing converter
        boxscore: boxscore(from: raw.boxscore),       // existing converter
        decisions: raw.decisions.map(gameDecisions)
    )
}
```

---

## Fixture

Capture a real response before implementing (in-season) or use an archived gamePk.

```bash
# Capture live feed for a completed game (gamePk 745612 used elsewhere in the project)
curl "https://statsapi.mlb.com/api/v1.1/game/745612/feed/live" \
  | python3 -m json.tool > Tests/SwiftBaseballTests/Fixtures/live_game_feed_745612.json
```

Trim the fixture for test use — the full response is large. At minimum keep:
- `gamePk`
- `metaData.wait` + `metaData.timeStamp`
- `gameData.status`, `gameData.teams`, 2–3 entries in `gameData.players`
- `gameData.weather`, `gameData.flags`, `gameData.probablePitchers`
- `liveData.plays.allPlays` (first 2–3 plays), `currentPlay`, `scoringPlays`
- `liveData.linescore` (trimmed)
- `liveData.boxscore` (trimmed — just home/away team + a few players)
- `liveData.decisions`

---

## Tests

File: `Tests/SwiftBaseballTests/LiveGameFeedTests.swift`

```swift
@Suite("LiveGameFeed")
struct LiveGameFeedTests {

    let feed: LiveGameFeed   // decoded from fixture in init

    @Test func gamePkDecodes() { ... }
    @Test func metaWaitInterval() { /* wait == 10 */ }
    @Test func abstractGameStateIsFinal() { /* .final */ }
    @Test func homeAndAwayTeamsDecode() { ... }
    @Test func playerDictionaryKeyStripping() { /* ID660271 → 660271 */ }
    @Test func weatherDecodes() { /* condition, temp, wind */ }
    @Test func flagsNoHitterFalse() { ... }
    @Test func probablePitchersDecod() { ... }
    @Test func allPlaysCount() { ... }
    @Test func currentPlayDecodes() { ... }
    @Test func scoringPlaysIndices() { ... }
    @Test func playsByInningDecodes() { ... }
    @Test func linescoreReusedModel() { /* currentInning, outs */ }
    @Test func boxscoreReusedModel() { /* home/away team stats */ }
    @Test func decisionsDecodes() { /* winner/loser/save */ }
    @Test func queryBuilderUsesV1_1Path() { /* endpoint.path contains "v1.1" */ }
    @Test func emptyPlayersDict() { /* graceful empty */ }
    @Test func nilDecisionsForPreviewGame() { /* decisions == nil */ }
}
```

---

## Public API Surface

```swift
// SwiftBaseball.swift addition
/// Fetch the complete live game feed for a game.
///
/// Returns a composite snapshot of the game state including the current play,
/// all prior plays, linescore, boxscore, and game decisions.
/// For live games, poll this endpoint using the ``LiveFeedMeta/wait`` interval.
///
/// ```swift
/// let feed = try await SwiftBaseball.liveGameFeed(gamePk: 745612).fetch()
/// print(feed.gameData.status.abstractGameState)  // .final
/// print(feed.liveData.plays.currentPlay?.result.event ?? "No current play")
/// ```
///
/// - Parameter gamePk: The MLB game primary key.
/// - Returns: A ``QueryBuilder`` producing a ``LiveGameFeed``.
public static func liveGameFeed(gamePk: Int) -> QueryBuilder<LiveGameFeed> {
    .liveGameFeed(gamePk: gamePk, client: client)
}
```

---

## Implementation Order

1. **Capture fixture** — `curl` the live feed for gamePk 745612, trim to test size.
2. **Endpoint version support** — Add `version` param to `Endpoint`; default `"v1"`.
3. **Internal response types** — Add all `MLB*` structs to `MLBAPIResponses.swift`.
4. **Public models** — Create `LiveGameFeed.swift` with all public structs/enums.
5. **Converter** — Add `liveGameFeed(from:)` and helpers in `MLBResponseConverters.swift`.
6. **Endpoint factory** — `LiveGameFeedEndpoint.swift`.
7. **Namespace exposure** — Add `liveGameFeed(gamePk:)` to `SwiftBaseball.swift`.
8. **Tests** — Write all test cases against the fixture.
9. **Docs + README** — DocC comments on all public declarations; update README.
10. **Commit + push.**

---

## Open Questions

- **Polling helper:** Should `QueryBuilder` gain a `.poll(every:)` async sequence method
  that respects `LiveFeedMeta.wait`? Scope-creep for this ticket — log as follow-up.
- **Fixture size:** The full live feed is ~500 KB. For CI speed, the trimmed fixture should
  stay under ~20 KB. Verify coverage is still meaningful after trimming.
- **Boxscore/linescore reuse:** The live feed's boxscore/linescore sub-payloads match the
  standalone endpoint shapes. Confirm this holds on a real response before assuming reuse
  is safe — the nested `liveData.linescore` path is slightly different from the top-level
  `game/{gamePk}/linescore` shape. If mismatched, add a dedicated internal type.
