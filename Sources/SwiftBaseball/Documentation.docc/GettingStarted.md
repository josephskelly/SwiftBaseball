# Getting Started with SwiftBaseball

Install the package, configure the client, and run your first query.

## Overview

SwiftBaseball is a Swift Package Manager library. Add it to your `Package.swift` or to your Xcode project's package dependencies.

```swift
dependencies: [
    .package(url: "https://github.com/josephskelly/SwiftBaseball.git", from: "0.5.0")
]
```

Then add `SwiftBaseball` to the target dependencies of any product that uses it.

```swift
.target(
    name: "MyApp",
    dependencies: ["SwiftBaseball"]
)
```

The library targets iOS 17, iPadOS 17, macOS 14, tvOS 17, watchOS 10, visionOS 1, and Linux. Swift 6 language mode is required.

## Your first query

Every query is a fluent chain that ends with `await fetch()`:

```swift
import SwiftBaseball

let judge = try await SwiftBaseball.player(id: 592450).fetch()
print(judge.fullName)  // "Aaron Judge"
```

Most chains take optional refinement modifiers between the entry point and `fetch()`. The compiler will complete the available modifiers per query type.

```swift
let leaders = try await SwiftBaseball
    .leaders(.homeRuns)
    .season(2024)
    .limit(10)
    .fetch()
```

For lookups that take a date, both `Date` and `"YYYY-MM-DD"` strings are accepted on every public method that takes one.

## Configuring the client

Library defaults work for most apps. Call ``SwiftBaseball/configure(_:)`` once at launch to override caching, retry behavior, or the user-agent string.

```swift
SwiftBaseball.configure(
    .init(
        cacheEnabled: true,
        cacheTTL: 300,           // 5 minutes
        maxRetries: 2,
        retryBaseDelay: 0.5,
        userAgent: "MyApp/1.0"
    )
)
```

The configuration is thread-safe and can be replaced at any time. New requests pick up the new client immediately; in-flight requests run to completion against their original client.

## Error handling

All public methods are `async throws` and surface a typed ``SwiftBaseballError``. The cases that most apps need to switch on:

- ``SwiftBaseballError/networkError(_:)`` — wraps a `URLError`, typically transport-level.
- ``SwiftBaseballError/invalidResponse(statusCode:)`` — non-2xx HTTP response.
- ``SwiftBaseballError/rateLimited(retryAfter:)`` — HTTP 429; `retryAfter` is parsed from the `Retry-After` header when present.
- ``SwiftBaseballError/decodingError(_:)`` — the response body could not be decoded into the expected model. Usually indicates an upstream schema change; please file an issue.

```swift
do {
    let player = try await SwiftBaseball.player(id: 592450).fetch()
    handle(player)
} catch let SwiftBaseballError.rateLimited(retryAfter) {
    await Task.sleep(for: .seconds(retryAfter ?? 30))
    // retry…
} catch {
    log(error)
}
```

The library will not retry automatically beyond the count set in `Configuration.maxRetries` (default `0`). Anything past that surfaces as an error.

## Where to look next

- ``DataSources`` — when to reach for Baseball Savant versus the MLB Stats API.
- ``Statcast`` — aggregation vs. raw pitch-level access, leaderboards, the `stream()` form.
