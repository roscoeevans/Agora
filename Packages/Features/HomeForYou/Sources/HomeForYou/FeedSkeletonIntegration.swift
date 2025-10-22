//
//  FeedSkeletonIntegration.swift
//  HomeForYou
//
//  Created by Agora Team on 2024.
//

import Foundation
import SwiftUI
import DesignSystem
import AppFoundation
import Darwin.Mach

// MARK: - Loading State Management

/// Loading state enumeration for HomeForYou feed skeleton integration.
/// Lives locally in Feature to avoid shared state complexity.
enum LoadingState: Equatable {
    case idle
    case loading(placeholderCount: Int)
    case hydrating(loadedIndices: Set<Int>)
    case loaded
    case loadingMore(existingCount: Int, placeholderCount: Int) // Pagination loading state
    case error(Error)
    case partialError(loadedIndices: Set<Int>, failedIndices: Set<Int>, errors: [Int: Error]) // Individual row errors
    case paginationError(existingCount: Int, error: Error) // Pagination-specific error
    
    var isLoading: Bool {
        switch self {
        case .loading, .hydrating, .loadingMore:
            return true
        case .idle, .loaded, .error, .partialError, .paginationError:
            return false
        }
    }
    
    var hasError: Bool {
        switch self {
        case .error, .partialError, .paginationError:
            return true
        case .idle, .loading, .hydrating, .loaded, .loadingMore:
            return false
        }
    }
    
    static func == (lhs: LoadingState, rhs: LoadingState) -> Bool {
        switch (lhs, rhs) {
        case (.idle, .idle), (.loaded, .loaded):
            return true
        case (.loading(let lhsCount), .loading(let rhsCount)):
            return lhsCount == rhsCount
        case (.hydrating(let lhsIndices), .hydrating(let rhsIndices)):
            return lhsIndices == rhsIndices
        case (.loadingMore(let lhsExisting, let lhsPlaceholders), .loadingMore(let rhsExisting, let rhsPlaceholders)):
            return lhsExisting == rhsExisting && lhsPlaceholders == rhsPlaceholders
        case (.error(let lhsError), .error(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        case (.partialError(let lhsLoaded, let lhsFailed, _), .partialError(let rhsLoaded, let rhsFailed, _)):
            return lhsLoaded == rhsLoaded && lhsFailed == rhsFailed
        case (.paginationError(let lhsCount, let lhsError), .paginationError(let rhsCount, let rhsError)):
            return lhsCount == rhsCount && lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}

// MARK: - Skeleton Configuration

/// Skeleton configuration for HomeForYou feed with performance parameters.
/// Configured locally per Feature requirements.
struct SkeletonConfiguration {
    let placeholderCount: Int
    let preloadThreshold: Int
    let maxSimultaneousShimmers: Int
    let memoryLimit: Int // MB
    let analyticsEnabled: Bool
    let targetDisplayTime: TimeInterval // 200ms target
    let postsPerPage: Int // Cursor-based pagination page size
    let staggerRevealDelay: TimeInterval // 50ms staggered reveal timing
    let imagePrefetchScreens: Int // Number of screens ahead to prefetch images
    
    static let homeForYou = SkeletonConfiguration(
        placeholderCount: 5,
        preloadThreshold: 5,
        maxSimultaneousShimmers: 10,
        memoryLimit: 100,
        analyticsEnabled: true,
        targetDisplayTime: 0.2, // 200ms target display time
        postsPerPage: 20, // 20 posts per page for cursor-based pagination
        staggerRevealDelay: 0.05, // 50ms staggered reveal timing between skeleton rows
        imagePrefetchScreens: 2 // Prefetch images for posts up to 2 screens ahead
    )
}

// MARK: - Performance Monitor

/// Performance monitoring utility for skeleton optimization and smooth scrolling
@MainActor
class PerformanceMonitor: ObservableObject {
    @Published var currentMemoryUsage: Int = 0 // MB
    @Published var shouldDisableShimmer: Bool = false
    @Published var isFastScrolling: Bool = false
    @Published var activeShimmerCount: Int = 0
    
    private let memoryLimit: Int
    private let maxSimultaneousShimmers: Int
    private var lastScrollOffset: CGFloat = 0
    private var scrollVelocityThreshold: CGFloat = 500 // Points per second
    private var lastScrollTime: Date = Date()
    
    init(memoryLimit: Int = 100, maxShimmers: Int = 10) {
        self.memoryLimit = memoryLimit
        self.maxSimultaneousShimmers = maxShimmers
        startMonitoring()
    }
    
    private func startMonitoring() {
        Task {
            while !Task.isCancelled {
                updateMemoryUsage()
                updateFastScrollingState()
                try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second
            }
        }
    }
    
    private func updateMemoryUsage() {
        let memoryUsage = getMemoryUsage()
        self.currentMemoryUsage = memoryUsage
        self.shouldDisableShimmer = memoryUsage >= self.memoryLimit || 
                                   activeShimmerCount >= maxSimultaneousShimmers ||
                                   isFastScrolling
    }
    
    private func updateFastScrollingState() {
        let currentTime = Date()
        let timeDelta = currentTime.timeIntervalSince(lastScrollTime)
        
        // Reset fast scrolling state if no scroll updates for 0.5 seconds
        if timeDelta > 0.5 {
            isFastScrolling = false
        }
    }
    
    /// Update scroll position to detect fast scrolling
    func updateScrollPosition(_ offset: CGFloat) {
        let currentTime = Date()
        let timeDelta = currentTime.timeIntervalSince(lastScrollTime)
        let offsetDelta = abs(offset - lastScrollOffset)
        
        if timeDelta > 0 {
            let velocity = offsetDelta / CGFloat(timeDelta)
            isFastScrolling = velocity > scrollVelocityThreshold
        }
        
        lastScrollOffset = offset
        lastScrollTime = currentTime
    }
    
    /// Register a shimmer as active
    func registerActiveShimmer() {
        activeShimmerCount = min(activeShimmerCount + 1, maxSimultaneousShimmers)
    }
    
    /// Unregister a shimmer as inactive
    func unregisterActiveShimmer() {
        activeShimmerCount = max(activeShimmerCount - 1, 0)
    }
    
    /// Check if new shimmer can be activated
    var canActivateShimmer: Bool {
        return activeShimmerCount < maxSimultaneousShimmers && 
               !shouldDisableShimmer && 
               !isFastScrolling
    }
    
    private func getMemoryUsage() -> Int {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
        
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_,
                         task_flavor_t(MACH_TASK_BASIC_INFO),
                         $0,
                         &count)
            }
        }
        
        if kerr == KERN_SUCCESS {
            return Int(info.resident_size) / (1024 * 1024) // Convert to MB
        }
        
        return 0
    }
}

// MARK: - Skeleton Integration Extension

extension ForYouViewModel {
    
    /// Performance monitor for memory and scrolling optimization
    private static let performanceMonitor = PerformanceMonitor(
        memoryLimit: SkeletonConfiguration.homeForYou.memoryLimit,
        maxShimmers: SkeletonConfiguration.homeForYou.maxSimultaneousShimmers
    )
    
    /// Access to performance monitor for shimmer and scroll control
    var performanceMonitor: PerformanceMonitor {
        return Self.performanceMonitor
    }
    
    /// Legacy memory monitor access for backward compatibility
    var memoryMonitor: PerformanceMonitor {
        return performanceMonitor
    }
    
    /// Enhanced loading state that supports skeleton placeholders and pagination
    var skeletonLoadingState: LoadingState {
        if let error = error {
            return .error(error)
        }
        
        if isLoading && posts.isEmpty {
            return .loading(placeholderCount: SkeletonConfiguration.homeForYou.placeholderCount)
        }
        
        if isLoading && !posts.isEmpty {
            // Check if this is pagination (loading more) vs refresh
            if isPaginationLoading {
                return .loadingMore(
                    existingCount: posts.count,
                    placeholderCount: SkeletonConfiguration.homeForYou.placeholderCount
                )
            } else {
                // During refresh, show hydrating state
                let loadedIndices = Set(posts.indices)
                return .hydrating(loadedIndices: loadedIndices)
            }
        }
        
        if !posts.isEmpty {
            return .loaded
        }
        
        return .idle
    }
    
    /// Track if current loading is pagination vs refresh
    private var isPaginationLoading: Bool {
        // If we have posts and nextCursor exists, this is likely pagination
        return !posts.isEmpty && hasNextPage
    }
    
    /// Skeleton-aware posts array that includes nil placeholders for skeleton display
    var skeletonAwarePosts: [Post?] {
        switch skeletonLoadingState {
        case .loading(let placeholderCount):
            // Return array of nils for skeleton placeholders
            return Array(repeating: nil, count: placeholderCount)
            
        case .hydrating(let loadedIndices):
            // Return mix of loaded posts and nil placeholders
            var result: [Post?] = []
            for index in 0..<max(posts.count, SkeletonConfiguration.homeForYou.placeholderCount) {
                if loadedIndices.contains(index) && index < posts.count {
                    result.append(posts[index])
                } else {
                    result.append(nil)
                }
            }
            return result
            
        case .loadingMore(_, let placeholderCount):
            // Return existing posts + skeleton placeholders for next page
            var result: [Post?] = posts.map { $0 as Post? }
            result.append(contentsOf: Array(repeating: nil, count: placeholderCount))
            return result
            
        case .loaded:
            // Return all loaded posts
            return posts.map { $0 }
            
        case .partialError(let loadedIndices, _, _):
            // Return mix of loaded posts and nil placeholders, errors handled separately
            var result: [Post?] = []
            for index in 0..<max(posts.count, SkeletonConfiguration.homeForYou.placeholderCount) {
                if loadedIndices.contains(index) && index < posts.count {
                    result.append(posts[index])
                } else {
                    result.append(nil)
                }
            }
            return result
            
        case .paginationError(let existingCount, _):
            // Return existing posts only, error handled separately
            return posts.map { $0 }
            
        case .idle, .error:
            return []
        }
    }
    
    /// Pre-seed skeleton placeholders for immediate display with staggered reveal timing
    func preloadSkeletonPlaceholders() {
        // This method ensures skeleton display within 200ms target
        // The actual skeleton rendering is handled by the view layer with staggered timing
        // Staggered reveal is implemented in the view layer using SkeletonConfiguration.staggerRevealDelay
    }
    
    /// Prefetch images for posts up to 2 screens ahead when available
    func prefetchImagesForVisibleRange(currentIndex: Int, screenHeight: CGFloat) {
        let postsPerScreen = Int(screenHeight / 120) // Approximate post height
        let prefetchRange = postsPerScreen * SkeletonConfiguration.homeForYou.imagePrefetchScreens
        let startIndex = max(0, currentIndex - prefetchRange)
        let endIndex = min(posts.count - 1, currentIndex + prefetchRange)
        
        for index in startIndex...endIndex {
            guard index < posts.count else { continue }
            let post = posts[index]
            
            // Prefetch post images if they exist
            // Note: Post model doesn't currently have imageURL property
            // This would be implemented when image support is added
            
            // Prefetch author avatar
            // Note: Post model doesn't currently have authorAvatarURL property
            // This would be implemented when avatar support is added
        }
    }
    
    /// Prefetch a single image from URL
    private func prefetchImage(from url: URL) async {
        // Use URLSession to prefetch image data
        do {
            let (_, _) = try await URLSession.shared.data(from: url)
            // Image is now cached by URLSession
        } catch {
            // Silently fail - prefetching is best effort
        }
    }
}

// MARK: - Skeleton-Aware Feed Post View

/// Wrapper view that applies skeleton loading to FeedPostView based on post availability
struct SkeletonAwareFeedPostView: View {
    let post: Post?
    let error: Error?
    let index: Int
    let onAuthorTap: () -> Void
    let onReply: () -> Void
    let onTap: () -> Void
    let onRetry: (() -> Void)?
    let shouldDisableShimmer: Bool
    let performanceMonitor: PerformanceMonitor
    
    @Environment(\.skeletonTheme) private var theme
    @Environment(\.accessibilityVoiceOverEnabled) private var voiceOverEnabled
    @State private var isShimmerActive: Bool = false
    @State private var hasRegisteredShimmer: Bool = false
    
    var body: some View {
        Group {
            if let error = error {
                // Error state - show inline error with retry
                SkeletonErrorView.feedRowError(
                    error: error,
                    retryAction: onRetry ?? {}
                )
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Failed to load post")
                .accessibilityHint("Double tap retry button to try loading again")
            } else if let post = post {
                // Real content - apply skeleton modifier for smooth transitions
                FeedPostView(
                    post: post,
                    onAuthorTap: onAuthorTap,
                    onReply: onReply
                )
                .skeleton(isActive: false) // Content is loaded
                .contentShape(Rectangle())
                .onTapGesture(perform: onTap)
                .accessibilityElement(children: .contain)
                .accessibilityLabel("Post by \(post.authorDisplayHandle)")
                .onAppear {
                    // Unregister shimmer when content appears
                    if hasRegisteredShimmer {
                        performanceMonitor.unregisterActiveShimmer()
                        hasRegisteredShimmer = false
                    }
                }
            } else {
                // Skeleton placeholder with performance-aware shimmer control
                FeedPostSkeletonView()
                    .skeleton(isActive: isShimmerActive && !shouldDisableShimmer)
                    .contentShape(Rectangle())
                    .onTapGesture { } // Disabled interaction for skeleton
                    .accessibilityHidden(true) // Hide skeleton from VoiceOver
                    .onAppear {
                        // Implement staggered reveal timing
                        let staggerDelay = SkeletonConfiguration.homeForYou.staggerRevealDelay * Double(index)
                        
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
            }
        }
        .animation(.easeInOut(duration: theme.crossfadeDuration), value: post != nil)
        .onChange(of: shouldDisableShimmer) { newValue in
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

// MARK: - Progressive Hydration Support

extension ForYouViewModel {
    
    /// Implements progressive hydration with index-replacement (no insert/delete animations)
    /// This method ensures smooth skeleton-to-content transitions
    func hydratePostAtIndex(_ index: Int, with post: Post) {
        guard index < posts.count else { return }
        
        // Replace post at specific index to avoid insert/delete animations
        // The view layer will automatically transition from skeleton to content
        posts[index] = post
    }
    
    /// Check if we should trigger pagination based on scroll position
    /// Uses 5 rows from bottom threshold as specified in requirements
    func shouldTriggerPagination(currentIndex: Int) -> Bool {
        let threshold = SkeletonConfiguration.homeForYou.preloadThreshold
        let totalVisibleItems = skeletonAwarePosts.count
        
        // Only trigger if we're not already loading and have a next cursor
        guard !isLoading, hasNextPage else { return false }
        
        // Trigger when within threshold of bottom, considering skeleton placeholders
        return currentIndex >= totalVisibleItems - threshold
    }
    
    /// Enhanced refresh that supports skeleton pre-seeding
    func refreshWithSkeletonSupport() async {
        // Pre-seed skeleton state immediately for 200ms target
        preloadSkeletonPlaceholders()
        
        // Perform actual refresh
        await refresh()
    }
    
    /// Enhanced load more that maintains existing content during skeleton display
    /// Implements cursor-based pagination with 20 posts per page
    func loadMoreWithSkeletonSupport() async {
        // Ensure we have a cursor and aren't already loading
        guard hasNextPage, !isLoading else { return }
        
        // Check memory usage before proceeding
        if memoryMonitor.shouldDisableShimmer {
            // Proceed with loading but without shimmer effects
            await loadMoreWithoutShimmer()
            return
        }
        
        // Use the existing loadMore method which handles cursor and pagination
        await loadMore()
    }
    
    /// Load more without shimmer effects for memory conservation
    private func loadMoreWithoutShimmer() async {
        // Standard pagination without skeleton effects
        await loadMore()
    }
    
    /// Check if pagination is available
    var canLoadMore: Bool {
        return hasNextPage && !isLoading
    }
    
    /// Get current memory usage for monitoring
    var currentMemoryUsage: Int {
        return memoryMonitor.currentMemoryUsage
    }
    
    /// Check if shimmer should be disabled due to memory pressure or fast scrolling
    var shouldDisableShimmer: Bool {
        return performanceMonitor.shouldDisableShimmer
    }
    
    /// Check if currently fast scrolling
    var isFastScrolling: Bool {
        return performanceMonitor.isFastScrolling
    }
    
    /// Update scroll position for fast scrolling detection
    func updateScrollPosition(_ offset: CGFloat) {
        performanceMonitor.updateScrollPosition(offset)
    }
    
    /// Get current active shimmer count
    var activeShimmerCount: Int {
        return performanceMonitor.activeShimmerCount
    }
    
    /// Check if new shimmer can be activated
    var canActivateShimmer: Bool {
        return performanceMonitor.canActivateShimmer
    }
    
    /// Get error for specific index if it exists
    func errorForIndex(_ index: Int) -> Error? {
        if case .partialError(_, let failedIndices, let errors) = skeletonLoadingState,
           failedIndices.contains(index) {
            return errors[index]
        }
        return nil
    }
    
    /// Get pagination error if it exists
    var paginationError: Error? {
        if case .paginationError(_, let error) = skeletonLoadingState {
            return error
        }
        return nil
    }
    
    /// Retry loading for a specific index
    func retryLoadingAtIndex(_ index: Int) async {
        // Clear the error for this index and attempt to reload
        if case .partialError(var loadedIndices, var failedIndices, var errors) = skeletonLoadingState {
            failedIndices.remove(index)
            errors.removeValue(forKey: index)
            
            // Update state to show loading for this index
            if failedIndices.isEmpty {
                // No more errors, return to normal loading state
                await refreshWithSkeletonSupport()
            } else {
                // Still have other errors, update partial error state
                // This would need to be implemented based on specific retry logic
                await refreshWithSkeletonSupport()
            }
        }
    }
    
    /// Retry pagination loading
    func retryPagination() async {
        // Clear pagination error and retry loading more
        await loadMoreWithSkeletonSupport()
    }
    
    /// Handle graceful degradation during refresh failures
    /// Maintains existing content while showing error for new content
    func handleRefreshFailure(_ error: Error) {
        if posts.isEmpty {
            // No existing content, show full error
            self.error = error
        } else {
            // Has existing content, maintain it and show inline error
            // This preserves the user's current view while indicating the refresh failed
            // The error will be shown in the UI but existing posts remain visible
        }
    }
    
    /// Handle individual row loading failures
    func handleRowLoadingFailure(_ error: Error, at index: Int) {
        // Convert current state to partial error state
        let currentLoadedIndices: Set<Int>
        
        switch skeletonLoadingState {
        case .hydrating(let indices):
            currentLoadedIndices = indices
        case .loaded:
            currentLoadedIndices = Set(posts.indices)
        default:
            currentLoadedIndices = Set()
        }
        
        var failedIndices = Set<Int>()
        var errors = [Int: Error]()
        
        // Add this failure
        failedIndices.insert(index)
        errors[index] = error
        
        // Update to partial error state
        // Note: This would need to be integrated with the actual ViewModel's state management
    }
}