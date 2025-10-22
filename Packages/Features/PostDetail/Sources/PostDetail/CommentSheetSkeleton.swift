//
//  CommentSheetSkeleton.swift
//  PostDetail
//
//  Created by Agora Team on 2024.
//

import SwiftUI
import DesignSystem
import AppFoundation

/// CommentSheet skeleton integration for PostDetail Feature.
///
/// Provides immediate parent post display with skeleton loading for replies,
/// implementing progressive hydration as comment data becomes available.
/// Follows requirement 4.1-4.5 for CommentSheet skeleton system.
public struct CommentSheetSkeleton: View {
    @Environment(\.dismiss) private var dismiss
    
    let post: Post
    let replyToCommentId: String?
    let replyToUsername: String?
    
    // Loading and content state
    @State private var loadingState: CommentLoadingState = .loading(placeholderCount: 6)
    @State private var comments: [Comment?] = [] // nil entries show skeletons
    
    // Performance monitoring
    @StateObject private var performanceMonitor = CommentPerformanceMonitor()
    
    // Haptic feedback triggers
    @State private var postButtonHapticTrigger = false
    @State private var closeButtonHapticTrigger = false
    
    // Comment input state
    @State private var commentText = ""
    @State private var isPostingComment = false
    
    public init(
        post: Post,
        replyToCommentId: String? = nil,
        replyToUsername: String? = nil
    ) {
        self.post = post
        self.replyToCommentId = replyToCommentId
        self.replyToUsername = replyToUsername
    }
    
    public var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Top handle for swipe-to-dismiss (requirement 4.5)
                Capsule()
                    .fill(ColorTokens.separator)
                    .frame(width: 36, height: 5)
                    .padding(.top, SpacingTokens.sm)
                    .padding(.bottom, SpacingTokens.md)
                
                ScrollView {
                    VStack(alignment: .leading, spacing: SpacingTokens.lg) {
                        // Show who we're replying to
                        if let username = replyToUsername {
                            HStack(spacing: SpacingTokens.xs) {
                                Text("Replying to")
                                    .font(TypographyScale.footnote)
                                    .foregroundColor(ColorTokens.tertiaryText)
                                
                                Text("@\(username)")
                                    .font(TypographyScale.footnote)
                                    .foregroundColor(ColorTokens.agoraBrand)
                            }
                            .padding(.horizontal, SpacingTokens.md)
                        }
                        
                        // Original post context (requirement 4.1 - immediate display)
                        parentPostSection
                        
                        Divider()
                            .padding(.horizontal, SpacingTokens.md)
                        
                        // Comments section with skeleton loading
                        commentsSection
                        
                        Divider()
                            .padding(.horizontal, SpacingTokens.md)
                        
                        // Comment input area
                        commentInputSection
                    }
                }
                
                Spacer()
                
                // Post button at bottom
                postButton
            }
            .navigationTitle("\(post.replyCount) comments")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            #endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        closeButtonHapticTrigger.toggle()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(ColorTokens.tertiaryText)
                            .symbolRenderingMode(.hierarchical)
                    }
                    .frame(minWidth: 44, minHeight: 44) // Minimum touch target
                    .accessibilityLabel("Close comments")
                    .sensoryFeedback(.selection, trigger: closeButtonHapticTrigger)
                }
            }
        }
        .onAppear {
            loadComments()
        }
        // Requirement 4.5 - sheet presentation configuration
        .presentationDetents([.fraction(0.65)])
        .presentationDragIndicator(.visible)
        .presentationCornerRadius(BorderRadiusTokens.xl)
        .presentationBackground(.ultraThinMaterial)
    }
    
    // MARK: - Parent Post Section
    
    /// Displays the parent post content immediately (requirement 4.1)
    private var parentPostSection: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.sm) {
            HStack(alignment: .top, spacing: SpacingTokens.sm) {
                Circle()
                    .fill(ColorTokens.agoraBrand)
                    .frame(width: 32, height: 32)
                    .overlay {
                        Text(String((post.authorDisplayName ?? post.authorDisplayHandle).prefix(1)))
                            .font(TypographyScale.caption1)
                            .foregroundColor(.white)
                    }
                
                VStack(alignment: .leading, spacing: SpacingTokens.xxs) {
                    HStack(spacing: SpacingTokens.xs) {
                        Text(post.authorDisplayHandle)
                            .font(TypographyScale.calloutEmphasized)
                            .foregroundColor(ColorTokens.primaryText)
                        
                        Text("·")
                            .font(TypographyScale.caption1)
                            .foregroundColor(ColorTokens.tertiaryText)
                        
                        Text(post.createdAt, style: .relative)
                            .font(TypographyScale.caption1)
                            .foregroundColor(ColorTokens.tertiaryText)
                    }
                    
                    Text(post.text)
                        .font(TypographyScale.body)
                        .foregroundColor(ColorTokens.primaryText)
                        .lineLimit(4)
                }
            }
        }
        .padding(.horizontal, SpacingTokens.md)
        .padding(.bottom, SpacingTokens.sm)
    }
    
    // MARK: - Comments Section
    
    /// Comments section with skeleton loading (requirements 4.2, 4.4)
    private var commentsSection: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.md) {
            Text("Comments")
                .font(TypographyScale.calloutEmphasized)
                .foregroundColor(ColorTokens.primaryText)
                .padding(.horizontal, SpacingTokens.md)
                .accessibilityAddTraits(.isHeader)
            
            // Progressive hydration: show skeletons for nil entries, real content for loaded entries
            LazyVStack(spacing: SpacingTokens.md) {
                ForEach(Array(comments.enumerated()), id: \.offset) { index, comment in
                    Group {
                        if let error = errorForIndex(index) {
                            // Error state - show inline error with retry
                            SkeletonErrorView.feedRowError(
                                error: error,
                                retryAction: {
                                    Task {
                                        await retryLoadingAtIndex(index)
                                    }
                                }
                            )
                            .accessibilityElement(children: .contain)
                            .accessibilityLabel("Failed to load comment")
                            .accessibilityHint("Double tap retry button to try loading again")
                        } else if let comment = comment {
                            // Real comment content (requirement 4.4 - progressive replacement)
                            CommentRowView(comment: comment)
                                .transition(.opacity.combined(with: .scale(scale: 0.95)))
                                .accessibilityElement(children: .contain)
                                .accessibilityLabel("Comment by \(comment.authorHandle): \(comment.text)")
                                .onAppear {
                                    // Unregister shimmer when content appears
                                    performanceMonitor.unregisterActiveShimmer()
                                }
                        } else {
                            // Skeleton placeholder with performance optimization (requirement 4.2 - 6-8 placeholders)
                            PerformanceAwareCommentSkeleton(
                                index: index,
                                performanceMonitor: performanceMonitor
                            )
                            .accessibilityHidden(true) // Hide skeleton from VoiceOver
                        }
                    }
                }
            }
            .skeletonContainerAccessibility(
                isLoading: loadingState.isLoading,
                loadingMessage: "Loading comments",
                loadedMessage: "Comments loaded"
            )
        }
    }
    
    // MARK: - Comment Input Section
    
    private var commentInputSection: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.md) {
            TextEditor(text: $commentText)
                .font(TypographyScale.body)
                .foregroundColor(ColorTokens.primaryText)
                .frame(minHeight: 100)
                .scrollContentBackground(.hidden)
                .background(Color.clear)
                .overlay(alignment: .topLeading) {
                    if commentText.isEmpty {
                        Text("Add a comment...")
                            .font(TypographyScale.body)
                            .foregroundColor(ColorTokens.quaternaryText)
                            .padding(.top, 8)
                            .padding(.leading, 5)
                            .allowsHitTesting(false)
                    }
                }
                .accessibilityLabel("Comment text")
                .accessibilityHint("Type your comment here")
            
            // Character count
            HStack {
                Spacer()
                Text("\(commentText.count)/280")
                    .font(TypographyScale.caption1)
                    .foregroundColor(commentText.count > 280 ? ColorTokens.error : ColorTokens.tertiaryText)
            }
        }
        .padding(.horizontal, SpacingTokens.md)
    }
    
    // MARK: - Post Button
    
    private var postButton: some View {
        Button(action: {
            postButtonHapticTrigger.toggle()
            postComment()
        }) {
            HStack {
                if isPostingComment {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                }
                
                Text(isPostingComment ? "Posting..." : "Post")
                    .font(TypographyScale.calloutEmphasized)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(
                (commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || commentText.count > 280 || isPostingComment) 
                    ? ColorTokens.quaternaryText 
                    : ColorTokens.agoraBrand
            )
            .cornerRadius(BorderRadiusTokens.md)
        }
        .disabled(commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || commentText.count > 280 || isPostingComment)
        .padding(.horizontal, SpacingTokens.md)
        .padding(.bottom, SpacingTokens.md)
        .frame(minHeight: 44) // Minimum touch target
        .accessibilityLabel("Post comment")
        .accessibilityHint("Double tap to post your comment")
        .sensoryFeedback(.impact(weight: .medium), trigger: postButtonHapticTrigger)
    }
    
    // MARK: - Loading Logic
    
    /// Loads comments with skeleton placeholders (requirements 4.2, 4.4)
    private func loadComments() {
        // Initialize with 6-8 skeleton placeholders (requirement 4.2)
        let placeholderCount = Int.random(in: 6...8)
        comments = Array(repeating: nil, count: placeholderCount)
        loadingState = .loading(placeholderCount: placeholderCount)
        
        // Simulate progressive loading of comments (requirement 4.4)
        Task {
            // Stagger comment loading to demonstrate progressive hydration
            for index in 0..<placeholderCount {
                // Random delay between 0.5-2.0 seconds per comment
                let delay = Double.random(in: 0.5...2.0)
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                
                await MainActor.run {
                    // Simulate occasional loading failures (10% chance)
                    if Double.random(in: 0...1) < 0.1 {
                        // Simulate loading failure
                        handleCommentLoadingFailure(
                            NSError(domain: "CommentLoadError", code: -1, userInfo: [
                                NSLocalizedDescriptionKey: "Failed to load comment"
                            ]),
                            at: index
                        )
                    } else {
                        // Replace skeleton with actual comment (progressive hydration)
                        if index < comments.count {
                            comments[index] = Comment(
                                id: "comment-\(index)",
                                authorHandle: "user\(index + 1)",
                                authorDisplayName: "User \(index + 1)",
                                text: generateSampleCommentText(),
                                createdAt: Date().addingTimeInterval(-Double(index * 3600)), // Hours ago
                                likeCount: Int.random(in: 0...50),
                                replyCount: Int.random(in: 0...10)
                            )
                        }
                    }
                }
            }
            
            await MainActor.run {
                // Check if all comments loaded successfully
                let loadedCount = comments.compactMap { $0 }.count
                if loadedCount == placeholderCount && !loadingState.hasError {
                    loadingState = .loaded
                } else if loadedCount > 0 {
                    let loadedIndices = Set(comments.enumerated().compactMap { index, comment in
                        comment != nil ? index : nil
                    })
                    if !loadingState.hasError {
                        loadingState = .hydrating(loadedIndices: loadedIndices)
                    }
                }
            }
        }
    }
    
    /// Posts a new comment
    private func postComment() {
        guard !commentText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              commentText.count <= 280,
              !isPostingComment else { return }
        
        isPostingComment = true
        
        Task {
            // Simulate posting delay
            try await Task.sleep(nanoseconds: 1_000_000_000) // 1 second
            
            await MainActor.run {
                // Add new comment to the top
                let newComment = Comment(
                    id: "new-comment-\(UUID().uuidString)",
                    authorHandle: "currentuser", // Would come from auth service
                    authorDisplayName: "Current User",
                    text: commentText,
                    createdAt: Date(),
                    likeCount: 0,
                    replyCount: 0
                )
                
                comments.insert(newComment, at: 0)
                commentText = ""
                isPostingComment = false
            }
        }
    }
    
    /// Generates sample comment text for demonstration
    private func generateSampleCommentText() -> String {
        let sampleTexts = [
            "Great post! Thanks for sharing this.",
            "I completely agree with your perspective on this topic.",
            "This is really insightful. Have you considered the implications for mobile users?",
            "Interesting point. I'd love to hear more about your experience with this.",
            "Thanks for the detailed explanation. This helps clarify things.",
            "I have a different view on this, but I appreciate the discussion.",
            "This reminds me of a similar situation I encountered last year.",
            "Excellent analysis! The data you provided really supports your argument."
        ]
        return sampleTexts.randomElement() ?? "Great post!"
    }
    
    // MARK: - Error Handling
    
    /// Get error for specific index if it exists
    private func errorForIndex(_ index: Int) -> Error? {
        if case .partialError(_, let failedIndices, let errors) = loadingState,
           failedIndices.contains(index) {
            return errors[index]
        }
        return nil
    }
    
    /// Retry loading for a specific comment index
    private func retryLoadingAtIndex(_ index: Int) async {
        // Clear the error for this index and attempt to reload
        if case .partialError(var loadedIndices, var failedIndices, var errors) = loadingState {
            failedIndices.remove(index)
            errors.removeValue(forKey: index)
            
            // Reset the comment to nil to show skeleton
            if index < comments.count {
                comments[index] = nil
            }
            
            // Update loading state
            if failedIndices.isEmpty {
                loadingState = .hydrating(loadedIndices: loadedIndices)
            } else {
                loadingState = .partialError(loadedIndices: loadedIndices, failedIndices: failedIndices, errors: errors)
            }
            
            // Simulate retry loading
            let delay = Double.random(in: 0.5...2.0)
            try? await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
            
            await MainActor.run {
                // Simulate potential failure (20% chance)
                if Double.random(in: 0...1) < 0.2 {
                    // Failed again
                    handleCommentLoadingFailure(
                        NSError(domain: "CommentLoadError", code: -1, userInfo: [
                            NSLocalizedDescriptionKey: "Failed to load comment"
                        ]),
                        at: index
                    )
                } else {
                    // Success - load the comment
                    if index < comments.count {
                        comments[index] = Comment(
                            id: "comment-retry-\(index)",
                            authorHandle: "user\(index + 1)",
                            authorDisplayName: "User \(index + 1)",
                            text: generateSampleCommentText(),
                            createdAt: Date().addingTimeInterval(-Double(index * 3600)),
                            likeCount: Int.random(in: 0...50),
                            replyCount: Int.random(in: 0...10)
                        )
                    }
                    
                    // Update loading state
                    let currentLoadedIndices = Set(comments.enumerated().compactMap { index, comment in
                        comment != nil ? index : nil
                    })
                    
                    if currentLoadedIndices.count == comments.count {
                        loadingState = .loaded
                    } else {
                        loadingState = .hydrating(loadedIndices: currentLoadedIndices)
                    }
                }
            }
        }
    }
    
    /// Handle individual comment loading failures
    private func handleCommentLoadingFailure(_ error: Error, at index: Int) {
        let currentLoadedIndices = Set(comments.enumerated().compactMap { index, comment in
            comment != nil ? index : nil
        })
        
        var failedIndices = Set<Int>()
        var errors = [Int: Error]()
        
        // Add this failure
        failedIndices.insert(index)
        errors[index] = error
        
        // Check if we already have partial errors
        if case .partialError(_, let existingFailedIndices, let existingErrors) = loadingState {
            failedIndices.formUnion(existingFailedIndices)
            errors.merge(existingErrors) { _, new in new }
        }
        
        // Update to partial error state
        loadingState = .partialError(
            loadedIndices: currentLoadedIndices,
            failedIndices: failedIndices,
            errors: errors
        )
    }
}

// MARK: - Loading State

/// Loading state enumeration for CommentSheet skeleton system
private enum CommentLoadingState {
    case idle
    case loading(placeholderCount: Int)
    case hydrating(loadedIndices: Set<Int>)
    case loaded
    case error(Error)
    case partialError(loadedIndices: Set<Int>, failedIndices: Set<Int>, errors: [Int: Error])
    
    var isLoading: Bool {
        switch self {
        case .loading, .hydrating:
            return true
        default:
            return false
        }
    }
    
    var hasError: Bool {
        switch self {
        case .error, .partialError:
            return true
        default:
            return false
        }
    }
}

// MARK: - Performance Aware Comment Skeleton

/// Comment skeleton with performance optimization and staggered reveal
private struct PerformanceAwareCommentSkeleton: View {
    let index: Int
    let performanceMonitor: CommentPerformanceMonitor
    
    @State private var isShimmerActive: Bool = false
    @State private var hasRegisteredShimmer: Bool = false
    
    var body: some View {
        CommentSkeletonView()
            .skeleton(isActive: isShimmerActive && !performanceMonitor.shouldDisableShimmer)
            .onAppear {
                // Implement staggered reveal timing
                let staggerDelay = performanceMonitor.staggerDelayForIndex(index)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + staggerDelay) {
                    // Check if shimmer can be activated
                    if performanceMonitor.canActivateShimmer {
                        performanceMonitor.registerActiveShimmer()
                        hasRegisteredShimmer = true
                        isShimmerActive = true
                    }
                }
            }
            .onDisappear {
                // Unregister shimmer when view disappears
                if hasRegisteredShimmer {
                    performanceMonitor.unregisterActiveShimmer()
                    hasRegisteredShimmer = false
                }
                isShimmerActive = false
            }
            .onChange(of: performanceMonitor.shouldDisableShimmer) { newValue in
                // Disable shimmer immediately if performance requires it
                if newValue && isShimmerActive {
                    isShimmerActive = false
                    if hasRegisteredShimmer {
                        performanceMonitor.unregisterActiveShimmer()
                        hasRegisteredShimmer = false
                    }
                }
            }
    }
}

// MARK: - Comment Row View

/// Individual comment row view
private struct CommentRowView: View {
    let comment: Comment
    
    @State private var likeHapticTrigger = false
    @State private var replyHapticTrigger = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.xs) {
            HStack(alignment: .top, spacing: SpacingTokens.sm) {
                // Avatar (32×32pt as per requirement 4.3)
                Circle()
                    .fill(ColorTokens.agoraBrand)
                    .frame(width: 32, height: 32)
                    .overlay {
                        Text(String((comment.authorDisplayName ?? comment.authorHandle).prefix(1)))
                            .font(TypographyScale.caption1)
                            .foregroundColor(.white)
                    }
                
                VStack(alignment: .leading, spacing: SpacingTokens.xxs) {
                    // Header
                    HStack(spacing: SpacingTokens.xs) {
                        Text(comment.authorHandle)
                            .font(TypographyScale.calloutEmphasized)
                            .foregroundColor(ColorTokens.primaryText)
                        
                        Text("·")
                            .font(TypographyScale.caption1)
                            .foregroundColor(ColorTokens.tertiaryText)
                        
                        Text(comment.createdAt, style: .relative)
                            .font(TypographyScale.caption1)
                            .foregroundColor(ColorTokens.tertiaryText)
                    }
                    
                    // Comment text
                    Text(comment.text)
                        .font(TypographyScale.body)
                        .foregroundColor(ColorTokens.primaryText)
                }
                
                Spacer()
            }
            
            // Engagement buttons
            HStack(spacing: SpacingTokens.lg) {
                // Like button
                Button(action: {
                    likeHapticTrigger.toggle()
                }) {
                    HStack(spacing: SpacingTokens.xxs) {
                        Image(systemName: "heart")
                            .font(.system(size: 14))
                            .foregroundColor(ColorTokens.tertiaryText)
                        
                        if comment.likeCount > 0 {
                            Text("\(comment.likeCount)")
                                .font(TypographyScale.caption1)
                                .foregroundColor(ColorTokens.tertiaryText)
                        }
                    }
                }
                .frame(minWidth: 44, minHeight: 32) // Minimum touch target
                .accessibilityLabel("Like comment")
                .sensoryFeedback(.selection, trigger: likeHapticTrigger)
                
                // Reply button
                Button(action: {
                    replyHapticTrigger.toggle()
                }) {
                    HStack(spacing: SpacingTokens.xxs) {
                        Image(systemName: "arrowshape.turn.up.left")
                            .font(.system(size: 14))
                            .foregroundColor(ColorTokens.tertiaryText)
                        
                        if comment.replyCount > 0 {
                            Text("\(comment.replyCount)")
                                .font(TypographyScale.caption1)
                                .foregroundColor(ColorTokens.tertiaryText)
                        }
                    }
                }
                .frame(minWidth: 44, minHeight: 32) // Minimum touch target
                .accessibilityLabel("Reply to comment")
                .sensoryFeedback(.selection, trigger: replyHapticTrigger)
                
                Spacer()
            }
            .padding(.leading, 32 + SpacingTokens.sm) // Align with comment text
        }
        .padding(.horizontal, SpacingTokens.md)
        .padding(.vertical, SpacingTokens.xs)
    }
}

// MARK: - Performance Monitor

/// Performance monitoring for CommentSheet skeleton optimization
@MainActor
private class CommentPerformanceMonitor: ObservableObject {
    @Published var activeShimmerCount: Int = 0
    @Published var shouldDisableShimmer: Bool = false
    
    private let maxSimultaneousShimmers: Int = 8 // Limit for comment skeletons
    private let staggerRevealDelay: TimeInterval = 0.05 // 50ms stagger
    
    /// Register a shimmer as active
    func registerActiveShimmer() {
        activeShimmerCount = min(activeShimmerCount + 1, maxSimultaneousShimmers)
        updateShimmerState()
    }
    
    /// Unregister a shimmer as inactive
    func unregisterActiveShimmer() {
        activeShimmerCount = max(activeShimmerCount - 1, 0)
        updateShimmerState()
    }
    
    /// Check if new shimmer can be activated
    var canActivateShimmer: Bool {
        return activeShimmerCount < maxSimultaneousShimmers && !shouldDisableShimmer
    }
    
    /// Get stagger delay for index
    func staggerDelayForIndex(_ index: Int) -> TimeInterval {
        return staggerRevealDelay * Double(index)
    }
    
    private func updateShimmerState() {
        shouldDisableShimmer = activeShimmerCount >= maxSimultaneousShimmers
    }
}

// MARK: - Comment Model

/// Comment model for CommentSheet
private struct Comment: Identifiable {
    let id: String
    let authorHandle: String
    let authorDisplayName: String?
    let text: String
    let createdAt: Date
    let likeCount: Int
    let replyCount: Int
}

// MARK: - Previews

#if DEBUG
#Preview("CommentSheet with Skeleton Loading") {
    PreviewDeps.scoped {
        CommentSheetSkeleton(
            post: PreviewFixtures.shortPost
        )
    }
}

#Preview("CommentSheet Reply Mode") {
    PreviewDeps.scoped {
        CommentSheetSkeleton(
            post: PreviewFixtures.longPost,
            replyToCommentId: "some-comment-id",
            replyToUsername: "commenter"
        )
    }
}

#Preview("CommentSheet Popular Post") {
    PreviewDeps.scoped {
        CommentSheetSkeleton(
            post: PreviewFixtures.popularPost
        )
    }
}
#endif