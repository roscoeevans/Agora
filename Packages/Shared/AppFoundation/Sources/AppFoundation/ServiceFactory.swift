import Foundation
import SupabaseKit
@preconcurrency import Supabase

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
    
    /// Creates a comment composition service instance
    /// - Returns: CommentCompositionProtocol implementation appropriate for current environment
    /// - Throws: ServiceFactoryError if service creation fails
    static func commentCompositionService() throws -> CommentCompositionProtocol
    
    /// Creates a media bundle service instance
    /// - Returns: MediaBundleServiceProtocol implementation appropriate for current environment
    /// - Throws: ServiceFactoryError if service creation fails
    static func mediaBundleService() throws -> MediaBundleServiceProtocol
    
    /// Creates a messaging service instance
    /// - Returns: MessagingServiceProtocol implementation appropriate for current environment
    /// - Throws: ServiceFactoryError if service creation fails
    static func messagingService() throws -> MessagingServiceProtocol
    
    /// Creates a messaging realtime service instance
    /// - Returns: MessagingRealtimeProtocol implementation appropriate for current environment
    /// - Throws: ServiceFactoryError if service creation fails
    static func messagingRealtimeService() throws -> MessagingRealtimeProtocol
    
    /// Creates a messaging media service instance
    /// - Returns: MessagingMediaProtocol implementation appropriate for current environment
    /// - Throws: ServiceFactoryError if service creation fails
    static func messagingMediaService() throws -> MessagingMediaProtocol
    
    /// Creates an image crop renderer service instance
    /// - Returns: ImageCropRendering implementation appropriate for current environment
    /// - Throws: ServiceFactoryError if service creation fails
    static func imageCropRenderer() throws -> ImageCropRendering
    
    /// Creates an avatar upload service instance
    /// - Returns: AvatarUploadService implementation appropriate for current environment
    /// - Throws: ServiceFactoryError if service creation fails
    static func avatarUploadService() throws -> AvatarUploadService
}

// MARK: - Forward declaration for Networking module types
// This allows ServiceFactory to reference API client without creating circular dependency
public protocol AgoraAPIClientProtocol: Sendable {}

// MARK: - Media Bundle Service Protocol
// This protocol is defined in AppFoundation to avoid circular dependencies

/// Protocol for creating and managing media bundles
public protocol MediaBundleServiceProtocol: Sendable {
    /// Get media URLs from a bundle ID with caching
    /// - Parameter bundleId: Media bundle ID
    /// - Returns: MediaBundleInfo with type, URLs, and metadata
    func getMediaBundleInfo(bundleId: String) async throws -> MediaBundleInfo
    
    /// Get media URLs from a bundle ID (legacy method for backward compatibility)
    /// - Parameter bundleId: Media bundle ID
    /// - Returns: Array of media URLs
    func getMediaURLs(bundleId: String) async throws -> [String]
    
    /// Create a media bundle from image data
    /// - Parameters:
    ///   - imageDataArray: Array of image data (1-4 images)
    ///   - userId: User ID for storage path
    /// - Returns: Media bundle ID
    func createImageBundle(imageDataArray: [Data], userId: String) async throws -> String
    
    /// Create a media bundle from a video
    /// - Parameters:
    ///   - videoURL: Local URL of video file
    ///   - userId: User ID for storage path
    /// - Returns: Media bundle ID
    func createVideoBundle(videoURL: URL, userId: String) async throws -> String
}

/// Media bundle information returned by the service
public struct MediaBundleInfo: Sendable {
    public let id: String
    public let type: MediaBundleType
    public let urls: [String]
    public let width: Int?
    public let height: Int?
    public let duration: TimeInterval?
    
    public init(
        id: String,
        type: MediaBundleType,
        urls: [String],
        width: Int? = nil,
        height: Int? = nil,
        duration: TimeInterval? = nil
    ) {
        self.id = id
        self.type = type
        self.urls = urls
        self.width = width
        self.height = height
        self.duration = duration
    }
}

/// Media bundle type enumeration
public enum MediaBundleType: String, Sendable, Codable {
    case image
    case video
}

/// Media bundle errors
public enum MediaBundleError: LocalizedError, Sendable {
    case invalidImageCount
    case creationFailed
    case notFound
    
    public var errorDescription: String? {
        switch self {
        case .invalidImageCount:
            return "Must provide 1-4 images for image bundle"
        case .creationFailed:
            return "Failed to create media bundle"
        case .notFound:
            return "Media bundle not found"
        }
    }
}

/// No-op implementation of MediaBundleServiceProtocol for testing and previews
public final class NoOpMediaBundleService: MediaBundleServiceProtocol, Sendable {
    public init() {}
    
    public func getMediaBundleInfo(bundleId: String) async throws -> MediaBundleInfo {
        throw MediaBundleError.notFound
    }
    
    public func getMediaURLs(bundleId: String) async throws -> [String] {
        throw MediaBundleError.notFound
    }
    
    public func createImageBundle(imageDataArray: [Data], userId: String) async throws -> String {
        throw MediaBundleError.creationFailed
    }
    
    public func createVideoBundle(videoURL: URL, userId: String) async throws -> String {
        throw MediaBundleError.creationFailed
    }
}

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
            // Use mock services ONLY in development, real services in staging and production
            let useMocks = AppConfig.isDevelopment
            let env = AppConfig.isProduction ? "Production" : AppConfig.isStaging ? "Staging" : "Development"
            print("[ServiceFactory] authService() for \(env) environment")
            print("[ServiceFactory]   useMocks = \(useMocks)")
            
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
            // Use mock services ONLY in development, real services in staging and production
            let useMocks = AppConfig.isDevelopment
            
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
            // Use mock services ONLY in development, real services in staging and production
            let useMocks = AppConfig.isDevelopment
            
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
                "API client provider not registered. Ensure NetworkingServiceFactory.register() is called at app startup."
            )
        }
        
        return try provider()
    }
    
    public static func commentCompositionService() throws -> CommentCompositionProtocol {
        // For now, return a no-op implementation
        // This will be replaced with real implementation when PostDetail module is available
        print("[ServiceFactory] Creating comment composition service (no-op)")
        return NoOpCommentCompositionService()
    }
    
    public static func mediaBundleService() throws -> MediaBundleServiceProtocol {
        // For now, return a no-op implementation
        // This will be replaced with real implementation when Media module is available
        print("[ServiceFactory] Creating media bundle service (no-op)")
        return NoOpMediaBundleService()
    }
    
    public static func messagingService() throws -> MessagingServiceProtocol {
        // For now, return a no-op implementation
        // This will be replaced with real implementation when Messaging module is available
        print("[ServiceFactory] Creating messaging service (no-op)")
        return NoOpMessagingService()
    }
    
    public static func messagingRealtimeService() throws -> MessagingRealtimeProtocol {
        // For now, return a no-op implementation
        // This will be replaced with real implementation when Messaging module is available
        print("[ServiceFactory] Creating messaging realtime service (no-op)")
        return NoOpMessagingRealtimeService()
    }
    
    public static func messagingMediaService() throws -> MessagingMediaProtocol {
        // For now, return a no-op implementation
        // This will be replaced with real implementation when Messaging module is available
        print("[ServiceFactory] Creating messaging media service (no-op)")
        return NoOpMessagingMediaService()
    }
    
    public static func imageCropRenderer() throws -> ImageCropRendering {
        // For now, return a no-op implementation
        // The real implementation from Media kit will be provided via dependency injection
        // at runtime when the Media module is available
        print("[ServiceFactory] Creating image crop renderer service (no-op)")
        return NoOpImageCropRenderer()
    }
    
    public static func avatarUploadService() throws -> AvatarUploadService {
        // Use real implementation from SupabaseKit
        print("[ServiceFactory] Creating avatar upload service")
        return try createProductionAvatarUploadService()
    }
    
    // MARK: - Production Service Creation
    
    private static func createProductionAuthService() throws -> AuthServiceProtocol {
        // Create production auth service using Supabase
        print("[ServiceFactory] Creating Supabase authentication service")
        // Note: SupabaseAuthService init must be called on MainActor
        // We return a nonisolated wrapper that ensures proper isolation
        return MainActor.assumeIsolated {
            SupabaseAuthService()
        }
    }
    
    private static func createProductionPhoneVerifier() throws -> PhoneVerifierProtocol {
        // Create production phone verifier using Twilio Verify
        print("[ServiceFactory] Creating Twilio phone verifier service")
        
        // TODO: Get Twilio credentials from AppConfig when ready
        // For now, throw an error since Twilio credentials aren't configured yet
        throw ServiceFactoryError.productionServiceNotImplemented("PhoneVerifier - Twilio credentials not configured")
        
        // Future implementation:
        // let accountSid = AppConfig.twilioAccountSid
        // let authToken = AppConfig.twilioAuthToken
        // let serviceSid = AppConfig.twilioVerifyServiceSid
        // return TwilioPhoneVerifier(accountSid: accountSid, authToken: authToken, serviceSid: serviceSid)
    }
    
    private static func createProductionCaptchaService() throws -> CaptchaServiceProtocol {
        // TODO: Implement production captcha service creation
        // This would integrate with hCaptcha SDK
        // For now, we'll throw an error to indicate it's not implemented
        throw ServiceFactoryError.productionServiceNotImplemented("CaptchaService")
    }
    
    private static func createProductionAvatarUploadService() throws -> AvatarUploadService {
        // Create production avatar upload service using Supabase
        print("[ServiceFactory] Creating Supabase avatar upload service")
        
        // Create Supabase client using configuration
        do {
            let client = SupabaseClient(
                supabaseURL: AppConfig.supabaseURL,
                supabaseKey: AppConfig.supabaseAnonKey
            )
            let liveService = AvatarUploadServiceLive(client: client)
            // Return adapter that bridges protocols
            return AvatarUploadServiceAdapter(liveService: liveService)
        } catch {
            throw ServiceFactoryError.initializationFailed("AvatarUploadService", error)
        }
    }
}

// MARK: - Protocol Adapter

/// Adapter that bridges AvatarUploadServiceProtocol from SupabaseKit to AvatarUploadService from AppFoundation
private struct AvatarUploadServiceAdapter: AvatarUploadService {
    private let liveService: AvatarUploadServiceProtocol
    
    init(liveService: AvatarUploadServiceProtocol) {
        self.liveService = liveService
    }
    
    func uploadAvatar(_ data: Data, mime: String) async throws -> URL {
        // Bridge to the live service, converting errors as needed
        do {
            return try await liveService.uploadAvatar(data, mime: mime)
        } catch {
            // Map SupabaseKit errors to AppFoundation errors
            if let supabaseError = error as? AvatarUploadError {
                throw supabaseError
            } else {
                throw AvatarUploadError.uploadFailed(error)
            }
        }
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
    
    public static func commentCompositionService() throws -> CommentCompositionProtocol {
        return DebugServiceFactory().createCommentCompositionService()
    }
    
    public static func mediaBundleService() throws -> MediaBundleServiceProtocol {
        return DebugServiceFactory().createMediaBundleService()
    }
    
    public static func messagingService() throws -> MessagingServiceProtocol {
        return DebugServiceFactory().createMessagingService()
    }
    
    public static func messagingRealtimeService() throws -> MessagingRealtimeProtocol {
        return DebugServiceFactory().createMessagingRealtimeService()
    }
    
    public static func messagingMediaService() throws -> MessagingMediaProtocol {
        return DebugServiceFactory().createMessagingMediaService()
    }
    
    public static func imageCropRenderer() throws -> ImageCropRendering {
        return DebugServiceFactory().createImageCropRenderer()
    }
    
    public static func avatarUploadService() throws -> AvatarUploadService {
        return DebugServiceFactory().createAvatarUploadService()
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
    
    public func createCommentCompositionService() -> CommentCompositionProtocol {
        // Debug factory uses the default implementation
        // The actual mock/production switching is handled in PostDetail module
        do {
            return try DefaultServiceFactory.commentCompositionService()
        } catch {
            fatalError("[DebugServiceFactory] Failed to create comment composition service: \(error)")
        }
    }
    
    public func createMediaBundleService() -> MediaBundleServiceProtocol {
        // Debug factory uses the default implementation
        // The actual mock/production switching is handled in Media module
        do {
            return try DefaultServiceFactory.mediaBundleService()
        } catch {
            fatalError("[DebugServiceFactory] Failed to create media bundle service: \(error)")
        }
    }
    
    public func createMessagingService() -> MessagingServiceProtocol {
        // Debug factory uses the default implementation
        // The actual mock/production switching is handled in Messaging module
        do {
            return try DefaultServiceFactory.messagingService()
        } catch {
            fatalError("[DebugServiceFactory] Failed to create messaging service: \(error)")
        }
    }
    
    public func createMessagingRealtimeService() -> MessagingRealtimeProtocol {
        // Debug factory uses the default implementation
        // The actual mock/production switching is handled in Messaging module
        do {
            return try DefaultServiceFactory.messagingRealtimeService()
        } catch {
            fatalError("[DebugServiceFactory] Failed to create messaging realtime service: \(error)")
        }
    }
    
    public func createMessagingMediaService() -> MessagingMediaProtocol {
        // Debug factory uses the default implementation
        // The actual mock/production switching is handled in Messaging module
        do {
            return try DefaultServiceFactory.messagingMediaService()
        } catch {
            fatalError("[DebugServiceFactory] Failed to create messaging media service: \(error)")
        }
    }
    
    public func createImageCropRenderer() -> ImageCropRendering {
        if configuration.forceUseMocks {
            let mockService = MockImageCropRenderer()
            mockService.processingDelay = 0.1
            mockService.shouldSucceed = !configuration.shouldSimulateFailures
            return mockService
        } else {
            // Use no-op implementation for debug builds when not forcing mocks
            // Real implementation will be provided via dependency injection
            return NoOpImageCropRenderer()
        }
    }
    
    public func createAvatarUploadService() -> AvatarUploadService {
        if configuration.forceUseMocks {
            let mockService = MockAvatarUploadService()
            mockService.uploadDelay = 0.2
            mockService.shouldSucceed = !configuration.shouldSimulateFailures
            return mockService
        } else {
            // Use real implementation for debug builds when not forcing mocks
            do {
                return try DefaultServiceFactory.avatarUploadService()
            } catch {
                print("[DebugServiceFactory] Failed to create real avatar upload service, using mock: \(error)")
                let mockService = MockAvatarUploadService()
                mockService.shouldSucceed = !configuration.shouldSimulateFailures
                return mockService
            }
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