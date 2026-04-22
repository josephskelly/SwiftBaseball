import Foundation
@testable import SwiftBaseball
import Testing

@Suite("Sport modifier tests")
struct SportTests {
    @Test("Sport enum raw values are correct")
    func sportRawValues() {
        #expect(Sport.mlb.rawValue == 1)
        #expect(Sport.tripleA.rawValue == 11)
        #expect(Sport.doubleA.rawValue == 12)
        #expect(Sport.highA.rawValue == 13)
        #expect(Sport.singleA.rawValue == 14)
        #expect(Sport.rookie.rawValue == 16)
        #expect(Sport.complexLeague.rawValue == 17)
    }

    @Test("Sport enum display names are correct")
    func sportDisplayNames() {
        #expect(Sport.tripleA.displayName == "Triple-A")
        #expect(Sport.doubleA.displayName == "Double-A")
        #expect(Sport.mlb.displayName == "MLB")
        #expect(Sport.highA.displayName == "High-A")
        #expect(Sport.singleA.displayName == "Single-A")
        #expect(Sport.rookie.displayName == "Rookie")
        #expect(Sport.complexLeague.displayName == "Complex League")
    }

    @Test(".sport() adds sportId to player stats (no prior sportId)")
    func sportModifierAddsParam() {
        let builder = SwiftBaseball.playerStats(id: 605_141).sport(.tripleA)
        let item = builder.endpoint.queryItems.first { $0.name == "sportId" }
        #expect(item?.value == "11")
    }

    @Test(".sport() replaces hardcoded sportId=1 on schedule")
    func sportModifierReplacesExisting() {
        let builder = SwiftBaseball.schedule(.season(2024)).sport(.doubleA)
        let items = builder.endpoint.queryItems.filter { $0.name == "sportId" }
        #expect(items.count == 1)
        #expect(items.first?.value == "12")
    }

    @Test(".sport(.mlb) keeps sportId=1 on schedule")
    func sportModifierMlbKeepsDefault() {
        let builder = SwiftBaseball.schedule(.season(2024)).sport(.mlb)
        let items = builder.endpoint.queryItems.filter { $0.name == "sportId" }
        #expect(items.count == 1)
        #expect(items.first?.value == "1")
    }
}
