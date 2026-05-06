# Rate Limiting

How SwiftBaseball caps concurrent requests and handles 429 / 5xx responses.

## Overview

Both upstreams — the MLB Stats API and Baseball Savant — throttle clients that fan out too aggressively. SwiftBaseball protects you from accidental over-fetch with two layers:

1. A **concurrency limiter** that caps simultaneous in-flight requests per client.
2. **Retry with exponential back-off** on transient failures (429, 5xx, network errors).

You shouldn't have to think about either in normal use. The defaults are tuned to be polite to the upstream services and let large fan-outs (`SwiftBaseball.batchStats(...)`, `statcastBatchBatting(...)`) complete without manual sequencing.

## Concurrency cap

The MLB Stats API client uses a default cap of 5 simultaneous requests, configurable via ``Configuration/maxConcurrentRequests``:

```swift
SwiftBaseball.configure(
    Configuration(maxConcurrentRequests: 8)
)
```

The Baseball Savant client uses a tighter cap of 4 (and 1 for some legacy paths). The Savant cap is not user-configurable — it's baked in because Savant returns 503 / 429 quickly under load and does not respect aggressive parallelism.

The cap is enforced by an internal ``RateLimiter`` actor: each request `acquire()`s a permit before firing and releases it on completion. If all permits are taken, callers suspend until one frees up. Callers see only `await SwiftBaseball.x()` — the suspension happens transparently.

## Why two clients have two limiters

The library holds **separate** rate limiters per upstream. Saturating the Statcast client does not block MLB Stats API queries from progressing, and vice versa. This matters when you mix the two in a single workflow — e.g., fetch a season's roster from the Stats API and then aggregate Statcast for every player. The roster query never queues behind the batch.

## Retry behavior

The Stats API client retries up to ``Configuration/maxRetries`` times (default `3`) on:

- Network errors (`URLError`).
- HTTP `429 Too Many Requests`.
- HTTP `5xx` server errors.

Back-off is exponential: `retryBaseDelay × 2^(attempt-1)`. Default ``Configuration/retryBaseDelay`` is `0.5 s`, so attempts fire at `t=0`, `t=0.5s`, `t=1s`, `t=2s`. A `Retry-After` response header is honored when present and overrides the computed back-off.

`4xx` responses other than `429` are treated as permanent and propagate immediately as ``SwiftBaseballError/invalidResponse(statusCode:)`` — no retry, since the same request will keep failing.

## When you'll see ``SwiftBaseballError/rateLimited(retryAfter:)``

The error surfaces in two cases:

1. The retry budget is exhausted (`maxRetries` reached) and the upstream is still returning 429.
2. You catch the error explicitly and decide not to retry.

The associated value carries the `Retry-After` window if the upstream provided one. A reasonable response is to wait that long, then retry the operation at the call site.

```swift
do {
    let pitches = try await SwiftBaseball.statcastRaw(start: "2024-04-01", end: "2024-04-30").fetch()
} catch SwiftBaseballError.rateLimited(let retryAfter) {
    let wait = retryAfter ?? 60
    try await Task.sleep(for: .seconds(wait))
    // retry
}
```

## Tuning for batch workloads

`batchStats(...)` and `statcastBatchBatting(...)` already fan out within the configured cap. The right knob to turn is ``Configuration/maxConcurrentRequests``, not the batch's own internal parallelism — the batch dispatches every request through the same rate-limiter, so raising the cap lifts the ceiling.

For the Stats API, values up to 12–16 work in practice. Above that, you'll start to see 429s.

For Savant, **don't try to circumvent the built-in cap of 4.** It's set conservatively because Savant's edge throttling fires earlier than its documented limits.

## Tuning for interactive use

Default values are right for most apps. If your UI is showing a spinner during a sequence of unrelated requests (player → team → schedule) and you want lower latency, raise `maxConcurrentRequests` to 8 — but only on the Stats API client. Savant doesn't reward parallelism here.

## Cancellation

The HTTP request itself respects task cancellation: cancelling the awaiting `Task` cancels the underlying `URLSessionDataTask` and propagates a `URLError(.cancelled)`. Cancellation while a request is *queued behind the rate limiter* does not unblock the queue — the next available permit will resume the canceled task, which then sees the cancellation when it tries to send its request. The practical effect is that cancellation always lands within one upstream round-trip.

## Topics

### Related articles

- <doc:GettingStarted>
- <doc:ErrorHandling>
- <doc:Caching>

### Related types

- ``Configuration``
- ``SwiftBaseballError``
