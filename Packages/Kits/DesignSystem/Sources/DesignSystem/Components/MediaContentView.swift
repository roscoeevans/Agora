//
//  MediaContentView.swift
//  DesignSystem
//
//  Smart dispatcher for media content (images vs videos)
//

import SwiftUI
import AppFoundation

/// Smart dispatcher that renders appropriate media component based on bundle type
public struct MediaContentView: View {
    let bundleId: String
    let onImageTap: (Int) -> Void
    let onVideoTap: () -> Void
    
    @State private var mediaBundle: MediaBundleInfo?
    @State private var isLoading = true
    @State private var error: Error?
    
    @Environment(\.deps) private var deps
    
    public init(
        bundleId: String,
        onImageTap: @escaping (Int) -> Void = { _ in },
        onVideoTap: @escaping () -> Void = {}
    ) {
        self.bundleId = bundleId
        self.onImageTap = onImageTap
        self.onVideoTap = onVideoTap
    }
    
    public var body: some View {
        Group {
            if let bundle = mediaBundle {
                // Real content with skeleton transition
                Group {
                    switch bundle.type {
                    case .image:
                        ImageGridView(
                            imageUrls: bundle.urls,
                            onImageTap: onImageTap
                        )
                    case .video:
                        InlineVideoPlayer(
                            videoUrl: bundle.urls.first ?? "",
                            thumbnailUrl: bundle.urls.count > 1 ? bundle.urls[1] : nil,
                            duration: bundle.duration,
                            onVideoTap: onVideoTap
                        )
                    }
                }
                .skeleton(isActive: false) // Content is loaded
                .animation(.easeInOut(duration: 0.3), value: bundle.id)
            } else if isLoading {
                // Skeleton loading state
                loadingView
                    .skeleton(isActive: true)
            } else {
                // Error state
                errorView
            }
        }
        .task {
            await loadMediaBundle()
        }
    }
    
    private var loadingView: some View {
        MediaSkeletonView(
            aspectRatio: expectedAspectRatio,
            cornerRadius: BorderRadiusTokens.md
        )
        .frame(height: 200)
    }
    
    private var expectedAspectRatio: CGFloat {
        // Determine expected aspect ratio based on bundleId or default to 16:9
        if bundleId.contains("video") {
            return 16/9 // Video aspect ratio
        } else if bundleId.contains("square") {
            return 1 // Square images
        } else {
            return 16/9 // Default for images
        }
    }
    
    private var errorView: some View {
        Rectangle()
            .fill(ColorTokens.separator.opacity(0.2))
            .frame(height: 200)
            .clipShape(RoundedRectangle(cornerRadius: BorderRadiusTokens.md))
            .overlay {
                VStack(spacing: SpacingTokens.sm) {
                    Image(systemName: "exclamationmark.triangle")
                        .foregroundColor(ColorTokens.tertiaryText)
                        .font(.system(size: 20))
                    
                    Text(errorMessage)
                        .font(TypographyScale.caption1)
                        .foregroundColor(ColorTokens.tertiaryText)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, SpacingTokens.sm)
                    
                    Button("Retry") {
                        Task {
                            await retryLoadMediaBundle()
                        }
                    }
                    .font(TypographyScale.caption1)
                    .foregroundColor(ColorTokens.link)
                    .padding(.top, SpacingTokens.xs)
                }
            }
    }
    
    private var errorMessage: String {
        if let mediaError = error as? MediaBundleError {
            return mediaError.localizedDescription
        } else {
            return "Unable to load media"
        }
    }
    
    private func loadMediaBundle() async {
        do {
            // Use the real MediaBundleService from dependencies
            guard let mediaBundleService = deps.mediaBundle else {
                // Fallback to mock data if service is not available
                await loadMockMediaBundle()
                return
            }
            
            // Fetch real media bundle data
            let bundleInfo = try await mediaBundleService.getMediaBundleInfo(bundleId: bundleId)
            
            // Convert to our internal MediaBundleInfo format
            let internalType: MediaType = bundleInfo.type == MediaBundleType.image ? .image : .video
            mediaBundle = MediaBundleInfo(
                id: bundleInfo.id,
                type: internalType,
                urls: bundleInfo.urls,
                duration: bundleInfo.duration
            )
            
        } catch {
            print("[MediaContentView] Failed to load media bundle \(bundleId): \(error)")
            
            // Handle different types of errors appropriately
            if let mediaError = error as? MediaBundleError {
                switch mediaError {
                case .notFound:
                    // Bundle doesn't exist - show error state
                    self.error = mediaError
                case .creationFailed, .invalidImageCount:
                    // These shouldn't happen during fetching, but handle gracefully
                    self.error = mediaError
                }
            } else {
                // Network or other errors - fallback to mock data for development
                print("[MediaContentView] Network/unknown error, falling back to mock data")
                await loadMockMediaBundle()
            }
        }
        
        isLoading = false
    }
    
    private func loadMockMediaBundle() async {
        // Fallback mock implementation for development/testing
        // No simulation delay - skeleton loading provides visual feedback
        
        if bundleId.contains("image") {
            mediaBundle = MediaBundleInfo(
                id: bundleId,
                type: .image,
                urls: [
                    "https://picsum.photos/800/600",
                    "https://picsum.photos/800/601",
                    "https://picsum.photos/800/602"
                ],
                duration: nil
            )
        } else if bundleId.contains("video") {
            mediaBundle = MediaBundleInfo(
                id: bundleId,
                type: .video,
                urls: [
                    "http://commondatastorage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"
                ],
                duration: 596.0
            )
        } else {
            error = NSError(domain: "MediaContentView", code: 404, userInfo: [NSLocalizedDescriptionKey: "Media bundle not found"])
        }
    }
    
    private func retryLoadMediaBundle() async {
        // Reset state for retry
        isLoading = true
        error = nil
        mediaBundle = nil
        
        // Reload the media bundle
        await loadMediaBundle()
    }
}

// MARK: - Supporting Types

private struct MediaBundleInfo {
    let id: String
    let type: MediaType
    let urls: [String]
    let duration: TimeInterval?
}

private enum MediaType {
    case image
    case video
}

// MARK: - Previews

#if DEBUG
#Preview("Media Content View - Loading") {
    MediaContentView(
        bundleId: "loading-bundle",
        onImageTap: { index in
            print("Image tapped: \(index)")
        },
        onVideoTap: {
            print("Video tapped")
        }
    )
    .padding()
}

#Preview("Media Content View - Error") {
    MediaContentView(
        bundleId: "error-bundle",
        onImageTap: { index in
            print("Image tapped: \(index)")
        },
        onVideoTap: {
            print("Video tapped")
        }
    )
    .padding()
}
#endif
