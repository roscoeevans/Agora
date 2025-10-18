/// Engagement Kit
/// 
/// Provides services for post engagement actions (likes, reposts, shares)
/// with optimistic updates, error handling, and analytics tracking.
///
/// ## Usage
/// 
/// ```swift
/// // Initialize service (typically in composition root)
/// let engagement = EngagementServiceLive(
///     baseURL: URL(string: "https://your-project.supabase.co/functions/v1")!,
///     authTokenProvider: { await authSession.currentToken },
///     session: .shared
/// )
///
/// // Toggle like
/// let result = try await engagement.toggleLike(postId: "123")
/// print("Liked: \(result.isLiked), Count: \(result.likeCount)")
/// ```
///
/// ## Architecture
///
/// - `EngagementService`: Protocol defining engagement operations
/// - `EngagementServiceLive`: Production implementation using Supabase Edge Functions
/// - `EngagementServiceFake`: Test double for previews and unit tests
///
/// All service implementations are actors for safe concurrency.

import Foundation

// Re-export public types
@_exported import AppFoundation

