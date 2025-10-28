//
//  AvatarUploadServiceLive.swift
//  SupabaseKit
//
//  Live implementation of AvatarUploadService using Supabase Storage and Database
//

import Foundation
@preconcurrency import Supabase

/// Protocol for avatar upload service
/// Note: This protocol is defined here to avoid circular dependency with AppFoundation
public protocol AvatarUploadServiceProtocol: Sendable {
    /// Uploads avatar data to storage and updates user profile
    /// - Parameters:
    ///   - data: The image data to upload (PNG or JPEG)
    ///   - mime: The MIME type of the image data
    /// - Returns: The public URL of the uploaded avatar with cache-busting version
    /// - Throws: AvatarUploadError if upload or profile update fails
    func uploadAvatar(_ data: Data, mime: String) async throws -> URL
}

/// Errors that can occur during avatar upload
public enum AvatarUploadError: LocalizedError, Sendable {
    case notAuthenticated
    case uploadFailed(Error)
    case profileUpdateFailed(Error)
    
    public var errorDescription: String? {
        switch self {
        case .notAuthenticated:
            return "Please sign in to update your avatar."
        case .uploadFailed:
            return "Failed to upload avatar. Please try again."
        case .profileUpdateFailed:
            return "Avatar uploaded but profile update failed. Please try again."
        }
    }
}

/// Response from profile update operation
public struct ProfileUpdateResponse: Codable, Sendable {
    public let updated_at: String?
    
    public init(updated_at: String?) {
        self.updated_at = updated_at
    }
}

/// Live implementation of AvatarUploadService using Supabase Storage and Database
public struct AvatarUploadServiceLive: AvatarUploadServiceProtocol {
    private let client: SupabaseClient
    
    public init(client: SupabaseClient) {
        self.client = client
    }
    
    public func uploadAvatar(_ data: Data, mime: String) async throws -> URL {
        // Get current user ID
        let user = try await client.auth.user()
        
        // Use lowercase UUID to match PostgreSQL's UUID::text format
        let userId = user.id.uuidString.lowercased()
        let fileExtension = mime == "image/png" ? "png" : "jpg"
        let fileName = "avatar_512.\(fileExtension)"
        // Path must be {userId}/filename for RLS policy (storage.foldername checks first folder)
        let filePath = "\(userId)/\(fileName)"
        
        print("🔐 [AvatarUpload] User ID: \(userId)")
        print("🔐 [AvatarUpload] File path: \(filePath)")
        print("🔐 [AvatarUpload] File size: \(data.count) bytes")
        
        // Retryable operation with exponential backoff
        return try await withRetry(maxAttempts: 3) {
            // Upload with upsert and cache control
            _ = try await client.storage
                .from("avatars")
                .upload(
                    path: filePath,
                    file: data,
                    options: FileOptions(
                        cacheControl: "31536000", // 1 year
                        contentType: mime,
                        upsert: true
                    )
                )
            
            // Get public URL
            let publicURL = try client.storage
                .from("avatars")
                .getPublicURL(path: filePath)
            
            // Update profile with new avatar URL
            let updateResponse: ProfileUpdateResponse = try await client.database
                .from("users")
                .update([
                    "avatar_url": publicURL.absoluteString,
                    "updated_at": "now()"
                ])
                .eq("id", value: userId)
                .select("updated_at")
                .single()
                .execute()
                .value
            
            // Extract timestamp for cache busting
            let updatedAt = updateResponse.updated_at ?? String(Int(Date().timeIntervalSince1970))
            let versionHash = String(updatedAt.hash)
            
            // Return versioned URL for cache busting
            var components = URLComponents(url: publicURL, resolvingAgainstBaseURL: false)
            components?.queryItems = [URLQueryItem(name: "v", value: versionHash)]
            
            return components?.url ?? publicURL
        }
    }
    
    /// Retry operation with exponential backoff
    private func withRetry<T>(
        maxAttempts: Int,
        operation: @escaping () async throws -> T
    ) async throws -> T {
        var lastError: Error?
        
        for attempt in 1...maxAttempts {
            do {
                return try await operation()
            } catch {
                lastError = error
                if attempt < maxAttempts {
                    let delay = pow(2.0, Double(attempt - 1)) * 0.5 // 0.5s, 1s, 2s
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                }
            }
        }
        
        // Wrap the final error appropriately
        if let lastError = lastError {
            if lastError is AuthError {
                throw AvatarUploadError.notAuthenticated
            } else if lastError.localizedDescription.contains("profile") {
                throw AvatarUploadError.profileUpdateFailed(lastError)
            } else {
                throw AvatarUploadError.uploadFailed(lastError)
            }
        }
        
        throw AvatarUploadError.uploadFailed(NSError(domain: "Unknown", code: -1))
    }
}