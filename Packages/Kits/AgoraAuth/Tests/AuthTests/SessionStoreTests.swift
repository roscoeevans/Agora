import XCTest
@testable import Auth
import AppFoundation

final class SessionStoreTests: XCTestCase {
    
    var sessionStore: SessionStore!
    var mockKeychainHelper: MockKeychainHelperForSessionTests!
    
    override func setUp() async throws {
        mockKeychainHelper = MockKeychainHelperForSessionTests()
        sessionStore = SessionStore(keychainHelper: mockKeychainHelper)
    }
    
    override func tearDown() async throws {
        sessionStore = nil
        mockKeychainHelper = nil
    }
    
    // MARK: - Session Storage Tests
    
    func testStoreSession() async throws {
        let user = AuthenticatedUser(
            id: "test_user_123",
            email: "test@example.com",
            fullName: PersonNameComponents()
        )
        
        try await sessionStore.storeSession(user: user, identityToken: "mock_identity_token")
        
        // Verify session was created and stored
        let accessToken = await sessionStore.accessToken
        let refreshToken = await sessionStore.refreshToken
        
        XCTAssertNotNil(accessToken)
        XCTAssertNotNil(refreshToken)
        XCTAssertTrue(accessToken!.contains("mock_access_token"))
        XCTAssertTrue(refreshToken!.contains("mock_refresh_token"))
    }
    
    func testLoadSession() async throws {
        // First store a session
        let user = AuthenticatedUser(
            id: "test_user_123",
            email: "test@example.com",
            fullName: PersonNameComponents()
        )
        
        try await sessionStore.storeSession(user: user, identityToken: "mock_identity_token")
        
        // Load the session
        let loadedSession = try await sessionStore.loadSession()
        
        XCTAssertNotNil(loadedSession)
        XCTAssertEqual(loadedSession?.user.id, "test_user_123")
        XCTAssertEqual(loadedSession?.user.email, "test@example.com")
    }
    
    func testLoadSessionWhenNoneExists() async throws {
        let loadedSession = try await sessionStore.loadSession()
        XCTAssertNil(loadedSession)
    }
    
    // MARK: - Session Validation Tests
    
    func testHasValidSessionWithValidSession() async throws {
        let user = AuthenticatedUser(id: "test_user", email: "test@example.com", fullName: nil)
        try await sessionStore.storeSession(user: user, identityToken: "token")
        
        let hasValid = await sessionStore.hasValidSession()
        XCTAssertTrue(hasValid)
    }
    
    func testHasValidSessionWithNoSession() async {
        let hasValid = await sessionStore.hasValidSession()
        XCTAssertFalse(hasValid)
    }
    
    func testHasValidSessionWithExpiredSession() async throws {
        // Create an expired session by manipulating the keychain helper
        let user = AuthenticatedUser(id: "test_user", email: "test@example.com", fullName: nil)
        let expiredSession = Session(
            user: user,
            accessToken: "expired_token",
            refreshToken: "refresh_token",
            expiresAt: Date().addingTimeInterval(-3600) // Expired 1 hour ago
        )
        
        try await mockKeychainHelper.setStoredSession(expiredSession)
        
        let hasValid = await sessionStore.hasValidSession()
        XCTAssertFalse(hasValid)
    }
    
    func testIsTokenValid() async throws {
        let user = AuthenticatedUser(id: "test_user", email: "test@example.com", fullName: nil)
        try await sessionStore.storeSession(user: user, identityToken: "token")
        
        let isValid = await sessionStore.isTokenValid()
        XCTAssertTrue(isValid)
    }
    
    func testIsTokenValidWithExpiredToken() async throws {
        // Create an expired session
        let user = AuthenticatedUser(id: "test_user", email: "test@example.com", fullName: nil)
        let expiredSession = Session(
            user: user,
            accessToken: "expired_token",
            refreshToken: "refresh_token",
            expiresAt: Date().addingTimeInterval(-3600) // Expired 1 hour ago
        )
        
        try await mockKeychainHelper.setStoredSession(expiredSession)
        
        // Force load the expired session
        _ = try await sessionStore.loadSession()
        
        let isValid = await sessionStore.isTokenValid()
        XCTAssertFalse(isValid)
    }
    
    // MARK: - User Retrieval Tests
    
    func testGetCurrentUser() async throws {
        let user = AuthenticatedUser(
            id: "test_user_456",
            email: "user@example.com",
            fullName: PersonNameComponents()
        )
        
        try await sessionStore.storeSession(user: user, identityToken: "token")
        
        let currentUser = try await sessionStore.getCurrentUser()
        XCTAssertEqual(currentUser.id, "test_user_456")
        XCTAssertEqual(currentUser.email, "user@example.com")
    }
    
    func testGetCurrentUserWithNoSession() async {
        do {
            _ = try await sessionStore.getCurrentUser()
            XCTFail("Should have thrown token not found error")
        } catch AuthTokenError.tokenNotFound {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testGetCurrentUserWithExpiredSession() async throws {
        let user = AuthenticatedUser(id: "test_user", email: "test@example.com", fullName: nil)
        let expiredSession = Session(
            user: user,
            accessToken: "expired_token",
            refreshToken: "refresh_token",
            expiresAt: Date().addingTimeInterval(-3600) // Expired 1 hour ago
        )
        
        try await mockKeychainHelper.setStoredSession(expiredSession)
        
        do {
            _ = try await sessionStore.getCurrentUser()
            XCTFail("Should have thrown token expired error")
        } catch AuthTokenError.tokenExpired {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Token Refresh Tests
    
    func testRefreshToken() async throws {
        let user = AuthenticatedUser(id: "test_user", email: "test@example.com", fullName: nil)
        try await sessionStore.storeSession(user: user, identityToken: "token")
        
        let originalToken = await sessionStore.accessToken
        
        try await sessionStore.refreshToken()
        
        let newToken = await sessionStore.accessToken
        XCTAssertNotEqual(originalToken, newToken)
        XCTAssertTrue(newToken!.contains("refreshed_access_token"))
    }
    
    func testRefreshTokenWithNoSession() async {
        do {
            try await sessionStore.refreshToken()
            XCTFail("Should have thrown token not found error")
        } catch AuthTokenError.tokenNotFound {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testRefreshTokenWithNoRefreshToken() async throws {
        let user = AuthenticatedUser(id: "test_user", email: "test@example.com", fullName: nil)
        let sessionWithoutRefresh = Session(
            user: user,
            accessToken: "access_token",
            refreshToken: nil,
            expiresAt: Date().addingTimeInterval(3600)
        )
        
        try await mockKeychainHelper.setStoredSession(sessionWithoutRefresh)
        _ = try await sessionStore.loadSession()
        
        do {
            try await sessionStore.refreshToken()
            XCTFail("Should have thrown token not found error")
        } catch AuthTokenError.tokenNotFound {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    // MARK: - Session Clearing Tests
    
    func testClearSession() async throws {
        let user = AuthenticatedUser(id: "test_user", email: "test@example.com", fullName: nil)
        try await sessionStore.storeSession(user: user, identityToken: "token")
        
        // Verify session exists
        let initialToken = await sessionStore.accessToken
        XCTAssertNotNil(initialToken)
        
        await sessionStore.clearSession()
        
        // Verify session is cleared
        let clearedToken = await sessionStore.accessToken
        XCTAssertNil(clearedToken)
        
        let deleteWasCalled = await mockKeychainHelper.deleteCredentialsCalled
        XCTAssertTrue(deleteWasCalled)
    }
    
    // MARK: - Phone Verification Tests
    
    func testUpdatePhoneVerificationStatus() async throws {
        let user = AuthenticatedUser(id: "test_user", email: "test@example.com", fullName: nil)
        try await sessionStore.storeSession(user: user, identityToken: "token")
        
        // Initially not verified
        let initialStatus = try await sessionStore.isPhoneVerified()
        XCTAssertFalse(initialStatus)
        
        // Update to verified
        try await sessionStore.updatePhoneVerificationStatus(isVerified: true)
        
        let updatedStatus = try await sessionStore.isPhoneVerified()
        XCTAssertTrue(updatedStatus)
    }
    
    func testUpdatePhoneVerificationStatusWithNoSession() async {
        do {
            try await sessionStore.updatePhoneVerificationStatus(isVerified: true)
            XCTFail("Should have thrown token not found error")
        } catch AuthTokenError.tokenNotFound {
            // Expected
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
    
    func testIsPhoneVerifiedWithNoSession() async throws {
        let isVerified = try await sessionStore.isPhoneVerified()
        XCTAssertFalse(isVerified)
    }
    
    func testIsPhoneVerifiedWithVerifiedSession() async throws {
        let user = AuthenticatedUser(id: "test_user", email: "test@example.com", fullName: nil)
        let verifiedSession = Session(
            user: user,
            accessToken: "access_token",
            refreshToken: "refresh_token",
            expiresAt: Date().addingTimeInterval(3600),
            isPhoneVerified: true
        )
        
        try await mockKeychainHelper.setStoredSession(verifiedSession)
        
        let isVerified = try await sessionStore.isPhoneVerified()
        XCTAssertTrue(isVerified)
    }
}

// MARK: - Session Model Tests

final class SessionTests: XCTestCase {
    
    func testSessionIsValidWhenNotExpired() {
        let user = AuthenticatedUser(id: "test", email: "test@example.com", fullName: nil)
        let session = Session(
            user: user,
            accessToken: "token",
            refreshToken: "refresh",
            expiresAt: Date().addingTimeInterval(3600) // 1 hour from now
        )
        
        XCTAssertTrue(session.isValid)
    }
    
    func testSessionIsInvalidWhenExpired() {
        let user = AuthenticatedUser(id: "test", email: "test@example.com", fullName: nil)
        let session = Session(
            user: user,
            accessToken: "token",
            refreshToken: "refresh",
            expiresAt: Date().addingTimeInterval(-3600) // 1 hour ago
        )
        
        XCTAssertFalse(session.isValid)
    }
    
    func testSessionPhoneVerificationDefault() {
        let user = AuthenticatedUser(id: "test", email: "test@example.com", fullName: nil)
        let session = Session(
            user: user,
            accessToken: "token",
            refreshToken: "refresh",
            expiresAt: Date().addingTimeInterval(3600)
        )
        
        XCTAssertFalse(session.isPhoneVerified)
    }
    
    func testSessionPhoneVerificationExplicit() {
        let user = AuthenticatedUser(id: "test", email: "test@example.com", fullName: nil)
        let session = Session(
            user: user,
            accessToken: "token",
            refreshToken: "refresh",
            expiresAt: Date().addingTimeInterval(3600),
            isPhoneVerified: true
        )
        
        XCTAssertTrue(session.isPhoneVerified)
    }
}

// MARK: - Mock KeychainHelper for SessionStore Tests

actor MockKeychainHelperForSessionTests: KeychainHelperProtocol {
    private var storedSession: Session?
    var deleteCredentialsCalled = false
    
    func storeSession(_ session: Session) async throws {
        storedSession = session
    }
    
    func loadSession() async throws -> Session? {
        return storedSession
    }
    
    func deleteCredentials() async {
        deleteCredentialsCalled = true
        storedSession = nil
    }
    
    func setStoredSession(_ session: Session?) async throws {
        if let session = session {
            try await storeSession(session)
        }
    }
}