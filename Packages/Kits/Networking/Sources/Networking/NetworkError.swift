import Foundation

/// Errors that can occur during network operations
public enum NetworkError: LocalizedError, Sendable {
    case invalidURL
    case invalidResponse
    case noData
    case decodingError(Error)
    case encodingError(Error)
    case httpError(statusCode: Int, data: Data?)
    case authenticationRequired
    case notFound(message: String)
    case networkUnavailable
    case timeout
    case rateLimited(retryAfter: TimeInterval?)
    case serverError(message: String)
    case unknownError(Error)
    
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            return "Invalid URL"
        case .invalidResponse:
            return "Invalid response from server"
        case .noData:
            return "No data received"
        case .decodingError(let error):
            return "Failed to decode response: \(error.localizedDescription)"
        case .encodingError(let error):
            return "Failed to encode request: \(error.localizedDescription)"
        case .httpError(let statusCode, _):
            return "HTTP error with status code: \(statusCode)"
        case .authenticationRequired:
            return "Authentication required"
        case .notFound(let message):
            return message
        case .networkUnavailable:
            return "Network unavailable"
        case .timeout:
            return "Request timed out"
        case .rateLimited(let retryAfter):
            if let retryAfter = retryAfter {
                return "Rate limited. Retry after \(retryAfter) seconds"
            } else {
                return "Rate limited"
            }
        case .serverError(let message):
            return "Server error: \(message)"
        case .unknownError(let error):
            return "Unknown error: \(error.localizedDescription)"
        }
    }
    
    /// Whether this error is retryable
    public var isRetryable: Bool {
        switch self {
        case .networkUnavailable, .timeout:
            return true
        case .httpError(let statusCode, _):
            return statusCode >= 500 || statusCode == 429
        case .rateLimited:
            return true
        default:
            return false
        }
    }
}