# Networking Kit

Network layer for Agora iOS app, providing type-safe API communication using OpenAPI-generated Swift client code.

## Overview

The Networking kit provides a clean, protocol-based interface for communicating with the Agora backend API. It uses:

- **OpenAPI-generated client code** for type-safe API calls
- **Protocol-based architecture** for easy testing and mocking
- **Environment-aware service factory** for seamless dev/staging/production switching

## Architecture

### Components

#### `AgoraAPIClient` Protocol
High-level protocol defining all API operations. Features depend on this protocol, not concrete implementations.

```swift
public protocol AgoraAPIClient: Sendable {
    func fetchForYouFeed(cursor: String?, limit: Int?) async throws -> FeedResponse
    func beginSignInWithApple(nonce: String) async throws -> SWABeginResponse
    func finishSignInWithApple(identityToken: String, authorizationCode: String) async throws -> AuthResponse
}
```

#### `OpenAPIAgoraClient`
Production implementation using OpenAPI-generated code. This is the real client that talks to the backend.

#### `StubAgoraClient`
Development/testing implementation that returns canned data. Perfect for:
- Offline development
- UI/UX iteration without backend
- Fast unit tests
- Demo builds

#### `NetworkingServiceFactory`
Factory for creating the appropriate client based on environment configuration.

### Generated Code

OpenAPI client code is **pre-generated** (not at build time) and committed to the repository at:

```
Sources/Networking/Generated/
```

This approach provides:
- ✅ **Fast builds** - no codegen during compilation
- ✅ **Predictable** - see exactly what code you're using
- ✅ **Version controlled** - changes are visible in PRs
- ✅ **Swift 6.2 compatible** - no plugin compatibility issues

## Setup

The Networking kit must be registered at app startup:

```swift
import Networking

@main
struct AgoraApp: App {
    init() {
        // Register networking services first
        NetworkingServiceFactory.register()
    }
}
```

This explicit registration ensures proper initialization order and avoids hidden dependencies.

## Usage

### Getting an API Client

```swift
import Networking
import AppFoundation

// Via ServiceProvider (recommended)
let apiClient = ServiceProvider.shared.apiClient()

// Or create directly
let client = NetworkingServiceFactory.makeAPIClient(useStub: false)
```

### Making API Calls

```swift
// Fetch feed
let feed = try await apiClient.fetchForYouFeed(cursor: nil, limit: 20)
for post in feed.posts {
    print("Post: \(post.text)")
}

// Sign in with Apple
let beginResponse = try await apiClient.beginSignInWithApple(nonce: "...")
let authResponse = try await apiClient.finishSignInWithApple(
    identityToken: "...",
    authorizationCode: "..."
)
```

### Environment Switching

The factory automatically selects the right implementation:

- **Development** (`mockExternalServices: true`): Uses `StubAgoraClient`
- **Staging/Production** (`mockExternalServices: false`): Uses `OpenAPIAgoraClient`

You can force the stub client in any environment:

```swift
let stubClient = NetworkingServiceFactory.makeAPIClient(
    config: config,
    useStub: true
)
```

## OpenAPI Code Generation

### Prerequisites

- Xcode 15+ with Swift 6.2
- OpenAPI spec at `/OpenAPI/agora.yaml`
- Configuration at `/OpenAPI/openapi-config.yaml`

### Generate Code

From the repository root:

```bash
# Generate client code
make api-gen

# Clean generated code and cached generator
make api-clean
```

### How It Works

1. **Script builds generator**: The script (`Scripts/generate-openapi.sh`) uses SPM to compile `swift-openapi-generator` locally
2. **Version locking**: First successful build is recorded in `OpenAPI/VERSION.lock`
3. **Code generation**: Runs generator with your OpenAPI spec
4. **Output location**: `Packages/Kits/Networking/Sources/Networking/Generated/`
5. **Commit changes**: Generated code is committed to version control

### After Generation

1. **Review changes**: Check `git diff` to see what changed
2. **Update implementations**: Wire generated endpoints into `OpenAPIAgoraClient`
3. **Update models**: Replace hand-written types with generated ones if desired
4. **Test**: Run tests to ensure everything works
5. **Commit**: Commit spec + generated code + VERSION.lock together

### CI Integration

In CI, add a check to ensure generated code is up-to-date:

```bash
make api-gen
git diff --exit-code Packages/Kits/Networking/Sources/Networking/Generated || \
  (echo "❌ Regenerate OpenAPI client before merging" && exit 3)
```

## Testing

### Unit Tests

Test your API client integrations with the stub:

```swift
import XCTest
@testable import Networking

final class MyFeatureTests: XCTestCase {
    func testFeedLoading() async throws {
        let client = StubAgoraClient()
        let feed = try await client.fetchForYouFeed(cursor: nil, limit: 20)
        
        XCTAssertEqual(feed.posts.count, 3)
        XCTAssertNotNil(feed.nextCursor)
    }
}
```

### Integration Tests

Test against real backend with `OpenAPIAgoraClient` in staging environment.

## Error Handling

Network errors are defined in `NetworkError`:

```swift
public enum NetworkError: LocalizedError, Sendable {
    case invalidURL
    case invalidResponse
    case httpError(statusCode: Int, data: Data?)
    case authenticationRequired
    case networkUnavailable
    case timeout
    case rateLimited(retryAfter: TimeInterval?)
    case serverError(message: String)
    // ...
}
```

OpenAPI-generated errors will be mapped to these or exposed directly depending on implementation.

## Dependencies

### External
- `swift-openapi-runtime` - OpenAPI client runtime
- `swift-openapi-urlsession` - URLSession-based transport
- `swift-http-types` - HTTP header types

### Internal
- `AppFoundation` - Configuration and environment management

## File Structure

```
Networking/
├── Package.swift                          # Package manifest with OpenAPI deps
├── README.md                              # This file
├── Sources/
│   └── Networking/
│       ├── Networking.swift               # Main module entry point
│       ├── APIClient.swift                # Legacy/convenience client (optional)
│       ├── AgoraAPIClient.swift           # Protocol and models
│       ├── OpenAPIAgoraClient.swift       # Production implementation
│       ├── StubAgoraClient.swift          # Development/test implementation
│       ├── NetworkingServiceFactory.swift # Service factory integration
│       ├── NetworkError.swift             # Error definitions
│       └── Generated/                     # OpenAPI-generated code (committed)
│           └── *.swift                    # Generated types, endpoints, etc.
└── Tests/
    └── NetworkingTests/
        └── *.swift                        # Unit and integration tests
```

## Migration Notes

### From Old APIClient

If you were using the old `APIClient.performRequest()` pattern, migrate to the DI pattern:

**Before (deprecated):**
```swift
let data = try await APIClient.shared.performRequest(path: "/feed/for-you")
let feed = try JSONDecoder().decode(FeedResponse.self, from: data)
```

**After (with Dependency Injection):**
```swift
// In ViewModel:
public init(networking: any AgoraAPIClient) {
    self.networking = networking
}

// In View:
@Environment(\.deps) private var deps
let viewModel = ForYouViewModel(networking: deps.networking)

// In ViewModel method:
let feed = try await networking.fetchForYouFeed(cursor: nil, limit: 20)
```

**Key Changes:**
- ❌ No more `APIClient.shared` singleton
- ✅ Inject `any AgoraAPIClient` via initializer
- ✅ Use protocol, not concrete class
- ✅ Get from `@Environment(\.deps)` in Views

### Adding New Endpoints

1. Update `OpenAPI/agora.yaml` with new endpoint
2. Run `make api-gen` to regenerate client
3. Add method to `AgoraAPIClient` protocol
4. Implement in `OpenAPIAgoraClient` (wire to generated code)
5. Implement in `StubAgoraClient` (return mock data)
6. Update tests

## Troubleshooting

### Generator Fails to Build

If all version candidates fail to compile:

1. Check Swift version: `swift --version` (should be 6.2+)
2. Check for compiler issues: `swift build --package-path .tools/swift-openapi-generator`
3. Try `make api-clean` and start fresh

### Missing Imports

If you see "Cannot find type 'HTTPRequest'":

- Ensure `HTTPTypes` is in Package.swift dependencies
- Check that imports are present: `import HTTPTypes`

### Generated Code Conflicts

If generated types conflict with hand-written ones:

1. Review `AgoraAPIClient.swift` models
2. Consider removing hand-written versions
3. Or prefix generated types differently in config

## Future Enhancements

- [ ] Retry logic with exponential backoff
- [ ] Request/response logging middleware
- [ ] Metrics collection
- [ ] Cache layer for GET requests
- [ ] Offline support with request queuing
- [ ] WebSocket support for real-time features

## Resources

- [Swift OpenAPI Generator Docs](https://github.com/apple/swift-openapi-generator)
- [OpenAPI Specification](https://swagger.io/specification/)
- [Agora API Spec](/OpenAPI/agora.yaml)
