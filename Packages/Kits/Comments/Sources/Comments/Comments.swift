import Foundation
import AppFoundation
import Supabase
import SupabaseKit

// MARK: - Public Exports

// The protocols and data models are already defined in AppFoundation
// We just need to import them and provide factory methods

// MARK: - Factory Methods

/// Creates a comment service with live Supabase implementation
/// - Parameter supabaseClient: Supabase client protocol wrapper
/// - Returns: Comment service protocol implementation
public func createCommentService(supabaseClient: any SupabaseClientProtocol) -> CommentServiceProtocol {
    // Extract raw Supabase client from the protocol wrapper
    guard let client = supabaseClient.rawClient as? SupabaseClient else {
        fatalError("Failed to extract SupabaseClient from wrapper")
    }
    return CommentServiceLive(supabase: client)
}

/// Creates a comment service with fake implementation for testing and previews
/// - Returns: Fake comment service for testing
public func createFakeCommentService() -> CommentServiceProtocol {
    return CommentServiceFake()
}

