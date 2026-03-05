import Foundation

public enum SwiftBaseballError: Error, Sendable {
    case networkError(URLError)
    case decodingError(DecodingError)
    case invalidDateRange(start: String, end: String)
    case playerNotFound(String)
    case rateLimited(retryAfter: TimeInterval?)
    case invalidResponse(statusCode: Int)
    case configurationError(String)
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
