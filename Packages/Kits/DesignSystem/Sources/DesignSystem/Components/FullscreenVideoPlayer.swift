//
//  FullscreenVideoPlayer.swift
//  DesignSystem
//
//  TikTok-inspired fullscreen video player
//

import SwiftUI
import AVKit
import AppFoundation

/// Fullscreen video player with TikTok-style controls
public struct FullscreenVideoPlayer: View {
    let videoUrl: String
    let bundleId: String
    
    @State private var player: AVPlayer?
    @State private var isPlaying = false
    @State private var isMuted = true
    @State private var currentTime: TimeInterval = 0
    @State private var duration: TimeInterval = 0
    @State private var showControls = false
    @State private var dragOffset: CGSize = .zero
    
    @Environment(\.dismiss) private var dismiss
    
    public init(videoUrl: String, bundleId: String) {
        self.videoUrl = videoUrl
        self.bundleId = bundleId
    }
    
    public var body: some View {
        ZStack {
            // Background
            Color.black
                .ignoresSafeArea()
            
            // Video player
            if let player = player {
                VideoPlayer(player: player)
                    .ignoresSafeArea()
                    .onTapGesture {
                        togglePlayPause()
                    }
                    .gesture(
                        DragGesture()
                            .onChanged { value in
                                dragOffset = value.translation
                            }
                            .onEnded { value in
                                if abs(value.translation.height) > 100 {
                                    dismiss()
                                } else {
                                    withAnimation(.spring()) {
                                        dragOffset = .zero
                                    }
                                }
                            }
                    )
                    .offset(dragOffset)
            }
            
            // Controls overlay
            VStack {
                // Top controls
                HStack {
                    // Close button
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.black.opacity(0.3))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    // Mute button
                    Button(action: { toggleMute() }) {
                        Image(systemName: isMuted ? "speaker.slash.fill" : "speaker.fill")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 44, height: 44)
                            .background(Color.black.opacity(0.3))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, SpacingTokens.md)
                .padding(.top, SpacingTokens.md)
                
                Spacer()
                
                // Bottom controls
                VStack(spacing: SpacingTokens.sm) {
                    // Progress bar
                    progressBar
                    
                    // Play/pause button
                    Button(action: { togglePlayPause() }) {
                        Image(systemName: isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 60, height: 60)
                            .background(Color.black.opacity(0.3))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, SpacingTokens.md)
                .padding(.bottom, SpacingTokens.lg)
            }
            .opacity(showControls ? 1 : 0)
            .animation(.easeInOut(duration: 0.2), value: showControls)
        }
        #if os(iOS)
        .navigationBarHidden(true)
        #endif
        .onAppear {
            setupPlayer()
            showControls = true
            
            // Auto-hide controls after 3 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                withAnimation {
                    showControls = false
                }
            }
        }
        .onDisappear {
            player?.pause()
        }
        .onTapGesture {
            withAnimation {
                showControls.toggle()
            }
            
            // Auto-hide after showing
            if showControls {
                DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                    withAnimation {
                        showControls = false
                    }
                }
            }
        }
    }
    
    private var progressBar: some View {
        VStack(spacing: SpacingTokens.xs) {
            // Progress slider
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    Rectangle()
                        .fill(Color.white.opacity(0.3))
                        .frame(height: 4)
                        .clipShape(Capsule())
                    
                    // Progress track
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: geometry.size.width * (currentTime / max(duration, 1)), height: 4)
                        .clipShape(Capsule())
                }
                .gesture(
                    DragGesture()
                        .onChanged { value in
                            let progress = value.location.x / geometry.size.width
                            let newTime = progress * duration
                            seekTo(time: newTime)
                        }
                )
            }
            .frame(height: 4)
            
            // Time labels
            HStack {
                Text(formatTime(currentTime))
                    .font(TypographyScale.caption2)
                    .foregroundColor(.white)
                
                Spacer()
                
                Text(formatTime(duration))
                    .font(TypographyScale.caption2)
                    .foregroundColor(.white)
            }
        }
    }
    
    private func setupPlayer() {
        guard let url = URL(string: videoUrl) else { return }
        
        player = AVPlayer(url: url)
        player?.isMuted = isMuted
        
        // Add time observer
        _ = player?.addPeriodicTimeObserver(
            forInterval: CMTime(seconds: 0.1, preferredTimescale: CMTimeScale(NSEC_PER_SEC)),
            queue: .main
        ) { time in
            Task { @MainActor in
                currentTime = CMTimeGetSeconds(time)
            }
        }
        
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
        
        // Get duration
        if let duration = player?.currentItem?.duration {
            self.duration = CMTimeGetSeconds(duration)
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
    
    private func toggleMute() {
        guard let player = player else { return }
        
        isMuted.toggle()
        player.isMuted = isMuted
    }
    
    private func seekTo(time: TimeInterval) {
        guard let player = player else { return }
        
        let cmTime = CMTime(seconds: time, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player.seek(to: cmTime)
        currentTime = time
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Fullscreen Video Player") {
    NavigationStack {
        FullscreenVideoPlayer(
            videoUrl: "https://sample-videos.com/zip/10/mp4/SampleVideo_1280x720_1mb.mp4",
            bundleId: "test-bundle"
        )
    }
}
#endif
