import Foundation
@testable import SwiftBaseball
import Testing

/// Verifies that every public `Date`-taking convenience overload formats the
/// `Date` to `"yyyy-MM-dd"` UTC and produces a query identical to the existing
/// `String`-taking call site. These overloads are pure forwarders, so we lock
/// them in by comparing the resulting query items rather than re-testing the
/// underlying network plumbing.
@Suite("Date convenience overloads (§4.2)")
struct DateOverloadTests {
    /// 2024-05-31 00:00:00 UTC — picked because the same calendar day spans
    /// the previous date in any timezone west of UTC, which would expose a
    /// locale/timezone bug in the formatter.
    private static let sampleDate = Date(timeIntervalSince1970: 1_717_113_600)
    private static let sampleString = "2024-05-31"

    /// 2024-09-29 00:00:00 UTC — paired end date for `dateRange` overloads.
    private static let endDate = Date(timeIntervalSince1970: 1_727_568_000)
    private static let endString = "2024-09-29"

    // MARK: - MLBDateFormatter sanity

    @Test("MLBDateFormatter formats Date in UTC regardless of host timezone")
    func formatterIsUTC() {
        #expect(MLBDateFormatter.string(from: Self.sampleDate) == Self.sampleString)
        #expect(MLBDateFormatter.string(from: Self.endDate) == Self.endString)
    }

    // MARK: - QueryBuilder.date(_:) and .dateRange(start:end:)

    @Test("QueryBuilder.date(Date) produces same query item as String overload")
    func queryBuilderDate() {
        let mock = MockAPIClient()
        let dateBuilder = QueryBuilder<[ScheduleEntry]>
            .schedule(.season(2024), client: mock)
            .date(Self.sampleDate)
        let stringBuilder = QueryBuilder<[ScheduleEntry]>
            .schedule(.season(2024), client: mock)
            .date(Self.sampleString)

        #expect(dateBuilder.endpoint.queryItems == stringBuilder.endpoint.queryItems)
        #expect(dateBuilder.endpoint.queryItems
            .contains { $0.name == "date" && $0.value == Self.sampleString })
    }

    @Test("QueryBuilder.dateRange(Date, Date) produces same query items as String overload")
    func queryBuilderDateRange() {
        let mock = MockAPIClient()
        let dateBuilder = QueryBuilder<[ScheduleEntry]>
            .schedule(.season(2024), client: mock)
            .dateRange(start: Self.sampleDate, end: Self.endDate)
        let stringBuilder = QueryBuilder<[ScheduleEntry]>
            .schedule(.season(2024), client: mock)
            .dateRange(start: Self.sampleString, end: Self.endString)

        #expect(dateBuilder.endpoint.queryItems == stringBuilder.endpoint.queryItems)
        #expect(dateBuilder.endpoint.queryItems
            .contains { $0.name == "startDate" && $0.value == Self.sampleString })
        #expect(dateBuilder.endpoint.queryItems
            .contains { $0.name == "endDate" && $0.value == Self.endString })
    }

    // MARK: - SwiftBaseball top-level Date overloads

    @Test("SwiftBaseball.umpires(date:) Date overload matches String overload")
    func umpiresDateOverload() {
        let dateBuilder = SwiftBaseball.umpires(date: Self.sampleDate)
        let stringBuilder = SwiftBaseball.umpires(date: Self.sampleString)
        #expect(dateBuilder.endpoint.queryItems == stringBuilder.endpoint.queryItems)
        #expect(dateBuilder.endpoint.queryItems
            .contains { $0.name == "date" && $0.value == Self.sampleString })
    }

    @Test("SwiftBaseball.officialScorers(date:) Date overload matches String overload")
    func officialScorersDateOverload() {
        let dateBuilder = SwiftBaseball.officialScorers(date: Self.sampleDate)
        let stringBuilder = SwiftBaseball.officialScorers(date: Self.sampleString)
        #expect(dateBuilder.endpoint.queryItems == stringBuilder.endpoint.queryItems)
        #expect(dateBuilder.endpoint.queryItems
            .contains { $0.name == "date" && $0.value == Self.sampleString })
    }

    @Test("SwiftBaseball.statcastRaw(start:end:) Date overload matches String overload")
    func statcastRawDateOverload() {
        let dateQuery = SwiftBaseball.statcastRaw(start: Self.sampleDate, end: Self.endDate)
        let stringQuery = SwiftBaseball.statcastRaw(start: Self.sampleString, end: Self.endString)
        #expect(dateQuery.start == stringQuery.start)
        #expect(dateQuery.end == stringQuery.end)
        #expect(dateQuery.start == Self.sampleString)
        #expect(dateQuery.end == Self.endString)
    }

    // MARK: - Statcast query Date overloads (compile-time wiring)
    //
    // The Statcast endpoints fire CSV requests rather than building MLB Stats API
    // endpoints, so we don't have a queryItems property to compare. Instead we
    // assert the Date overload exists with the right signature and forwards
    // through to MLBDateFormatter — a simple compile-time + identity check.

    @Test("StatcastQuery.dateRange Date overload exists and forwards via MLBDateFormatter")
    func statcastQueryDateOverload() {
        let mock = StatcastAPIClient()
        let query = StatcastQuery(playerId: 660271, client: mock)
            .dateRange(start: Self.sampleDate, end: Self.endDate)
        // Reflection: confirm internal startDate/endDate strings were populated.
        let mirror = Mirror(reflecting: query)
        let start = mirror.children.first { $0.label == "startDate" }?.value as? String
        let end = mirror.children.first { $0.label == "endDate" }?.value as? String
        #expect(start == Self.sampleString)
        #expect(end == Self.endString)
    }

    @Test("StatcastPitcherQuery.dateRange Date overload populates startDate/endDate")
    func statcastPitcherQueryDateOverload() {
        let mock = StatcastAPIClient()
        let query = StatcastPitcherQuery(playerId: 543037, client: mock)
            .dateRange(start: Self.sampleDate, end: Self.endDate)
        let mirror = Mirror(reflecting: query)
        let start = mirror.children.first { $0.label == "startDate" }?.value as? String
        let end = mirror.children.first { $0.label == "endDate" }?.value as? String
        #expect(start == Self.sampleString)
        #expect(end == Self.endString)
    }

    @Test("StatcastBatchBattingQuery.dateRange Date overload populates startDate/endDate")
    func statcastBatchBattingDateOverload() {
        let mock = StatcastAPIClient()
        let query = StatcastBatchBattingQuery(playerIds: [660271], client: mock)
            .dateRange(start: Self.sampleDate, end: Self.endDate)
        let mirror = Mirror(reflecting: query)
        let start = mirror.children.first { $0.label == "startDate" }?.value as? String
        let end = mirror.children.first { $0.label == "endDate" }?.value as? String
        #expect(start == Self.sampleString)
        #expect(end == Self.endString)
    }

    @Test("StatcastBatchPitchingQuery.dateRange Date overload populates startDate/endDate")
    func statcastBatchPitchingDateOverload() {
        let mock = StatcastAPIClient()
        let query = StatcastBatchPitchingQuery(playerIds: [543037], client: mock)
            .dateRange(start: Self.sampleDate, end: Self.endDate)
        let mirror = Mirror(reflecting: query)
        let start = mirror.children.first { $0.label == "startDate" }?.value as? String
        let end = mirror.children.first { $0.label == "endDate" }?.value as? String
        #expect(start == Self.sampleString)
        #expect(end == Self.endString)
    }

    @Test("StatcastBatterRawQuery.dateRange Date overload populates startDate/endDate")
    func statcastBatterRawDateOverload() {
        let mock = StatcastAPIClient()
        let query = StatcastBatterRawQuery(client: mock, playerId: 660271)
            .dateRange(start: Self.sampleDate, end: Self.endDate)
        let mirror = Mirror(reflecting: query)
        let start = mirror.children.first { $0.label == "startDate" }?.value as? String
        let end = mirror.children.first { $0.label == "endDate" }?.value as? String
        #expect(start == Self.sampleString)
        #expect(end == Self.endString)
    }

    @Test("StatcastPitcherRawQuery.dateRange Date overload populates startDate/endDate")
    func statcastPitcherRawDateOverload() {
        let mock = StatcastAPIClient()
        let query = StatcastPitcherRawQuery(client: mock, playerId: 543037)
            .dateRange(start: Self.sampleDate, end: Self.endDate)
        let mirror = Mirror(reflecting: query)
        let start = mirror.children.first { $0.label == "startDate" }?.value as? String
        let end = mirror.children.first { $0.label == "endDate" }?.value as? String
        #expect(start == Self.sampleString)
        #expect(end == Self.endString)
    }
}
