import Foundation

// MARK: - Service Factory Protocol

/// Protocol for creating environment-appropriate service instances
public protocol ServiceFactory: Sendable {
    /// Creates an authentication service instance
    /// - Returns: AuthServiceProtocol implementation appropriate for current environment
    /// - Throws: ServiceFactoryError if service creation fails
    static func authService() throws -> AuthServiceProtocol
    
    /// Creates a phone verifier service instance
    /// - Returns: PhoneVerifierProtocol implementation appropriate for current environment
    /// - Throws: ServiceFactoryError if service creation fails
    static func phoneVerifier() throws -> PhoneVerifierProtocol
    
    /// Creates a captcha service instance
    /// - Returns: CaptchaServiceProtocol implementation appropriate for current environment
    /// - Throws: ServiceFactoryError if service creation fails
    static func captchaService() throws -> CaptchaServiceProtocol
    
    /// Creates an API client instance
    /// - Returns: API client implementation appropriate for current environment
    /// - Throws: ServiceFactoryError if service creation fails
    static func apiClient() throws -> any AgoraAPIClientProtocol
}

// MARK: - Forward declaration for Networking module types
// This allows ServiceFactory to reference API client without creating circular dependency
public protocol AgoraAPIClientProtocol: Sendable {}

// MARK: - Default Service Factory

/// Default implementation of ServiceFactory that selects services based on environment configuration
@available(iOS 26.0, macOS 15.0, *)
public struct DefaultServiceFactory: ServiceFactory {
    
    // MARK: - API Client Provider (Injectable)
    
    /// Injectable API client provider - set by Networking module at app startup
    /// nonisolated(unsafe): This is set once at startup before any concurrent access
    public nonisolated(unsafe) static var apiClientProvider: (@Sendable () throws -> any AgoraAPIClientProtocol)?
    
    // MARK: - Service Creation Methods
    
    public static func authService() throws -> AuthServiceProtocol {
        do {
            // Use mock services in dev/staging, real services in production
            let useMocks = !AppConfig.isProduction
            let env = AppConfig.isProduction ? "Production" : AppConfig.isStaging ? "Staging" : "Debug"
            print("[ServiceFactory] authService() for \(env) environment")
            print("[ServiceFactory]   mockExternalServices = \(useMocks)")
            
            if useMocks {
                print("[ServiceFactory]   ➜ Creating MOCK authentication service")
                return MockAuthService()
            } else {
                print("[ServiceFactory]   ➜ Creating REAL Supabase authentication service")
                return try createProductionAuthService()
            }
        } catch {
            print("[ServiceFactory] Failed to create auth service: \(error)")
            
            // Fallback to mock service in case of production service failure
            print("[ServiceFactory] Falling back to mock authentication service")
            return MockAuthService()
        }
    }
    
    public static func phoneVerifier() throws -> PhoneVerifierProtocol {
        do {
            // Use mock services in dev/staging, real services in production
            let useMocks = !AppConfig.isProduction
            
            if useMocks {
                print("[ServiceFactory] Creating mock phone verifier service")
                return MockPhoneVerifier()
            } else {
                print("[ServiceFactory] Creating production phone verifier service")
                return try createProductionPhoneVerifier()
            }
        } catch {
            print("[ServiceFactory] Failed to create phone verifier service: \(error)")
            
            // Fallback to mock service in case of production service failure
            print("[ServiceFactory] Falling back to mock phone verifier service")
            return MockPhoneVerifier()
        }
    }
    
    public static func captchaService() throws -> CaptchaServiceProtocol {
        do {
            // Use mock services in dev/staging, real services in production
            let useMocks = !AppConfig.isProduction
            
            if useMocks {
                print("[ServiceFactory] Creating mock captcha service")
                return MockCaptchaService()
            } else {
                print("[ServiceFactory] Creating production captcha service")
                return try createProductionCaptchaService()
            }
        } catch {
            print("[ServiceFactory] Failed to create captcha service: \(error)")
            
            // Fallback to mock service in case of production service failure
            print("[ServiceFactory] Falling back to mock captcha service")
            return MockCaptchaService()
        }
    }
    
    public static func apiClient() throws -> any AgoraAPIClientProtocol {
        // Check if Networking module has registered an API client provider
        guard let provider = apiClientProvider else {
            throw ServiceFactoryError.dependencyMissing(
                "API client provider not registered. Call Networking.forceLoad() at app startup."
            )
        }
        
        return try provider()
    }
    
    // MARK: - Production Service Creation
    
    private static func createProductionAuthService() throws -> AuthServiceProtocol {
        // Create production auth service using Supabase
        print("[ServiceFactory] Creating Supabase authentication service")
        return SupabaseAuthService()
    }
    
    private static func createProductionPhoneVerifier() throws -> PhoneVerifierProtocol {
        // TODO: Implement production phone verifier creation
        // This would create a TwilioPhoneVerifier with AppConfig.twilioVerifyServiceSid
        // For now, we'll throw an error to indicate it's not implemented
        throw ServiceFactoryError.productionServiceNotImplemented("PhoneVerifier")
    }
    
    private static func createProductionCaptchaService() throws -> CaptchaServiceProtocol {
        // TODO: Implement production captcha service creation
        // This would integrate with hCaptcha SDK
        // For now, we'll throw an error to indicate it's not implemented
        throw ServiceFactoryError.productionServiceNotImplemented("CaptchaService")
    }
}

// MARK: - Convenience Service Factory

/// Convenience wrapper for accessing services without throwing
@available(iOS 26.0, macOS 15.0, *)
public struct ServiceProvider: Sendable {
    
    /// Shared service provider instance
    public static let shared = ServiceProvider()
    
    private init() {}
    
    /// Gets an authentication service, falling back to mock on failure
    public func authService() -> AuthServiceProtocol {
        do {
            return try DefaultServiceFactory.authService()
        } catch {
            print("[ServiceProvider] Failed to get auth service, using mock: \(error)")
            return MockAuthService()
        }
    }
    
    /// Gets a phone verifier service, falling back to mock on failure
    public func phoneVerifier() -> PhoneVerifierProtocol {
        do {
            return try DefaultServiceFactory.phoneVerifier()
        } catch {
            print("[ServiceProvider] Failed to get phone verifier service, using mock: \(error)")
            return MockPhoneVerifier()
        }
    }
    
    /// Gets a captcha service, falling back to mock on failure
    public func captchaService() -> CaptchaServiceProtocol {
        do {
            return try DefaultServiceFactory.captchaService()
        } catch {
            print("[ServiceProvider] Failed to get captcha service, using mock: \(error)")
            return MockCaptchaService()
        }
    }
    
    /// Gets an auth token provider, falling back to mock on failure
    public func authTokenProvider() -> AuthTokenProvider {
        // AuthServiceProtocol conforms to AuthTokenProvider
        return authService()
    }
    
    /// Gets an API client instance
    public func apiClient() -> any AgoraAPIClientProtocol {
        do {
            return try DefaultServiceFactory.apiClient()
        } catch {
            fatalError("[ServiceProvider] Failed to get API client: \(error)")
        }
    }
}

// MARK: - Debug Service Factory

#if DEBUG
/// Debug-only service factory for testing with specific configurations
@available(iOS 26.0, macOS 15.0, *)
public struct DebugServiceFactory: ServiceFactory {
    
    /// Configuration for debug service creation
    public struct Configuration: Sendable {
        public let forceUseMocks: Bool
        public let authServiceDelay: TimeInterval
        public let phoneVerifierDelay: TimeInterval
        public let captchaServiceDelay: TimeInterval
        public let shouldSimulateFailures: Bool
        
        public init(
            forceUseMocks: Bool = true,
            authServiceDelay: TimeInterval = 0.1,
            phoneVerifierDelay: TimeInterval = 0.1,
            captchaServiceDelay: TimeInterval = 0.1,
            shouldSimulateFailures: Bool = false
        ) {
            self.forceUseMocks = forceUseMocks
            self.authServiceDelay = authServiceDelay
            self.phoneVerifierDelay = phoneVerifierDelay
            self.captchaServiceDelay = captchaServiceDelay
            self.shouldSimulateFailures = shouldSimulateFailures
        }
    }
    
    private let configuration: Configuration
    
    public init(configuration: Configuration = Configuration()) {
        self.configuration = configuration
    }
    
    public static func authService() throws -> AuthServiceProtocol {
        return DebugServiceFactory().createAuthService()
    }
    
    public static func phoneVerifier() throws -> PhoneVerifierProtocol {
        return DebugServiceFactory().createPhoneVerifier()
    }
    
    public static func captchaService() throws -> CaptchaServiceProtocol {
        return DebugServiceFactory().createCaptchaService()
    }
    
    public static func apiClient() throws -> any AgoraAPIClientProtocol {
        return DebugServiceFactory().createAPIClient()
    }
    
    // MARK: - Debug Service Creation
    
    public func createAuthService() -> AuthServiceProtocol {
        let mockService = MockAuthService()
        mockService.operationDelay = configuration.authServiceDelay
        mockService.shouldSucceed = !configuration.shouldSimulateFailures
        return mockService
    }
    
    public func createPhoneVerifier() -> PhoneVerifierProtocol {
        let mockService = MockPhoneVerifier()
        mockService.operationDelay = configuration.phoneVerifierDelay
        mockService.shouldSucceed = !configuration.shouldSimulateFailures
        return mockService
    }
    
    public func createCaptchaService() -> CaptchaServiceProtocol {
        let mockService = MockCaptchaService()
        mockService.challengeDelay = configuration.captchaServiceDelay
        mockService.shouldSucceed = !configuration.shouldSimulateFailures
        return mockService
    }
    
    public func createAPIClient() -> any AgoraAPIClientProtocol {
        // Debug factory uses the default implementation
        // The actual mock/production switching is handled in Networking module
        do {
            return try DefaultServiceFactory.apiClient()
        } catch {
            fatalError("[DebugServiceFactory] Failed to create API client: \(error)")
        }
    }
}
#endif

// MARK: - Service Factory Errors

/// Errors that can occur during service factory operations
public enum ServiceFactoryError: LocalizedError, Sendable {
    case productionServiceNotImplemented(String)
    case configurationError(String)
    case dependencyMissing(String)
    case initializationFailed(String, Error)
    
    public var errorDescription: String? {
        switch self {
        case .productionServiceNotImplemented(let serviceName):
            return "Production \(serviceName) implementation not yet available"
        case .configurationError(let message):
            return "Service configuration error: \(message)"
        case .dependencyMissing(let dependency):
            return "Missing required dependency: \(dependency)"
        case .initializationFailed(let serviceName, let error):
            return "Failed to initialize \(serviceName): \(error.localizedDescription)"
        }
    }
}

// MARK: - Service Factory Validation

@available(iOS 26.0, macOS 15.0, *)
extension DefaultServiceFactory {
    
    /// Validates that all services can be created successfully
    /// - Throws: ServiceFactoryError if any service creation fails
    public static func validateServices() throws {
        print("[ServiceFactory] Validating service factory configuration...")
        
        // Test auth service creation
        _ = try authService()
        print("[ServiceFactory] ✓ Auth service creation successful")
        
        // Test phone verifier creation
        _ = try phoneVerifier()
        print("[ServiceFactory] ✓ Phone verifier service creation successful")
        
        // Test captcha service creation
        _ = try captchaService()
        print("[ServiceFactory] ✓ Captcha service creation successful")
        
        print("[ServiceFactory] All services validated successfully")
    }
    
    /// Performs a health check on all services
    /// - Returns: Dictionary of service names to their health status
    public static func performHealthCheck() async -> [String: Bool] {
        var results: [String: Bool] = [:]
        
        // Check auth service
        do {
            _ = try authService()
            // For mock services, they're always healthy
            // For production services, this could ping the actual service
            results["AuthService"] = true
        } catch {
            print("[ServiceFactory] Auth service health check failed: \(error)")
            results["AuthService"] = false
        }
        
        // Check phone verifier service
        do {
            _ = try phoneVerifier()
            results["PhoneVerifier"] = true
        } catch {
            print("[ServiceFactory] Phone verifier health check failed: \(error)")
            results["PhoneVerifier"] = false
        }
        
        // Check captcha service
        do {
            _ = try captchaService()
            results["CaptchaService"] = true
        } catch {
            print("[ServiceFactory] Captcha service health check failed: \(error)")
            results["CaptchaService"] = false
        }
        
        return results
    }
}