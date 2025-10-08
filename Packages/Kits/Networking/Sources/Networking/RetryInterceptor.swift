import Foundation
import OpenAPIRuntime
import HTTPTypes
import AppFoundation

/// Middleware that implements exponential backoff retry logic for failed requests
public struct RetryInterceptor: ClientMiddleware, Sendable {
    private let maxRetries: Int
    private let baseDelay: TimeInterval
    private let maxDelay: TimeInterval
    private let logger: Logger?
    
    public init(
        maxRetries: Int = 3,
        baseDelay: TimeInterval = 1.0,
        maxDelay: TimeInterval = 60.0,
        logger: Logger? = nil
    ) {
        self.maxRetries = maxRetries
        self.baseDelay = baseDelay
        self.maxDelay = maxDelay
        self.logger = logger
    }
    
    public func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String,
        next: @Sendable (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        var lastError: Error?
        
        for attempt in 0...maxRetries {
            do {
                let (response, responseBody) = try await next(request, body, baseURL)
                
                // Check if we should retry based on status code
                if shouldRetry(response: response, attempt: attempt) {
                    let delay = calculateDelay(attempt: attempt)
                    logger?.info("Request failed with status \(response.status.code), retrying in \(delay)s (attempt \(attempt + 1)/\(maxRetries + 1))")
                    
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    continue
                }
                
                return (response, responseBody)
            } catch {
                lastError = error
                
                if shouldRetry(error: error, attempt: attempt) {
                    let delay = calculateDelay(attempt: attempt)
                    logger?.warning("Request failed with error: \(error), retrying in \(delay)s (attempt \(attempt + 1)/\(maxRetries + 1))")
                    
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    continue
                }
                
                throw error
            }
        }
        
        // If we've exhausted all retries, throw the last error
        throw lastError ?? NetworkError.unknownError(NSError(domain: "RetryExhausted", code: -1))
    }
    
    /// Determine if we should retry based on HTTP response
    private func shouldRetry(response: HTTPResponse, attempt: Int) -> Bool {
        guard attempt < maxRetries else { return false }
        
        let statusCode = response.status.code
        
        // Retry on server errors (5xx) and rate limiting (429)
        return statusCode >= 500 || statusCode == 429
    }
    
    /// Determine if we should retry based on error
    private func shouldRetry(error: Error, attempt: Int) -> Bool {
        guard attempt < maxRetries else { return false }
        
        // Retry on network errors
        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost, .timedOut:
                return true
            default:
                return false
            }
        }
        
        // Retry on specific NetworkError cases
        if let networkError = error as? NetworkError {
            return networkError.isRetryable
        }
        
        return false
    }
    
    /// Calculate exponential backoff delay with jitter
    private func calculateDelay(attempt: Int) -> TimeInterval {
        let exponentialDelay = baseDelay * pow(2.0, Double(attempt))
        let jitter = Double.random(in: 0.0...0.1) * exponentialDelay
        let delayWithJitter = exponentialDelay + jitter
        
        return min(delayWithJitter, maxDelay)
    }
}