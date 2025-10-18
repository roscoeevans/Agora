//
//  PreviewDeps.swift
//  AppFoundation
//
//  Preview dependency injection helpers for SwiftUI previews
//

import SwiftUI

#if DEBUG
/// Helpers for providing safe, minimal dependencies in SwiftUI previews
@available(iOS 26.0, macOS 15.0, *)
public enum PreviewDeps {
    /// Wrap any view in a DI scope with mock services suitable for SwiftUI previews.
    ///
    /// This provides a minimal dependency container that:
    /// - Uses stub implementations (no network calls)
    /// - Has deterministic data for consistent previews
    /// - Avoids heavy initialization that slows down preview refresh
    ///
    /// Example:
    /// ```swift
    /// #Preview {
    ///     PreviewDeps.scoped {
    ///         HomeForYouView()
    ///     }
    /// }
    /// ```
    @ViewBuilder
    public static func scoped<V: View>(@ViewBuilder _ content: () -> V) -> some View {
        content()
            .environment(\.deps, Dependencies.test())
            .environment(\.colorScheme, .light)
            .environment(\.locale, .init(identifier: "en_US"))
    }
    
    /// Wrap any view with dark mode preview styling
    @ViewBuilder
    public static func scopedDark<V: View>(@ViewBuilder _ content: () -> V) -> some View {
        content()
            .environment(\.deps, Dependencies.test())
            .environment(\.colorScheme, .dark)
            .environment(\.locale, .init(identifier: "en_US"))
            .preferredColorScheme(.dark)
    }
}
#endif // DEBUG

// MARK: - ProcessInfo Extension

public extension ProcessInfo {
    /// Returns true if code is running inside Xcode Previews
    ///
    /// Use this to guard expensive initialization or network calls in app startup:
    /// ```swift
    /// init() {
    ///     guard !ProcessInfo.processInfo.isXcodePreviews else { return }
    ///     // Heavy initialization here
    /// }
    /// ```
    var isXcodePreviews: Bool {
        environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1" || 
        environment["XCODE_RUNNING_FOR_PLAYGROUNDS"] == "1"
    }
}

// MARK: - Preview Fixture Data

#if DEBUG
/// Sample data for previews
@available(iOS 26.0, macOS 15.0, *)
public enum PreviewFixtures {
    
    // MARK: - Posts
    
    public static let shortPost = Post(
        id: "preview-short",
        authorId: "user-1",
        authorDisplayHandle: "rocky.evans",
        text: "Just shipped! 🚀",
        likeCount: 12,
        repostCount: 3,
        replyCount: 2,
        createdAt: Date().addingTimeInterval(-600),
        authorDisplayName: "Rocky Evans"
    )
    
    public static let longPost = Post(
        id: "preview-long",
        authorId: "user-2",
        authorDisplayHandle: "design.lover",
        text: """
        Really enjoying the new design system we built. The component library makes it so easy to maintain consistency across the app. 
        
        Plus, the SwiftUI previews are working great now! Being able to see components in isolation speeds up development significantly.
        
        What's your favorite feature so far?
        """,
        likeCount: 156,
        repostCount: 24,
        replyCount: 43,
        createdAt: Date().addingTimeInterval(-7200),
        authorDisplayName: "Design Lover",
        editedAt: Date().addingTimeInterval(-3600)
    )
    
    public static let popularPost = Post(
        id: "preview-popular",
        authorId: "user-3",
        authorDisplayHandle: "viral.post",
        text: "This post is going viral! Thanks everyone for the support 💜",
        likeCount: 2_847,
        repostCount: 512,
        replyCount: 389,
        createdAt: Date().addingTimeInterval(-86400),
        authorDisplayName: "Viral Post"
    )
    
    public static let recentPost = Post(
        id: "preview-recent",
        authorId: "user-4",
        authorDisplayHandle: "just.now",
        text: "Testing real-time updates...",
        likeCount: 0,
        repostCount: 0,
        replyCount: 0,
        createdAt: Date().addingTimeInterval(-10),
        authorDisplayName: "Just Now"
    )
    
    // MARK: - Users
    
    public static let sampleUser = User(
        id: "preview-user-1",
        handle: "rocky",
        displayHandle: "rocky.evans",
        displayName: "Rocky Evans",
        bio: "Building Agora 🏛️ • Human-only social",
        avatarUrl: nil,
        createdAt: Date().addingTimeInterval(-2_592_000) // 30 days ago
    )
    
    public static let verifiedUser = User(
        id: "preview-user-2",
        handle: "verified",
        displayHandle: "verified.account",
        displayName: "Verified Account ✓",
        bio: "Official account",
        avatarUrl: nil,
        createdAt: Date().addingTimeInterval(-7_776_000) // 90 days ago
    )
    
    // MARK: - Feed Responses
    
    public static let sampleFeed = FeedResponse(
        posts: [shortPost, longPost, popularPost, recentPost],
        nextCursor: "next-page-cursor"
    )
    
    public static let emptyFeed = FeedResponse(
        posts: [],
        nextCursor: nil
    )
}
#endif // DEBUG

