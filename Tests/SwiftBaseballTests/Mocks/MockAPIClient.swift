import Foundation
@testable import SwiftBaseball

/// A mock APIClient that returns pre-configured fixture data.
final class MockAPIClient: APIClient {
    enum Response {
        case success(Data)
        case failure(Error)
    }

    var responses: [String: Response] = [:]
    var lastEndpoint: Endpoint?
    var callCount = 0

    func stub(path: String, data: Data) {
        responses[path] = .success(data)
    }

    func stub(path: String, error: Error) {
        responses[path] = .failure(error)
    }

    func fetchRaw(_ endpoint: Endpoint) async throws -> Data {
        lastEndpoint = endpoint
        callCount += 1

        if let response = responses[endpoint.path] {
            switch response {
            case .success(let data): return data
            case .failure(let error): throw error
            }
        }

        for (key, response) in responses where endpoint.path.hasPrefix(key) {
            switch response {
            case .success(let data): return data
            case .failure(let error): throw error
            }
        }

        throw SwiftBaseballError.configurationError(
            "MockAPIClient: no stub for path '\(endpoint.path)'"
        )
    }
}

extension MockAPIClient: @unchecked Sendable {}

// MARK: - Fixture loading

enum Fixtures {
    static func load(_ filename: String) throws -> Data {
        guard let bundleURL = Bundle.module.resourceURL else {
            throw FixtureError.notFound(filename)
        }
        let fileURL = bundleURL.appendingPathComponent("Fixtures")
                               .appendingPathComponent(filename)
        return try Data(contentsOf: fileURL)
    }

    enum FixtureError: Error {
        case notFound(String)
    }
}
