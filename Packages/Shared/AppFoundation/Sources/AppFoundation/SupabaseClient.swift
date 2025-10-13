import Foundation
import Supabase

/// Centralized Supabase client configuration and access
/// @unchecked Sendable: SupabaseClient is thread-safe in practice via its actor-based architecture
public final class AgoraSupabaseClient: @unchecked Sendable {
    public static let shared = AgoraSupabaseClient()

    public let client: SupabaseClient

    private init() {
        self.client = SupabaseClient(
            supabaseURL: AppConfig.supabaseURL,
            supabaseKey: AppConfig.supabaseAnonKey,
            options: SupabaseClientOptions(
                auth: .init(
                    redirectToURL: URL(string: "\(AppConfig.webShareBaseURL)/auth/callback")
                ),
                global: .init(
                    headers: [
                        "X-Client-Info": "agora-ios/\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")"
                    ]
                )
            )
        )

        // Configure auth callback handling
        setupAuthCallbacks()
    }

    /// Access to Supabase Auth
    public var auth: AuthClient {
        return client.auth
    }

    /// Access to Supabase Database
    public var database: PostgrestClient {
        return client.database
    }

    /// Access to Supabase Storage  
    public var storage: SupabaseStorageClient {
        return client.storage
    }

    /// Check if the client is properly configured
    public func isConfigured() -> Bool {
        return !AppConfig.supabaseURL.absoluteString.contains("placeholder") &&
               !AppConfig.supabaseAnonKey.contains("placeholder")
    }

    /// Perform a health check on the Supabase connection
    public func performHealthCheck() async -> Bool {
        do {
            // Try to fetch current session to verify connection
            _ = try await client.auth.session
            return true
        } catch {
            print("[SupabaseClient] Health check failed: \(error)")
            return false
        }
    }

    // MARK: - Private Methods

    private func setupAuthCallbacks() {
        // Handle auth state changes if needed
        // This can be used to sync with your app's auth state
    }
}

// MARK: - Convenience Extensions

extension SupabaseClient {
    /// Convenience method to get current session safely
    public func currentSession() async throws -> Auth.Session? {
        return try await self.auth.session
    }

    /// Convenience method to check if user is authenticated
    public func isAuthenticated() async -> Bool {
        do {
            return try await self.auth.session != nil
        } catch {
            return false
        }
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
