import Testing
import Foundation
@testable import SwiftBaseball

@Suite("Transaction Tests")
struct TransactionTests {

    @Test("Decode transactions from fixture")
    func decodeFromFixture() throws {
        let data = try Fixtures.load("transactions_2024_07.json")
        let response = try JSONDecoder.mlb.decode(MLBTransactionsResponse.self, from: data)
        let transactions = MLBResponseConverters.transactions(from: response)

        #expect(transactions.count == 4)

        let first = try #require(transactions.first)
        #expect(first.id == 745001)
        #expect(first.typeCode == "SGN")
        #expect(first.typeDesc == "Signing")
        #expect(first.description?.contains("Aaron Judge") == true)
    }

    @Test("Player reference mapping")
    func playerReference() throws {
        let data = try Fixtures.load("transactions_2024_07.json")
        let response = try JSONDecoder.mlb.decode(MLBTransactionsResponse.self, from: data)
        let transactions = MLBResponseConverters.transactions(from: response)

        let first = try #require(transactions.first)
        #expect(first.person?.id == 592450)
        #expect(first.person?.fullName == "Aaron Judge")
    }

    @Test("From and to team references")
    func teamReferences() throws {
        let data = try Fixtures.load("transactions_2024_07.json")
        let response = try JSONDecoder.mlb.decode(MLBTransactionsResponse.self, from: data)
        let transactions = MLBResponseConverters.transactions(from: response)

        // Trade: Jazz Chisholm from Marlins to Yankees
        let trade = try #require(transactions.first(where: { $0.id == 745002 }))
        #expect(trade.fromTeam?.id == 146)
        #expect(trade.fromTeam?.name == "Miami Marlins")
        #expect(trade.toTeam?.id == 147)
        #expect(trade.toTeam?.name == "New York Yankees")
    }

    @Test("Date parsing for transaction dates")
    func dateParsing() throws {
        let data = try Fixtures.load("transactions_2024_07.json")
        let response = try JSONDecoder.mlb.decode(MLBTransactionsResponse.self, from: data)
        let transactions = MLBResponseConverters.transactions(from: response)

        let first = try #require(transactions.first)
        let date = try #require(first.date)
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "UTC")!
        let components = calendar.dateComponents([.year, .month, .day], from: date)
        #expect(components.year == 2024)
        #expect(components.month == 7)
        #expect(components.day == 1)

        let effectiveDate = try #require(first.effectiveDate)
        #expect(effectiveDate == date)
    }

    @Test("Type codes and descriptions")
    func typeCodes() throws {
        let data = try Fixtures.load("transactions_2024_07.json")
        let response = try JSONDecoder.mlb.decode(MLBTransactionsResponse.self, from: data)
        let transactions = MLBResponseConverters.transactions(from: response)

        let trades = transactions.filter { $0.typeCode == "TR" }
        #expect(trades.count == 3)
        for trade in trades {
            #expect(trade.typeDesc == "Trade")
        }

        let signings = transactions.filter { $0.typeCode == "SGN" }
        #expect(signings.count == 1)
    }

    @Test("Empty transactions produce empty array")
    func emptyTransactions() throws {
        let json = """
        {"transactions":[]}
        """.data(using: .utf8)!
        let response = try JSONDecoder.mlb.decode(MLBTransactionsResponse.self, from: json)
        let transactions = MLBResponseConverters.transactions(from: response)

        #expect(transactions.isEmpty)
    }

    @Test("Query builder path and modifiers")
    func queryBuilder() throws {
        let baseURL = URL(string: "https://statsapi.mlb.com/api/v1/")!
        let mock = MockAPIClient()
        let builder = QueryBuilder<[Transaction]>.transactions(client: mock)
            .dateRange(start: "2024-07-01", end: "2024-07-31")

        let url = try #require(builder.endpoint.url(baseURL: baseURL))
        let urlString = url.absoluteString
        #expect(urlString.contains("transactions"))
        #expect(urlString.contains("startDate=2024-07-01"))
        #expect(urlString.contains("endDate=2024-07-31"))
    }
}
