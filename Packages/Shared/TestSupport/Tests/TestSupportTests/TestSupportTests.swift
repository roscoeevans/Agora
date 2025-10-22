import XCTest
@testable import TestSupport

final class TestSupportTests: XCTestCase {
    
    func testMockAuthTokenProvider() async throws {
        let mockProvider = MockAuthTokenProvider()
        
        // Initially not authenticated
        let isAuthenticated = await mockProvider.isAuthenticated
        XCTAssertFalse(isAuthenticated)
        
        // Should return nil token
        let token = try await mockProvider.currentAccessToken()
        XCTAssertNil(token)
        
        // Set a token
        mockProvider.setToken("test_token")
        let newToken = try await mockProvider.currentAccessToken()
        XCTAssertEqual(newToken, "test_token")
        
        let newAuthState = await mockProvider.isAuthenticated
        XCTAssertTrue(newAuthState)
    }
    
    func testMockAuthTokenProviderError() async {
        let mockProvider = MockAuthTokenProvider()
        mockProvider.setShouldThrowError(true, error: .tokenExpired)
        
        do {
            _ = try await mockProvider.currentAccessToken()
            XCTFail("Should have thrown an error")
        } catch let error as AuthTokenError {
            XCTAssertEqual(error, .tokenExpired)
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }
    
    func testTestFixtures() {
        // Test that fixtures are properly structured
        XCTAssertFalse(TestFixtures.sampleUser.id.isEmpty)
        XCTAssertFalse(TestFixtures.sampleUser.handle.isEmpty)
        XCTAssertFalse(TestFixtures.sampleUser.displayName.isEmpty)
        
        XCTAssertEqual(TestFixtures.sampleUsers.count, 3)
        
        XCTAssertFalse(TestFixtures.samplePost.id.isEmpty)
        XCTAssertFalse(TestFixtures.samplePost.text.isEmpty)
        
        XCTAssertEqual(TestFixtures.samplePosts.count, 3)
    }
    
    func testXCTestExtensions() {
        // Test date assertion
        let date1 = Date()
        let date2 = Date().addingTimeInterval(0.5)
        assertDatesEqual(date1, date2, tolerance: 1.0)
        
        // Test valid handle assertion
        assertValidHandle("valid_handle123")
        
        // Test wait for condition with a simple condition
        let startTime = Date()
        waitForCondition(timeout: 1.0) {
            Date().timeIntervalSince(startTime) > 0.1
        }
    }
}