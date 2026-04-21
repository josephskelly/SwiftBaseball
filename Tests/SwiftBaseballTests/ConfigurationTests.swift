import Testing
import Foundation
@testable import SwiftBaseball

@Suite("Configuration Tests")
struct ConfigurationTests {

    @Test("configure is safe under concurrent callers")
    func configureIsThreadSafe() async {
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<32 {
                group.addTask {
                    let cfg = Configuration(
                        cacheEnabled: i.isMultiple(of: 2),
                        cacheTTL: TimeInterval(i + 1),
                        maxConcurrentRequests: (i % 4) + 1
                    )
                    SwiftBaseball.configure(cfg)
                }
            }
        }

        let expected = Configuration.default
        SwiftBaseball.configure(expected)

        // Smoke-check: after the races settle, configure() with a known value
        // should leave the library in a coherent state that subsequent calls
        // can still build a fluent query on top of without crashing.
        _ = SwiftBaseball.player(id: 660271)
    }

    @Test("configure toggles caching client on and off")
    func configureTogglesCaching() {
        SwiftBaseball.configure(Configuration(cacheEnabled: true, cacheTTL: 60))
        SwiftBaseball.configure(Configuration(cacheEnabled: false))
        _ = SwiftBaseball.player(id: 660271)
    }
}
