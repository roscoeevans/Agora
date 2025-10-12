# Design Document

## Overview

The environment strategy implements a build-time environment selection system that extends the existing Agora iOS app architecture. The design leverages Xcode's build configuration system to provide clean separation between development, staging, and production environments while maintaining simplicity for solo development.

The system builds upon existing infrastructure including:
- Current xcconfig files in `Configs/Xcode/`
- AppFoundation module for shared utilities
- Protocol-based architecture for service abstraction
- Existing Secrets.plist structure

## Architecture

### Environment Detection

The system uses Swift compilation conditions to determine the current environment at build time:

```swift
enum Environment: String, CaseIterable {
    case development = "development"
    case staging = "staging" 
    case production = "production"
    
    static var current: Environment {
        #if DEVELOPMENT
        return .development
        #elseif STAGING
        return .staging
        #else
        return .production
        #endif
    }
}
```

### Build Configuration Structure

The system extends existing xcconfig files with environment-specific variants:

```
Configs/Xcode/
├── Base.xcconfig              # Shared settings (new)
├── Debug.xcconfig             # Extends Base (existing, modified)
├── Release.xcconfig           # Extends Base (existing, modified)
├── Debug-Development.xcconfig # Development environment (new)
├── Debug-Staging.xcconfig     # Staging environment (new)
├── Release-Staging.xcconfig   # Staging release builds (new)
└── Release-Production.xcconfig # Production builds (new)
```

### Base Configuration Structure

The Base.xcconfig contains all shared settings:

```
// Base.xcconfig - Shared settings across all environments
SWIFT_VERSION = 6.2
IPHONEOS_DEPLOYMENT_TARGET = 18.0
TARGETED_DEVICE_FAMILY = 1,2
SWIFT_PACKAGE_MANAGER = YES
OTHER_SWIFT_FLAGS = -strict-concurrency=complete

// Environment-specific overrides
AGORA_ENV = $(AGORA_ENV)
SWIFT_ACTIVE_COMPILATION_CONDITIONS = $(SWIFT_ACTIVE_COMPILATION_CONDITIONS)
```

### Secrets Management Architecture

Environment-specific configuration uses separate plist files:

```
Resources/Configs/
├── Development.plist          # Dev secrets (gitignored)
├── Staging.plist             # Staging secrets (gitignored)
├── Production.plist          # Production secrets (gitignored)
├── Development.plist.example # Example with fake values
├── Staging.plist.example     # Example with fake values
└── Production.plist.example  # Example with fake values
```

### Service Factory Pattern

The system uses a factory pattern to provide environment-appropriate service implementations:

```swift
protocol ServiceFactory {
    static func authService() -> AuthServiceProtocol
    static func phoneVerifier() -> PhoneVerifierProtocol
    static func captchaService() -> CaptchaServiceProtocol
}

struct DefaultServiceFactory: ServiceFactory {
    static func authService() -> AuthServiceProtocol {
        AppConfig.shared.mockExternalServices ? 
            MockAuthService() : ProductionAuthService()
    }
}
```

## Components and Interfaces

### AppConfig Component

Central configuration component integrated into AppFoundation module:

```swift
public struct AppConfig: Sendable {
    public let environment: Environment
    public let apiBaseURL: URL
    public let webShareBaseURL: URL
    public let supabaseURL: URL
    public let supabaseAnonKey: String
    public let posthogKey: String
    public let sentryDSN: String
    public let twilioVerifyServiceSid: String
    public let oneSignalAppId: String
    public let mockExternalServices: Bool
    
    public static let shared = AppConfig.load()
    
    /// Validate configuration for current environment
    public static func validate() throws {
        #if DEBUG
        // Validate environment-specific requirements
        if shared.environment == .production && shared.mockExternalServices {
            throw ConfigurationError.invalidProductionConfiguration
        }
        
        // Validate bundle identifier matches environment
        let bundleId = Bundle.main.bundleIdentifier ?? ""
        switch shared.environment {
        case .development:
            assert(bundleId.contains("dev"), "Development environment should use dev bundle ID")
        case .staging:
            assert(bundleId.contains("stg"), "Staging environment should use staging bundle ID")
        case .production:
            assert(!bundleId.contains("dev") && !bundleId.contains("stg"), "Production should use clean bundle ID")
        }
        #endif
    }
}
```

### Environment Indicator Component

Visual environment indicator for development and staging builds:

```swift
public struct EnvironmentBadge: View {
    public var body: some View {
        if AppConfig.shared.environment != .production {
            Text(AppConfig.shared.environment.rawValue.uppercased())
                .font(.caption2)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(badgeColor)
                .foregroundColor(.white)
                .cornerRadius(4)
        }
    }
}
```

### Mock Service Interfaces

Consistent interfaces for mock and production services:

```swift
// Auth Service Protocol
public protocol AuthServiceProtocol: Sendable {
    func signInWithApple() async throws -> AuthResult
    func signOut() async throws
    func refreshToken() async throws -> String
}

// Phone Verification Protocol  
public protocol PhoneVerifierProtocol: Sendable {
    func sendVerificationCode(to phoneNumber: String) async throws
    func verifyCode(_ code: String, for phoneNumber: String) async throws -> Bool
}

// Captcha Service Protocol
public protocol CaptchaServiceProtocol: Sendable {
    func presentCaptcha() async throws -> String
    func verifyCaptcha(token: String) async throws -> Bool
}
```

### Debug Menu Component

Development-only debug menu for toggling mock services:

```swift
#if DEBUG
public struct DebugMenu: View {
    @State private var mockServicesEnabled = AppConfig.shared.mockExternalServices
    
    public var body: some View {
        NavigationView {
            Form {
                Section("Mock Services") {
                    Toggle("Enable Mock Services", isOn: $mockServicesEnabled)
                        .onChange(of: mockServicesEnabled) { newValue in
                            DebugSettings.shared.setMockServices(enabled: newValue)
                        }
                }
            }
            .navigationTitle("Debug Settings")
        }
    }
}
#endif
```

## Data Models

### Environment Configuration Schema

Standardized plist schema for all environments:

```xml
<plist version="1.0">
<dict>
    <key>apiBaseURL</key>
    <string>https://api.{env}.agora.app</string>
    
    <key>webShareBaseURL</key>
    <string>https://{env}.agora.app/p</string>
    
    <key>supabaseURL</key>
    <string>https://{project-id}.supabase.co</string>
    
    <key>supabaseAnonKey</key>
    <string>{environment-specific-key}</string>
    
    <key>posthogKey</key>
    <string>phc_{env}_key</string>
    
    <key>sentryDSN</key>
    <string>https://...{env}@sentry.io/...</string>
    
    <key>twilioVerifyServiceSid</key>
    <string>VA_{env}_sid</string>
    
    <key>oneSignalAppId</key>
    <string>{env}-onesignal-id</string>
    
    <key>mockExternalServices</key>
    <true/>
</dict>
</plist>
```

### Xcode Scheme Configuration

Environment-specific build settings:

```
# Debug-Development.xcconfig
#include "Base.xcconfig"
PRODUCT_BUNDLE_IDENTIFIER = app.agora.ios.dev
INFOPLIST_KEY_CFBundleDisplayName = Agora Dev
SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG DEVELOPMENT
AGORA_ENV = development

# Debug-Staging.xcconfig  
#include "Base.xcconfig"
PRODUCT_BUNDLE_IDENTIFIER = app.agora.ios.stg
INFOPLIST_KEY_CFBundleDisplayName = Agora Staging
SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG STAGING
AGORA_ENV = staging

# Release-Production.xcconfig
#include "Base.xcconfig"
PRODUCT_BUNDLE_IDENTIFIER = app.agora.ios
INFOPLIST_KEY_CFBundleDisplayName = Agora
SWIFT_ACTIVE_COMPILATION_CONDITIONS = 
AGORA_ENV = production
```

## Error Handling

### Configuration Loading Errors

Fail-fast approach with clear error messages:

```swift
enum ConfigurationError: LocalizedError {
    case missingConfigFile(environment: String)
    case invalidConfigFormat(environment: String)
    case missingRequiredKey(key: String, environment: String)
    case invalidURL(key: String, value: String)
    case invalidProductionConfiguration
    
    var errorDescription: String? {
        switch self {
        case .missingConfigFile(let env):
            return "Missing configuration file for \(env) environment"
        case .invalidConfigFormat(let env):
            return "Invalid plist format in \(env) configuration"
        case .missingRequiredKey(let key, let env):
            return "Missing required key '\(key)' in \(env) configuration"
        case .invalidURL(let key, let value):
            return "Invalid URL for key '\(key)': \(value)"
        case .invalidProductionConfiguration:
            return "Production environment cannot use mock services"
        }
    }
}
```

### Service Factory Error Handling

Graceful fallback for service creation failures:

```swift
extension DefaultServiceFactory {
    static func authService() -> AuthServiceProtocol {
        do {
            return AppConfig.shared.mockExternalServices ? 
                MockAuthService() : try ProductionAuthService()
        } catch {
            Logger.shared.error("Failed to create auth service: \(error)")
            return MockAuthService() // Fallback to mock
        }
    }
}
```

### Debug Assertions

Development-time safety checks:

```swift
#if DEBUG
private static func validateConfiguration() {
    assert(
        AppConfig.shared.environment != .production || !AppConfig.shared.mockExternalServices,
        "Production environment should not use mock services"
    )
    
    assert(
        Bundle.main.bundleIdentifier?.contains("dev") != true || AppConfig.shared.environment == .development,
        "Development bundle ID should only be used in development environment"
    )
}
#endif
```

## Testing Strategy

### Unit Testing Approach

- All tests use mock services by default
- Environment-specific configuration loading tests
- Service factory tests for all environments
- Mock service implementation tests

### Integration Testing Strategy

- Development environment: Mix of mock and real services
- Staging environment: Real services with test accounts
- Production environment: Real services (limited testing)

### Mock Service Testing

```swift
class MockAuthServiceTests: XCTestCase {
    func testSignInWithApple() async throws {
        let mockAuth = MockAuthService()
        let result = try await mockAuth.signInWithApple()
        
        XCTAssertNotNil(result.accessToken)
        XCTAssertNotNil(result.user)
        XCTAssertEqual(result.user.email, "test@example.com")
    }
}
```

### Configuration Testing

```swift
class AppConfigTests: XCTestCase {
    func testDevelopmentConfiguration() {
        // Test with mock development plist
        let config = AppConfig.loadFromBundle(environment: .development)
        
        XCTAssertEqual(config.environment, .development)
        XCTAssertTrue(config.apiBaseURL.absoluteString.contains("dev"))
        XCTAssertTrue(config.mockExternalServices)
    }
}
```

## Implementation Notes

### Integration with Existing APIClient

The existing APIClient will be updated to use environment-specific configuration:

```swift
public final class APIClient: Sendable {
    public static let shared = APIClient(
        baseURL: AppConfig.shared.apiBaseURL,
        authTokenProvider: ServiceFactory.authTokenProvider()
    )
}
```

### Supabase Integration

Environment-specific Supabase configuration:

```swift
extension AppConfig {
    var supabaseConfiguration: SupabaseConfiguration {
        SupabaseConfiguration(
            url: supabaseURL,
            anonKey: supabaseAnonKey,
            environment: environment.rawValue
        )
    }
}
```

### Universal Links Configuration

Environment-specific associated domains in entitlements:

```xml
<!-- Development -->
<key>com.apple.developer.associated-domains</key>
<array>
    <string>applinks:dev.agora.app</string>
</array>

<!-- Staging -->
<key>com.apple.developer.associated-domains</key>
<array>
    <string>applinks:staging.agora.app</string>
</array>

<!-- Production -->
<key>com.apple.developer.associated-domains</key>
<array>
    <string>applinks:agora.app</string>
</array>
```

### Push Notification Configuration

Environment-specific APN settings:

```xml
<!-- Development/Staging -->
<key>aps-environment</key>
<string>development</string>

<!-- Production -->
<key>aps-environment</key>
<string>production</string>
```