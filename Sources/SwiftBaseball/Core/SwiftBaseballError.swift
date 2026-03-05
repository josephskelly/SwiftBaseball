import Foundation

/// Errors thrown by SwiftBaseball API operations.
public enum SwiftBaseballError: Error, Sendable {
    /// A network-level error occurred.
    case networkError(URLError)
    /// The response data could not be decoded.
    case decodingError(DecodingError)
    /// The provided date range is invalid.
    case invalidDateRange(start: String, end: String)
    /// No player was found matching the query.
    case playerNotFound(String)
    /// The API returned a rate-limit response.
    case rateLimited(retryAfter: TimeInterval?)
    /// The API returned a non-success HTTP status code.
    case invalidResponse(statusCode: Int)
    /// The library configuration is invalid.
    case configurationError(String)
    /// The API returned an unexpected response format.
    case unexpectedResponse
}

extension SwiftBaseballError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .decodingError(let error):
            return "Decoding error: \(error.localizedDescription)"
        case .invalidDateRange(let start, let end):
            return "Invalid date range: \(start) to \(end)"
        case .playerNotFound(let name):
            return "Player not found: \(name)"
        case .rateLimited(let retryAfter):
            if let retry = retryAfter {
                return "Rate limited. Retry after \(retry) seconds."
            }
            return "Rate limited."
        case .invalidResponse(let code):
            return "Invalid HTTP response: \(code)"
        case .configurationError(let message):
            return "Configuration error: \(message)"
        case .unexpectedResponse:
            return "Unexpected response from server."
        }
    }
}
