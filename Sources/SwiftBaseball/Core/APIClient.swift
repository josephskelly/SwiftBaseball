import Foundation

// MARK: - Protocol

protocol APIClient: Sendable {
    func fetchRaw(_ endpoint: Endpoint) async throws -> Data
}

// MARK: - URLSession implementation

final class URLSessionAPIClient: APIClient {
    private let session: URLSession
    private let baseURL: URL

    init(configuration: Configuration = .default) {
        self.baseURL = configuration.baseURL
        let config = URLSessionConfiguration.default
        config.httpAdditionalHeaders = ["User-Agent": configuration.userAgent]
        self.session = URLSession(configuration: config)
    }

    func fetchRaw(_ endpoint: Endpoint) async throws -> Data {
        guard let url = endpoint.url(baseURL: baseURL) else {
            throw SwiftBaseballError.configurationError(
                "Could not construct URL for path: \(endpoint.path)"
            )
        }
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(from: url)
        } catch let urlError as URLError {
            throw SwiftBaseballError.networkError(urlError)
        }
        guard let http = response as? HTTPURLResponse else {
            throw SwiftBaseballError.unexpectedResponse
        }
        switch http.statusCode {
        case 200...299:
            return data
        case 429:
            let retryAfter = http.value(forHTTPHeaderField: "Retry-After").flatMap(TimeInterval.init)
            throw SwiftBaseballError.rateLimited(retryAfter: retryAfter)
        default:
            throw SwiftBaseballError.invalidResponse(statusCode: http.statusCode)
        }
    }
}

extension URLSessionAPIClient: @unchecked Sendable {}

// MARK: - Shared JSONDecoder

extension JSONDecoder {
    static let mlb: JSONDecoder = {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .custom { decoder in
            let container = try decoder.singleValueContainer()
            let string = try container.decode(String.self)

            // Try date-only format first (most common in MLB API)
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "en_US_POSIX")
            dateFormatter.timeZone = TimeZone(identifier: "UTC")
            dateFormatter.dateFormat = "yyyy-MM-dd"
            if let date = dateFormatter.date(from: string) {
                return date
            }

            // Fall back to full ISO8601
            let iso = ISO8601DateFormatter()
            iso.formatOptions = [.withInternetDateTime]
            if let date = iso.date(from: string) {
                return date
            }

            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "Cannot decode date string: \(string)"
            )
        }
        return decoder
    }()
}
