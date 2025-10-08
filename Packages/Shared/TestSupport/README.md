# TestSupport

The TestSupport shared module provides testing utilities, mocks, and fixtures used across all test suites in the Agora iOS app. This module enables consistent and efficient testing practices.

## Purpose

This module contains mock implementations, test fixtures, custom assertions, and testing utilities that are shared across all module test suites. It ensures consistent testing patterns and reduces code duplication in tests.

## Key Components

- **MockNetworking**: Mock implementation of networking layer for testing
- **MockAuthTokenProvider**: Mock authentication token provider
- **TestFixtures**: Sample data and objects for testing
- **XCTestExtensions**: Custom assertions and testing utilities

## Dependencies

All modules (for testing purposes) - This module can import any other module to provide mocks and test utilities.

## Usage

```swift
import TestSupport
import XCTest

class MyFeatureTests: XCTestCase {
    var mockNetworking: MockNetworking!
    var mockAuth: MockAuthTokenProvider!
    
    override func setUp() {
        mockNetworking = MockNetworking()
        mockAuth = MockAuthTokenProvider()
    }
    
    func testFeature() {
        // Use test fixtures
        let testUser = TestFixtures.sampleUser
        
        // Configure mock responses
        mockNetworking.mockResponse(for: "/users/123", with: testUser)
        
        // Use custom assertions
        XCTAssertEventuallyTrue(condition, timeout: 2.0)
    }
}
```

## Mock Implementations

### MockNetworking

Provides controllable network responses for testing:

```swift
let mock = MockNetworking()
mock.mockResponse(for: "/api/posts", with: TestFixtures.samplePosts)
mock.mockError(for: "/api/posts", with: NetworkError.serverError(500))
```

### MockAuthTokenProvider

Provides controllable authentication state for testing:

```swift
let mockAuth = MockAuthTokenProvider()
mockAuth.setToken("test-token")
mockAuth.simulateExpiredToken()
```

## Test Fixtures

Pre-built sample data for consistent testing:

- `TestFixtures.sampleUser`: Sample user object
- `TestFixtures.samplePost`: Sample post object
- `TestFixtures.sampleThread`: Sample conversation thread

## Custom Assertions

Extended XCTest assertions for common testing patterns:

- `XCTAssertEventuallyTrue`: Wait for async conditions
- `XCTAssertThrowsAsyncError`: Test async error throwing
- `XCTAssertPublisherEmits`: Test Combine publisher emissions

## Architecture

The module provides:

- **Mocks**: Controllable implementations of key protocols
- **Fixtures**: Consistent test data across all test suites
- **Utilities**: Helper functions for common testing patterns
- **Extensions**: Enhanced XCTest capabilities

## Testing

This module is primarily for testing other modules. Run its own tests using:
```bash
swift test --package-path Packages/Shared/TestSupport
```