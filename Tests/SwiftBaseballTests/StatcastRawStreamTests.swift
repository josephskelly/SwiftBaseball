import Foundation
import Testing
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import SwiftBaseball

private final class StreamMockURLProtocol: URLProtocol {
    nonisolated(unsafe) static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let handler = StreamMockURLProtocol.requestHandler else {
            client?.urlProtocol(self, didFailWithError: URLError(.unknown))
            return
        }
        do {
            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}
}

private func makeStatcastClient() -> StatcastAPIClient {
    let config = URLSessionConfiguration.ephemeral
    config.protocolClasses = [StreamMockURLProtocol.self]
    let session = URLSession(configuration: config)
    let baseURL = URL(string: "https://baseballsavant.mlb.com")!
    return StatcastAPIClient(session: session, baseURL: baseURL)
}

private func httpResponse(_ url: URL, _ status: Int = 200) -> HTTPURLResponse {
    HTTPURLResponse(url: url, statusCode: status, httpVersion: "HTTP/1.1", headerFields: nil)!
}

@Suite("Statcast Raw Stream Tests", .serialized)
struct StatcastRawStreamTests {
    @Test("stream() yields every pitch across multiple chunks in calendar order")
    func streamYieldsAllChunks() async throws {
        let csv = try Fixtures.load("statcast_raw_game_746309.csv")
        let csvString = try #require(String(data: csv, encoding: .utf8))

        nonisolated(unsafe) var observedRanges: [(String, String)] = []
        StreamMockURLProtocol.requestHandler = { request in
            let url = try #require(request.url)
            let comps = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false))
            let items = comps.queryItems ?? []
            let gt = items.first { $0.name == "game_date_gt" }?.value ?? ""
            let lt = items.first { $0.name == "game_date_lt" }?.value ?? ""
            observedRanges.append((gt, lt))
            return (httpResponse(url), Data(csvString.utf8))
        }

        let client = makeStatcastClient()
        let query = StatcastRawQuery(client: client, start: "2024-05-01", end: "2024-05-14")

        var count = 0
        for try await _ in query.stream() {
            count += 1
        }

        // 14 days → two 7-day chunks → 2 × 15 fixture rows = 30 pitches.
        #expect(count == 30)
        #expect(observedRanges.count == 2)
        #expect(observedRanges[0] == ("2024-05-01", "2024-05-07"))
        #expect(observedRanges[1] == ("2024-05-08", "2024-05-14"))
    }

    @Test("stream() applies gameType filter row-by-row")
    func streamAppliesGameTypeFilter() async throws {
        let csv = try Fixtures.load("statcast_raw_game_746309.csv")
        let csvString = try #require(String(data: csv, encoding: .utf8))

        StreamMockURLProtocol.requestHandler = { request in
            let url = try #require(request.url)
            return (httpResponse(url), Data(csvString.utf8))
        }

        let client = makeStatcastClient()
        let query = StatcastRawQuery(client: client, start: "2024-05-01", end: "2024-05-07")
            .gameType("X")  // fixture rows are all "R" — filter drops everything

        var count = 0
        for try await _ in query.stream() {
            count += 1
        }
        #expect(count == 0)
    }

    @Test("stream() propagates network errors via the throwing iterator")
    func streamPropagatesErrors() async throws {
        StreamMockURLProtocol.requestHandler = { request in
            let url = try #require(request.url)
            return (httpResponse(url, 500), Data())
        }

        let client = makeStatcastClient()
        let query = StatcastRawQuery(client: client, start: "2024-05-01", end: "2024-05-01")

        await #expect(throws: SwiftBaseballError.self) {
            for try await _ in query.stream() {
                Issue.record("Should not yield — server returned 500")
            }
        }
    }

    @Test("stream() respects custom chunk size")
    func streamRespectsChunkDays() async throws {
        let csv = try Fixtures.load("statcast_raw_game_746309.csv")
        let csvString = try #require(String(data: csv, encoding: .utf8))

        nonisolated(unsafe) var requestCount = 0
        StreamMockURLProtocol.requestHandler = { request in
            requestCount += 1
            let url = try #require(request.url)
            return (httpResponse(url), Data(csvString.utf8))
        }

        let client = makeStatcastClient()
        let query = StatcastRawQuery(client: client, start: "2024-05-01", end: "2024-05-10")
            .chunkDays(3) // 10 days / 3 = 4 chunks

        for try await _ in query.stream() {}
        #expect(requestCount == 4)
    }
}
