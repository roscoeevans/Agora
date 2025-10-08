# Networking

The Networking module provides HTTP client functionality for the Agora iOS app, including OpenAPI-generated models, authentication, and retry logic.

## Features

- **OpenAPI Integration**: Automatically generated client code from the Agora API specification
- **Authentication**: Automatic token injection via `AuthTokenProvider` protocol
- **Retry Logic**: Exponential backoff retry mechanism for failed requests
- **Error Handling**: Comprehensive error mapping and handling
- **Logging**: Structured logging for debugging and monitoring

## Usage

### Basic Setup

```swift
import Networking
import AppFoundation

// Create API client with authentication
let authProvider = MyAuthTokenProvider()
let apiClient = APIClient(
    baseURL: URL(string: "https://api.agora.app/v1")!,
    authTokenProvider: authProvider
)
```

### Feed Operations

```swift
// Get For You feed
let feedResponse = try await apiClient.getForYouFeed(limit: 20)
print("Received \(feedResponse.posts.count) posts")

// Get next page
if let nextCursor = feedResponse.nextCursor {
    let nextPage = try await apiClient.getForYouFeed(cursor: nextCursor, limit: 20)
}
```

### Authentication

```swift
// Begin Sign in with Apple flow
let nonce = UUID().uuidString
let beginResponse = try await apiClient.beginSignInWithApple(nonce: nonce)

// Complete authentication
let authResponse = try await apiClient.finishSignInWithApple(
    identityToken: identityToken,
    authorizationCode: authorizationCode
)
```

### Error Handling

```swift
do {
    let feed = try await apiClient.getForYouFeed()
} catch NetworkError.authenticationRequired {
    // Handle authentication required
} catch NetworkError.networkUnavailable {
    // Handle network issues
} catch {
    // Handle other errors
}
```

## Architecture

### Components

- **APIClient**: Main client class with convenience methods
- **AuthInterceptor**: Middleware for automatic token injection
- **RetryInterceptor**: Middleware for exponential backoff retry logic
- **NetworkError**: Comprehensive error types
- **Generated Types**: OpenAPI-generated models and client code

### Dependencies

- **AppFoundation**: For `AuthTokenProvider` protocol and logging
- **OpenAPIRuntime**: For OpenAPI client functionality
- **OpenAPIURLSession**: For URLSession transport

## Configuration

The module uses OpenAPI Generator to create client code from `openapi.yaml`. The configuration is in `openapi-generator-config.yaml`:

```yaml
generate:
  - types
  - client
accessModifier: public
```

## Testing

Run tests with:

```bash
swift test
```

The module includes basic unit tests and can be extended with mock implementations for testing.