# Caching

Opt-in TTL caching for MLB Stats API responses.

## Overview

Network round-trips dominate the cost of most SwiftBaseball calls. The library ships an in-memory response cache that you opt into via ``Configuration/cacheEnabled``. When enabled, identical requests within the configured TTL window return immediately without hitting the network.

```swift
SwiftBaseball.configure(
    Configuration(cacheEnabled: true, cacheTTL: 600)  // 10-minute TTL
)
let first = try await SwiftBaseball.standings().fetch()  // hits network
let second = try await SwiftBaseball.standings().fetch() // returns cache
```

The cache is off by default — most callers want fresh data, and the cost of a Stats API request is rarely worth caching for one-shot scripts. Turn it on for long-running processes (servers, daemons, batch jobs) and interactive UIs that re-issue the same query in response to user navigation.

## Scope: MLB Stats API only

Only the MLB Stats API client is wrapped with the cache. Baseball Savant responses are not cached, by design:

- Statcast pitch-level CSVs are large (tens of thousands of rows). Storing many of them blows the memory budget.
- Aggregator queries already cover the typical "I want season totals" path with one cheap CSV per player; adding a cache layer there saves little.
- Leaderboard CSVs are mostly read once per session. If you're serving them out of an app, layer your own application-level cache at the model boundary, not the HTTP layer.

If your workload re-fetches the same Savant query frequently, store the result of `.fetch()` in your own state — don't reach for a network cache.

## Configuration

Three settings on ``Configuration`` control caching:

- ``Configuration/cacheEnabled`` — turns the cache on or off.
- ``Configuration/cacheTTL`` — how long, in seconds, an entry stays valid. Default `3600` (one hour).

A reasonable starting point for a daily-update use case: enable the cache with a TTL of 6–12 hours. Standings and rosters change once per day during the season; per-game endpoints (live feed, play-by-play) should not be cached at all and are typically called against gamePks that don't recur.

## Cache keys

The cache keys requests on the endpoint path plus the sorted query string. Two calls that produce the same `path?param=value&...` string after sorting will hit the same entry — including the case where one is a string-form date and one is a `Date` overload formatted to the same `"yyyy-MM-dd"`.

## TTL semantics

Entries expire wall-clock seconds after they were stored, not after last use. There is no LRU eviction — entries simply disappear when their TTL elapses.

This is intentional: the cache exists to absorb burst duplication ("the same screen issues this query three times during navigation"), not to memoize a long working set. Process restart purges everything; the actor holds no on-disk state.

## Manual invalidation

The ``CacheManager`` actor exposes three methods you can call when you need to force a refresh:

- ``CacheManager/invalidate(key:)`` — drops a single entry.
- ``CacheManager/purgeAll()`` — clears every entry.
- ``CacheManager/purgeExpired()`` — runs a sweep to free memory now without waiting for natural expiry.

You will rarely need these. The most common case is `purgeAll()` on app foregrounding to guarantee the next view sees fresh data.

## Concurrency model

``CacheManager`` is an `actor`, so all access is serialized inside it. Two concurrent fetches for the same key may both miss and both fire requests — the cache does not coalesce in-flight requests. If your workload needs that, layer a request-coalescing async-cache on top.

## When not to cache

Disable caching outright (the default) for:

- One-shot CLI scripts and notebooks.
- Anything that touches `live/{gamePk}` or otherwise expects per-second freshness.
- Test suites that mock the network — caching adds nothing and obscures which calls actually fired.

Enable caching for:

- Long-running servers serving the same standings / roster / schedule queries to many users.
- iOS apps where a tab switch re-issues a query the user just navigated away from.
- Bulk-stats workflows that visit the same player across many code paths.

## Topics

### Related articles

- <doc:GettingStarted>
- <doc:DataSources>
- <doc:RateLimiting>

### Related types

- ``Configuration``
- ``CacheManager``
