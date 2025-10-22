//
//  InlineVideoPlayer.swift
//  DesignSystem
//
//  Inline video player for feed with thumbnail overlay
//

import SwiftUI
import AVKit
import AppFoundation

/// Inline video player that shows thumbnail with play button overlay
public struct InlineVideoPlayer: View {
    let videoUrl: String
    let thumbnailUrl: String?
    let duration: TimeInterval?
    let onVideoTap: () -> Void
    
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    @State private var showControls = false
    
    public init(
        videoUrl: String,
        thumbnailUrl: String? = nil,
        duration: TimeInterval? = nil,
        onVideoTap: @escaping () -> Void = {}
    ) {
        self.videoUrl = videoUrl
        self.thumbnailUrl = thumbnailUrl
        self.duration = duration
        self.onVideoTap = onVideoTap
    }
    
    public var body: some View {
        ZStack {
            // Video player (hidden initially)
            if let player = player {
                VideoPlayer(player: player)
                    .aspectRatio(16/9, contentMode: .fit)
                    .frame(maxHeight: 400)
                    .clipShape(RoundedRectangle(cornerRadius: BorderRadiusTokens.md))
                    .opacity(isPlaying ? 1 : 0)
            }
            
            // Thumbnail overlay
            if !isPlaying {
                thumbnailView
            }
            
            // Play button overlay
            if !isPlaying {
                playButtonOverlay
            }
            
            // Duration badge
            if let duration = duration, !isPlaying {
                durationBadge(duration)
            }
        }
        .onTapGesture {
            if isPlaying {
                togglePlayPause()
            } else {
                onVideoTap()
            }
        }
        .onAppear {
            setupPlayer()
        }
        .onDisappear {
            player?.pause()
        }
    }
    
    private var thumbnailView: some View {
        AsyncImage(url: URL(string: thumbnailUrl ?? "")) { phase in
            switch phase {
            case .empty:
                placeholderView
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            case .failure:
                placeholderView
            @unknown default:
                placeholderView
            }
        }
        .aspectRatio(contentMode: .fit)
        .frame(maxHeight: 400)
        .clipShape(RoundedRectangle(cornerRadius: BorderRadiusTokens.md))
    }
    
    private var placeholderView: some View {
        Rectangle()
            .fill(ColorTokens.separator.opacity(0.2))
            .aspectRatio(16/9, contentMode: .fit)
            .frame(maxHeight: 400)
            .clipShape(RoundedRectangle(cornerRadius: BorderRadiusTokens.md))
            .overlay {
                Image(systemName: "play.rectangle")
                    .font(.system(size: 40))
                    .foregroundColor(ColorTokens.tertiaryText)
            }
    }
    
    private var playButtonOverlay: some View {
        ZStack {
            // Semi-transparent overlay
            Circle()
                .fill(Color.black.opacity(0.3))
                .frame(width: 60, height: 60)
            
            // Play icon
            Image(systemName: "play.fill")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.white)
                .offset(x: 2) // Slight offset to center the triangle
        }
    }
    
    private func durationBadge(_ duration: TimeInterval) -> some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Text(formatDuration(duration))
                    .font(TypographyScale.caption2)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, SpacingTokens.xs)
                    .padding(.vertical, 2)
                    .background(Color.black.opacity(0.7))
                    .clipShape(RoundedRectangle(cornerRadius: 4))
                    .padding(.trailing, SpacingTokens.xs)
                    .padding(.bottom, SpacingTokens.xs)
            }
        }
    }
    
    private func setupPlayer() {
        guard let url = URL(string: videoUrl) else { return }
        
        player = AVPlayer(url: url)
        player?.isMuted = true // Muted by default in feed
        
        // Add observer for playback status
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player?.currentItem,
            queue: .main
        ) { _ in
            Task { @MainActor in
                player?.seek(to: .zero)
                isPlaying = false
            }
        }
    }
    
    private func togglePlayPause() {
        guard let player = player else { return }
        
        if isPlaying {
            player.pause()
        } else {
            player.play()
        }
        isPlaying.toggle()
    }
    
    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        let seconds = Int(duration) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Video with Thumbnail") {
    InlineVideoPlayer(
        videoUrl: "https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4",
        thumbnailUrl: "https://picsum.photos/800/450",
        duration: 120.5,
        onVideoTap: {
            print("Video tapped")
        }
    )
    .padding()
}

#Preview("Video without Thumbnail") {
    InlineVideoPlayer(
        videoUrl: "https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4",
        duration: 45.0,
        onVideoTap: {
            print("Video tapped")
        }
    )
    .padding()
}
#endif
