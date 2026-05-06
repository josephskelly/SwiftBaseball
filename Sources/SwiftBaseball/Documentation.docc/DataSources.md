# Data Sources

When to reach for the MLB Stats API vs. Baseball Savant, and what each one is good at.

## Overview

SwiftBaseball talks to two upstream services. They have different shapes, different rate-limit behavior, and different strengths. Understanding which one to query for a given question saves wall-clock time and avoids surprising errors.

| Source | Format | Auth | Best for |
|---|---|---|---|
| **MLB Stats API** (`statsapi.mlb.com`) | JSON | None | Players, teams, schedules, standings, box scores, season stats, sabermetrics (wOBA / wRC+ / WAR), play-by-play, transactions, awards, draft, official scorers, postseason brackets |
| **Baseball Savant / Statcast** (`baseballsavant.mlb.com`) | CSV | None | Pitch-level Statcast (release / movement / outcome / xMetrics), expected stats, percentile ranks, exit-velo & barrels, pitch arsenal & movement, sprint speed, OAA, catcher framing, bat tracking |

## MLB Stats API

The MLB Stats API is fast (under 200 ms per request typical), JSON-shaped, and stable. Almost every method on `SwiftBaseball.*` that returns a player, team, schedule, game, or stats hits this source.

Rate limits are undocumented but generous in practice. The library uses a default `maxConcurrent: 8` against this service and retries on transient failures up to ``Configuration/maxRetries``.

A few endpoints have schema quirks worth knowing about — these are surfaced as either internal converters or custom decoders:

- `currentTeam` only appears on player lookups when `?hydrate=currentTeam` is added — the library does this automatically.
- Rate stats (`avg`, `era`, `whip`) come over the wire as quoted strings; counting stats come as ints. The `MLBStatNumber` decoder accepts both.
- `gamesBack: "-"` for division leaders parses to `nil`.
- The `teams/history` endpoint returns malformed `league` refs (no `id`) for franchises in pre-debut snapshot years; ``MLBEntityRef`` tolerates the missing field.

## Baseball Savant / Statcast

Savant is the public face of MLB's Statcast tracking. It serves CSV from a small handful of leaderboard endpoints, plus the workhorse `statcast_search/csv` endpoint for raw pitch-level rows. Two characteristics drive the library's design:

1. **The 25 000-row CSV cap.** A single request cannot return more than 25k pitches. League-wide pitch volume averages 2 000–2 500 per day, so the library chunks date-range requests into 7-day windows and concatenates.
2. **Tighter rate limits.** Savant is more aggressive about throttling than the Stats API. The library uses `maxConcurrent: 4` (sometimes `1` for older paths) and a separate ``RateLimiter`` for Savant.

Savant CSVs are also more drift-prone than the Stats API JSON. New columns appear, old ones get renamed or dropped. Two patterns help:

- **Raw access** — every ``StatcastPitch`` carries a typed surface for ~100 documented columns plus a `raw: [String: String]` dictionary holding every column verbatim. New Savant columns surface in `raw` even before they get a typed property.
- **Leaderboards** are CSVs without an envelope. Some columns are season-conditional (bat-tracking columns first appear in 2024). Older seasons return empty data for those rates.

## Choosing between them

Use the MLB Stats API for:
- Anything about a person, team, schedule, or game outcome.
- Box-score and play-by-play context (umpires, pitch calls, runner movement).
- Season-aggregated standard / advanced / sabermetric stats.

Use Baseball Savant for:
- Anything per-pitch (release point, velocity, spin, movement, location, batted-ball outcome, expected stats, win-prob delta).
- Per-pitch-type breakdowns (arsenal, movement, active spin, tilt).
- Defensive metrics that depend on tracking data (OAA, catch probability, outfielder jumps).
- Bat-tracking metrics from 2024 forward (bat speed, swing length, attack angle).

When both sources expose what looks like the same metric — e.g., wOBA — prefer the MLB Stats API's `sabermetrics` view for season totals, and Savant's `expected_statistics` board for xwOBA. They are not identical: the Stats API computes wOBA from the season's counting events; Savant's xwOBA is a Statcast model fit on launch speed and angle.

## Caching

Caching is opt-in via ``Configuration/cacheEnabled``. When enabled, only the MLB Stats API client is wrapped with a TTL cache — Savant responses are not cached, because their rows are pitch-level data that consumers usually want fresh, and CSV bodies are large.

## Topics

### Related articles

- ``GettingStarted``
- ``Statcast``
