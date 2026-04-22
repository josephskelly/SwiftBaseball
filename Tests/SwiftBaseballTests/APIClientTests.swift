import Foundation
import Testing
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
@testable import SwiftBaseball

// MARK: - URLProtocol stubs

private final class MockURLProtocol: URLProtocol {
    nonisolated(unsafe) static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data))?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = MockURLProtocol.requestHandler else {
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

private func makeClient(maxRetries: Int = 0, retryBaseDelay: TimeInterval = 0.001) -> URLSessionAPIClient {
    let sessionConfig = URLSessionConfiguration.ephemeral
    sessionConfig.protocolClasses = [MockURLProtocol.self]
    let session = URLSession(configuration: sessionConfig)
    let configuration = Configuration(
        baseURL: URL(string: "https://statsapi.mlb.com/api/v1/"),
        maxRetries: maxRetries,
        retryBaseDelay: retryBaseDelay
    )
    return URLSessionAPIClient(session: session, configuration: configuration)
}

private func makeHTTPResponse(url: URL, status: Int, headers: [String: String] = [:]) -> HTTPURLResponse {
    HTTPURLResponse(url: url, statusCode: status, httpVersion: "HTTP/1.1", headerFields: headers)!
}

// MARK: - Tests

@Suite("APIClient Tests", .serialized)
struct APIClientTests {
    // MARK: - 429 Retry-After header parsing

    @Test("429 response throws rateLimited error")
    func rateLimitedThrows() async throws {
        let testURL = try #require(URL(string: "https://statsapi.mlb.com/api/v1/teams"))
        MockURLProtocol.requestHandler = { _ in
            (makeHTTPResponse(url: testURL, status: 429), Data())
        }

        let client = makeClient(maxRetries: 0)
        let endpoint = Endpoint(path: "teams")

        await #expect(throws: SwiftBaseballError.self) {
            _ = try await client.fetchRaw(endpoint)
        }
    }

    @Test("429 with Retry-After header includes delay in error")
    func retryAfterHeaderParsed() async throws {
        let testURL = try #require(URL(string: "https://statsapi.mlb.com/api/v1/teams"))
        MockURLProtocol.requestHandler = { _ in
            (makeHTTPResponse(url: testURL, status: 429, headers: ["Retry-After": "30"]), Data())
        }

        let client = makeClient(maxRetries: 0)
        let endpoint = Endpoint(path: "teams")

        do {
            _ = try await client.fetchRaw(endpoint)
            Issue.record("Expected rateLimited error but fetch succeeded")
        } catch SwiftBaseballError.rateLimited(let retryAfter) {
            #expect(retryAfter == 30.0)
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    @Test("429 without Retry-After header has nil retryAfter")
    func retryAfterNilWhenHeaderAbsent() async throws {
        let testURL = try #require(URL(string: "https://statsapi.mlb.com/api/v1/teams"))
        MockURLProtocol.requestHandler = { _ in
            (makeHTTPResponse(url: testURL, status: 429), Data())
        }

        let client = makeClient(maxRetries: 0)
        let endpoint = Endpoint(path: "teams")

        do {
            _ = try await client.fetchRaw(endpoint)
            Issue.record("Expected rateLimited error but fetch succeeded")
        } catch SwiftBaseballError.rateLimited(let retryAfter) {
            #expect(retryAfter == nil)
        } catch {
            Issue.record("Unexpected error type: \(error)")
        }
    }

    // MARK: - 4xx non-retryable

    @Test("404 throws invalidResponse immediately")
    func notFoundThrowsImmediately() async throws {
        let testURL = try #require(URL(string: "https://statsapi.mlb.com/api/v1/people/0"))
        var callCount = 0
        MockURLProtocol.requestHandler = { _ in
            callCount += 1
            return (makeHTTPResponse(url: testURL, status: 404), Data())
        }

        let client = makeClient(maxRetries: 2)
        let endpoint = Endpoint(path: "people/0")

        do {
            _ = try await client.fetchRaw(endpoint)
            Issue.record("Expected error")
        } catch SwiftBaseballError.invalidResponse(let code) {
            #expect(code == 404)
            #expect(callCount == 1) // Not retried
        } catch {
            Issue.record("Unexpected error: \(error)")
        }
    }

    // MARK: - 200 success

    @Test("200 response returns data")
    func successReturnsData() async throws {
        let testURL = try #require(URL(string: "https://statsapi.mlb.com/api/v1/teams"))
        let expected = Data("{}".utf8)
        MockURLProtocol.requestHandler = { _ in
            (makeHTTPResponse(url: testURL, status: 200), expected)
        }

        let client = makeClient()
        let endpoint = Endpoint(path: "teams")
        let result = try await client.fetchRaw(endpoint)

        #expect(result == expected)
    }
}
