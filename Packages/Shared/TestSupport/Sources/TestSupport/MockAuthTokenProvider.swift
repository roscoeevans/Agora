import Foundation

/// Mock implementation of AuthTokenProvider for testing
public final class MockAuthTokenProvider: AuthTokenProvider, @unchecked Sendable {
    private var _token: String?
    private var _isAuthenticated: Bool = false
    private var _shouldThrowError: Bool = false
    private var _errorToThrow: AuthTokenError = .tokenNotFound
    
    public init(token: String? = nil, isAuthenticated: Bool = false) {
        self._token = token
        self._isAuthenticated = isAuthenticated
    }
    
    public func currentAccessToken() async throws -> String? {
        if _shouldThrowError {
            throw _errorToThrow
        }
        
        return _token
    }
    
    public var isAuthenticated: Bool {
        get async {
            return _isAuthenticated
        }
    }
    
    // MARK: - Test Helpers
    
    /// Set the token to return from currentAccessToken()
    public func setToken(_ token: String?) {
        _token = token
        _isAuthenticated = token != nil
    }
    
    /// Set whether the provider should throw an error
    public func setShouldThrowError(_ shouldThrow: Bool, error: AuthTokenError = .tokenNotFound) {
        _shouldThrowError = shouldThrow
        _errorToThrow = error
    }
    
    /// Set the authentication state
    public func setAuthenticated(_ authenticated: Bool) {
        _isAuthenticated = authenticated
        if !authenticated {
            _token = nil
        }
    }
}