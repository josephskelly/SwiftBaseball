# Error Handling

What can throw, when, and how to recover.

## Overview

Every public `fetch()` is `async throws`. Failures land as ``SwiftBaseballError`` values — a small typed enum that surfaces the upstream cause at the right granularity for the call site to act on.

```swift
do {
    let player = try await SwiftBaseball.players(id: 660_271).fetch()
} catch let error as SwiftBaseballError {
    // typed handling — see below
} catch {
    // unreachable in normal use; the library only throws SwiftBaseballError
}
```

Catching `SwiftBaseballError` is enough for almost every call site. Catching `Error` is fine for "log and surface a message" code paths.

## The error cases

Each case names the upstream condition it reflects. The call site can pattern-match for differentiated handling.

### ``SwiftBaseballError/networkError(_:)``

The underlying `URLSessionDataTask` failed with a `URLError` — DNS lookup failed, the host is unreachable, the request was canceled, etc. The `URLError` is preserved so callers can branch on its `.code`. Surfaces only after retry budget is exhausted (transient `URLError` failures retry with exponential back-off).

```swift
catch SwiftBaseballError.networkError(let urlError) where urlError.code == .notConnectedToInternet {
    // tell the user to reconnect
}
```

### ``SwiftBaseballError/decodingError(_:)``

The HTTP request succeeded but the body did not match the expected shape. The associated `DecodingError` carries the JSON path and reason from `JSONDecoder`, and is the right tool to file a bug report against — it usually means an upstream schema drift.

```swift
catch SwiftBaseballError.decodingError(let decodingError) {
    // log decodingError.localizedDescription and file an issue
}
```

### ``SwiftBaseballError/rateLimited(retryAfter:)``

The upstream returned `429 Too Many Requests` and the retry budget was exhausted. The associated `retryAfter` is the `Retry-After` header value if the upstream provided one. See <doc:RateLimiting> for the back-off semantics. The standard recovery is "sleep for `retryAfter` and try again at the call site."

```swift
catch SwiftBaseballError.rateLimited(let retryAfter) {
    try await Task.sleep(for: .seconds(retryAfter ?? 60))
    // retry
}
```

### ``SwiftBaseballError/invalidResponse(statusCode:)``

The upstream returned a non-2xx, non-429 status that wasn't retried. `4xx` responses (other than `429`) propagate immediately because the same request will keep failing — typically `404 Not Found` for a misformed identifier or `400 Bad Request` for an invalid query parameter.

```swift
catch SwiftBaseballError.invalidResponse(statusCode: 404) {
    // probably a stale player id
}
```

### ``SwiftBaseballError/invalidDateRange(start:end:)``

Pre-flight validation failed: the supplied `start` is after `end`, or one of the dates couldn't be parsed. Always recoverable by the caller — fix the dates and retry.

### ``SwiftBaseballError/notFound(_:)`` and ``SwiftBaseballError/playerNotFound(_:)``

The upstream returned `200 OK` with an empty result envelope rather than `404`. Common for player-name lookups that don't match anyone. The associated string is the query that produced no results.

### ``SwiftBaseballError/configurationError(_:)``

Library-side configuration is invalid — typically a malformed base URL. Should never fire in normal use; if it does, it indicates a programming error rather than a runtime condition.

### ``SwiftBaseballError/unexpectedResponse``

A catch-all for "request succeeded but the response object wasn't an HTTP response" — practically only fires under URLSession bugs or in tests with an exotic mock. Treat as a programming error.

## Strategies

### Default: catch the typed error and surface a message

```swift
do {
    let stats = try await SwiftBaseball.batterStats(id: 660_271).season(2024).fetch()
    render(stats)
} catch let error as SwiftBaseballError {
    showAlert(title: "Could not load stats", message: error.localizedDescription)
}
```

`SwiftBaseballError` conforms to `LocalizedError`, so `localizedDescription` returns a human-readable string with the upstream cause already filled in.

### Retry on transient failures

The library already retries network and 5xx failures internally up to ``Configuration/maxRetries``. Add a *call-site* retry only for cases that survive the built-in retries — typically `rateLimited` after a long pause:

```swift
for attempt in 0..<3 {
    do {
        return try await SwiftBaseball.statcastRaw(start: start, end: end).fetch()
    } catch SwiftBaseballError.rateLimited(let retryAfter) {
        try await Task.sleep(for: .seconds(retryAfter ?? 60))
    }
}
throw SwiftBaseballError.rateLimited(retryAfter: nil)
```

### Distinguish "not found" from "wire failure"

`notFound` and `playerNotFound` mean the upstream succeeded — there's nothing wrong, the answer is just empty. Branch on those to render an empty state rather than an error message.

### Don't catch `error` and swallow

The catch-all `catch { }` is a code smell here. Every error the library throws is a typed `SwiftBaseballError` — the only way `error` would escape `as` matching is a programming error in the library itself, which should fail loudly during development.

## Topics

### Related articles

- <doc:GettingStarted>
- <doc:RateLimiting>
- <doc:Caching>

### Related types

- ``SwiftBaseballError``
- ``Configuration``
