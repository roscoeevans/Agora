import Foundation
import SupabaseKit

/// Centralized Supabase client configuration and access
/// @unchecked Sendable: SupabaseClientProtocol implementations are thread-safe
public final class AgoraSupabaseClient: @unchecked Sendable {
    public static let shared = AgoraSupabaseClient()

    public let client: SupabaseClientProtocol

    private init() {
        // Create live implementation using SupabaseKit
        self.client = SupabaseClientLive(
            url: AppConfig.supabaseURL.absoluteString,
            key: AppConfig.supabaseAnonKey
        )

        // Configure auth callback handling
        setupAuthCallbacks()
    }

    /// Access to Supabase Auth
    public var auth: SupabaseAuthProtocol {
        return client.auth
    }

    /// Access to Supabase Database
    public var database: SupabaseDatabaseProtocol {
        return client.database
    }

    /// Access to Supabase Storage  
    public var storage: SupabaseStorageProtocol {
        return client.storage
    }

    /// Access to Supabase Realtime
    public var realtime: SupabaseRealtimeProtocol {
        return client.realtime
    }

    /// Check if the client is properly configured
    public func isConfigured() -> Bool {
        return !AppConfig.supabaseURL.absoluteString.contains("placeholder") &&
               !AppConfig.supabaseAnonKey.contains("placeholder")
    }

    /// Perform a health check on the Supabase connection
    public func performHealthCheck() async -> Bool {
        // Try to fetch current session to verify connection
        let session = await client.auth.session
        return session != nil
    }

    // MARK: - Private Methods

    private func setupAuthCallbacks() {
        // Handle auth state changes if needed
        // This can be used to sync with your app's auth state
    }
}

// MARK: - Convenience Extensions

extension AgoraSupabaseClient {
    /// Convenience method to get current session safely
    public func currentSession() async -> AuthSession? {
        return await self.auth.session
    }

    /// Convenience method to check if user is authenticated
    public func isAuthenticated() async -> Bool {
        return await self.auth.session != nil
    }
}

// MARK: - Error Types

public enum SupabaseClientError: LocalizedError, Sendable {
    case notConfigured
    case connectionFailed
    case authenticationFailed
    case invalidConfiguration

    public var errorDescription: String? {
        switch self {
        case .notConfigured:
            return "Supabase client is not properly configured"
        case .connectionFailed:
            return "Failed to connect to Supabase"
        case .authenticationFailed:
            return "Authentication with Supabase failed"
        case .invalidConfiguration:
            return "Invalid Supabase configuration"
        }
    }
}
