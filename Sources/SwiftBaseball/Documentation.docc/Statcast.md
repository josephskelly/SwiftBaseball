# Statcast

Aggregation vs. raw pitch-level access, leaderboards, and the streaming form.

## Overview

Statcast is MLB's optical-and-radar tracking system. Its public face is Baseball Savant, which exposes CSV downloads of pitch-level rows and ~25 leaderboards. SwiftBaseball wraps both surfaces. There are three ways to consume Statcast data, listed from coarsest to finest:

1. **Aggregator queries** — ``SwiftBaseball/statcastBatter(playerId:)`` / ``StatcastQuery`` group pitch-level rows by season into a single ``StatcastBatting`` summary (GB% / FB% / LD%, avg exit velo, barrel rate, hard-hit rate, xBA / xSLG / xwOBA).
2. **Leaderboards** — typed CSV-backed entry types covering expected stats, percentile ranks, exit-velo & barrels, pitch arsenal, pitch movement, active spin, running splits, bat tracking, outfield catch probability, outfielder jumps, fielding run value, baserunning run value, swing/take, and pitch tilt.
3. **Raw pitch-level rows** — ``StatcastPitch`` exposes one row per pitch with every documented column typed plus a `raw: [String: String]` escape hatch.

## Pick the right granularity

Aggregator queries are the right starting point when you want player-level summaries, want to derive your own rates, or are aggregating across many players. They run cheaply against a single Savant CSV per player and are date-range aware via `.season(_:)` or `.dateRange(start:end:)`.

```swift
let judge = try await SwiftBaseball
    .statcastBatter(playerId: 592_450)
    .season(2024)
    .fetch()
print(judge.barrelRate, judge.xWOBA)
```

Leaderboards are the right call when you want pre-computed, cross-player views — percentile ranks, league-leader breakdowns, per-pitch-type splits. Each leaderboard maps to one CSV endpoint and one strongly-typed entry type, so there is no aggregation cost.

```swift
let pcts = try await SwiftBaseball.percentileRanksBatter().season(2024).fetch()
print(pcts.first?.exitVelocityPercentile)  // 1–99
```

Raw pitch-level access is the right tool when you need anything Statcast records that isn't already aggregated for you — pitch sequencing, count-state analysis, situational filters, custom barrel definitions.

```swift
let game = try await SwiftBaseball.statcastGame(gamePk: 746_309).fetch()
for pitch in game where pitch.bbType == "ground_ball" {
    print(pitch.launchSpeed, pitch.launchAngle)
}
```

## Date chunking and the 25 000-row cap

Savant's CSV endpoint refuses to return more than 25 000 rows from a single request. League-wide pitch volume runs 2 000–2 500 per day, so a 7-day window stays comfortably under the cap. ``StatcastRawQuery`` chunks any date range into 7-day windows automatically and fans the requests out concurrently when you call ``StatcastRawQuery/fetch()``.

The chunk size is exposed via ``StatcastRawQuery/chunkDays(_:)`` if you need to tune it (e.g., for very dense days during the postseason).

```swift
let week = try await SwiftBaseball
    .statcastRaw(start: "2024-10-01", end: "2024-10-07")
    .fetch()
```

## Streaming for multi-month / multi-season pulls

`fetch()` returns the entire range as a single `[StatcastPitch]`. For multi-month or multi-season pulls, that's a lot of rows to hold in memory at once — a full season is roughly 700 000 pitches, and `StatcastPitch` carries ~100 typed fields plus a `raw` dictionary.

``StatcastRawQuery/stream()`` returns an `AsyncThrowingStream<StatcastPitch, Error>` that yields one pitch at a time, fetching one chunk at a time in calendar order. Peak memory stays at roughly one chunk's worth of rows regardless of how long the requested range is.

```swift
for try await pitch in SwiftBaseball
    .statcastRaw(start: "2024-04-01", end: "2024-09-30")
    .stream()
{
    aggregator.consume(pitch)
}
```

Cancelling the consuming task halts the stream cleanly: the in-flight chunk completes but no further chunks are requested.

`stream()` is sequential per chunk — the simplest form bounded by Savant's per-request throughput. Use `fetch()` when wall-clock latency matters more than memory; use `stream()` when memory matters more.

## The barrel definition

The aggregator and the exit-velo & barrels leaderboard both compute `barrelRate`, but neither is a re-implementation of an external definition. SwiftBaseball matches the public Statcast definition: a ball is a barrel when its exit velocity is at least 98 mph and its launch angle falls within a velocity-dependent window that widens as exit velocity rises. The library exposes the boolean per-pitch through the raw rows; the aggregator and leaderboards expose the rate per batted-ball event.

## Bat tracking is 2024+

Bat-tracking columns — bat speed, swing length, attack angle, attack direction, swing-path tilt — were first published by Savant in May 2024. Pre-2024 fixtures and seasons return empty cells for those fields, which decode to `nil`. The corresponding leaderboard, ``BatTrackingEntry``, returns no rows for seasons before 2024.

## Rate-scale conventions

Different leaderboards report rate fields on different scales — by deliberate choice, the library matches whatever scale Savant ships in the CSV.

- ``StatcastBatting`` (aggregator output) — rates are 0–1 fractions (`0.42` means 42%).
- ``BatTrackingEntry`` — rates are 0–1 fractions (matches Savant).
- All other leaderboards (``ExitVeloBarrelsBatterEntry``, ``PitchArsenalStatsEntry``, etc.) — rates are 0–100 integers (`42.0` means 42%).

The convention is documented on each entry type's individual properties.

## Topics

### Related articles

- ``GettingStarted``
- ``DataSources``

### Aggregator entry points

- ``StatcastBatting``
- ``StatcastPitching``
- ``StatcastQuery``

### Raw pitch-level access

- ``StatcastPitch``
- ``StatcastRawQuery``
- ``StatcastBatterRawQuery``
- ``StatcastPitcherRawQuery``
- ``StatcastGameRawQuery``
