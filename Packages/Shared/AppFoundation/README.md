# AppFoundation

The AppFoundation shared module provides core utilities, extensions, and protocols used throughout the Agora iOS app. This module serves as the foundation layer for all other modules.

## Purpose

This module contains essential utilities, logging infrastructure, validation helpers, and protocol definitions that are shared across the entire application. It prevents circular dependencies by providing common interfaces.

## Key Components

- **Logger**: Structured logging system for debugging and monitoring
- **DateFormatter+Extensions**: Standardized date formatting utilities
- **ValidationHelpers**: Input validation and sanitization functions
- **AuthTokenProvider**: Protocol for authentication token access

## Dependencies

None - This is a foundation module with no external dependencies.

## Usage

```swift
import AppFoundation

// Logging
Logger.shared.info("User action completed", metadata: ["userId": userId])

// Date formatting
let formattedDate = DateFormatter.agora.string(from: date)

// Validation
let isValid = ValidationHelpers.isValidEmail(email)

// Token provider (implemented by Auth module)
class MyAuthManager: AuthTokenProvider {
    func currentAccessToken() async throws -> String? {
        // Implementation
    }
}
```

## Key Protocols

### AuthTokenProvider

```swift
public protocol AuthTokenProvider: Sendable {
    func currentAccessToken() async throws -> String?
}
```

This protocol prevents circular dependencies between Auth and Networking modules by providing a common interface for token access.

## Architecture

The module provides:

- **Utilities**: Common helper functions and extensions
- **Protocols**: Shared interfaces to prevent circular dependencies
- **Logging**: Centralized logging infrastructure
- **Validation**: Input validation and sanitization

## Testing

Run tests using:
```bash
swift test --package-path Packages/Shared/AppFoundation
```

The module includes unit tests for all utility functions and validation logic.