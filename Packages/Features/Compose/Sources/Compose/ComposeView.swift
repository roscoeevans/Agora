//
//  ComposeView.swift
//  Agora
//
//  Created by Agora Team on 2024.
//

import SwiftUI
import UIKitBridge
import DesignSystem
import AppFoundation
import Verification
import Authentication
import AVKit

public struct ComposeView: View {
    @Environment(\.deps) private var deps
    @Environment(AuthStateManager.self) private var authManager
    @State private var viewModel: ComposeViewModel?
    @Environment(\.dismiss) private var dismiss
    let quotePostId: String?
    
    public init(quotePostId: String? = nil) {
        self.quotePostId = quotePostId
    }
    
    public var body: some View {
        content
            .task {
                // Initialize view model with dependencies from environment
                // Following DI rule: dependencies injected from environment
                guard let mediaBundleService = deps.mediaBundle else {
                    print("[ComposeView] ❌ MediaBundleService not available in dependencies")
                    return
                }
                
                let vm = ComposeViewModel(
                    networking: deps.networking,
                    verificationManager: AppAttestManager.shared,
                    mediaBundleService: mediaBundleService,
                    authStateManager: authManager
                )
                vm.quotePostId = quotePostId
                self.viewModel = vm
            }
    }
    
    @ViewBuilder
    private var content: some View {
        if let vm = viewModel {
            ComposeContentView(viewModel: vm, authManager: authManager, dismiss: dismiss)
        } else {
            PostingOverlay()
        }
    }
}

struct ComposeContentView: View {
    let viewModel: ComposeViewModel
    let authManager: AuthStateManager
    let dismiss: DismissAction
    
    var body: some View {
        NavigationStack {
            ComposeMainContent(viewModel: viewModel, authManager: authManager)
                .navigationTitle("New post")
                #if os(iOS)
                .navigationBarTitleDisplayMode(.inline)
                .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
                #endif
                .toolbar {
                    ComposeToolbar(viewModel: viewModel, dismiss: dismiss)
                }
                .overlay {
                    if viewModel.isPosting {
                        PostingOverlay()
                    }
                }
                .alert("Couldn't Post", isPresented: .constant(viewModel.error != nil)) {
                    Button("Try Again") {
                        viewModel.error = nil
                        Task {
                            await viewModel.post()
                        }
                    }
                    Button("Cancel", role: .cancel) {
                        viewModel.error = nil
                    }
                } message: {
                    Text("Please check your connection and try again.")
                }
                .onAppear {
                    viewModel.loadDraft()
                }
                .onDisappear {
                    if !viewModel.text.isEmpty {
                        viewModel.saveDraft()
                    }
                }
                .onChange(of: viewModel.text) { _, newValue in
                    // Debounce link preview fetch
                    Task {
                        try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 second debounce
                        await viewModel.detectAndFetchLinkPreview()
                    }
                }
        }
    }
}

struct ComposeMainContent: View {
    let viewModel: ComposeViewModel
    let authManager: AuthStateManager
    @State private var showPhotoPicker = false
    @State private var showVideoPicker = false
    
    private var hasPhotos: Bool {
        viewModel.selectedMedia.contains { $0.type == .photo }
    }
    
    private var hasVideo: Bool {
        viewModel.selectedMedia.contains { $0.type == .video }
    }
    
    var body: some View {
        VStack(spacing: SpacingTokens.md) {
            // User profile section
            HStack(alignment: .top, spacing: SpacingTokens.sm) {
                // User avatar
                if let user = authManager.state.currentUser {
                    AsyncImage(url: user.avatarUrl.flatMap(URL.init)) { image in
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                    } placeholder: {
                        Circle()
                            .fill(ColorTokens.agoraBrand)
                            .overlay {
                                Text(String(user.displayHandle.prefix(1)).uppercased())
                                    .font(TypographyScale.calloutEmphasized)
                                    .foregroundColor(.white)
                            }
                    }
                    .frame(width: 40, height: 40)
                    .clipShape(Circle())
                } else {
                    Circle()
                        .fill(ColorTokens.agoraBrand)
                        .frame(width: 40, height: 40)
                        .overlay {
                            Text("U")
                                .font(TypographyScale.calloutEmphasized)
                                .foregroundColor(.white)
                        }
                }
                
                VStack(alignment: .leading, spacing: SpacingTokens.xxs) {
                    Text(authManager.state.currentUser?.displayHandle ?? "username")
                        .font(TypographyScale.calloutEmphasized)
                        .foregroundColor(ColorTokens.primaryText)
                    
                    // Text input area
                    ZStack(alignment: .topLeading) {
                        TextEditor(text: Binding(
                            get: { viewModel.text },
                            set: { viewModel.text = $0 }
                        ))
                        .font(TypographyScale.body)
                        .foregroundColor(ColorTokens.primaryText)
                        .scrollContentBackground(.hidden)
                        .background(Color.clear)
                        .frame(minHeight: 100)
                        .padding(.horizontal, -4)
                        .accessibilityLabel("Compose post text")
                        .accessibilityHint("Type your post content here")
                        
                        if viewModel.text.isEmpty {
                            Text("What's new?")
                                .font(TypographyScale.body)
                                .foregroundColor(ColorTokens.quaternaryText)
                                .padding(.top, 8)
                                .allowsHitTesting(false)
                        }
                    }
                }
            }
            .padding(.horizontal, SpacingTokens.md)
            
            // Character count
            HStack {
                Spacer()
                Text("\(viewModel.characterCount)/280")
                    .font(TypographyScale.caption1)
                    .foregroundColor(viewModel.isOverLimit ? ColorTokens.error : ColorTokens.tertiaryText)
            }
            .padding(.horizontal, SpacingTokens.md)
            
            // Link preview
            if let linkPreview = viewModel.linkPreview {
                LinkPreviewCard(preview: linkPreview) {
                    viewModel.linkPreview = nil
                }
            }
            
            // Media selection area
            if !viewModel.selectedMedia.isEmpty {
                MediaPreviewView(mediaItems: viewModel.selectedMedia) { item in
                    viewModel.removeMedia(item)
                }
            }
            
            // Media buttons row
            HStack(spacing: SpacingTokens.lg) {
                // Image button with MediaPickerBridge
                Button(action: {
                    DesignSystemBridge.lightImpact()
                    showPhotoPicker = true
                }) {
                    Image(systemName: "photo")
                        .font(.system(size: 20))
                        .foregroundColor(hasVideo ? ColorTokens.quaternaryText : ColorTokens.agoraBrand)
                }
                .disabled(hasVideo)
                .accessibilityLabel("Add photos")
                .accessibilityHint(hasVideo ? "Cannot add photos when video is present" : "Add up to 4 photos")
                .sheet(isPresented: $showPhotoPicker) {
                    PhotoMediaPickerSheet(viewModel: viewModel)
                }
                
                // Video button with MediaPickerBridge
                Button(action: {
                    DesignSystemBridge.lightImpact()
                    showVideoPicker = true
                }) {
                    Image(systemName: "video")
                        .font(.system(size: 20))
                        .foregroundColor(hasPhotos ? ColorTokens.quaternaryText : ColorTokens.agoraBrand)
                }
                .disabled(hasPhotos)
                .accessibilityLabel("Add video")
                .accessibilityHint(hasPhotos ? "Cannot add video when photos are present" : "Add 1 video (no mixed media)")
                .sheet(isPresented: $showVideoPicker) {
                    VideoMediaPickerSheet(viewModel: viewModel)
                }
                
                Spacer()
                
                // Self-destruct timer button
                Menu {
                    // Predefined options
                    ForEach(SelfDestructDuration.predefinedCases, id: \.id) { duration in
                        Button {
                            DesignSystemBridge.lightImpact()
                            viewModel.selfDestructDuration = duration
                        } label: {
                            HStack {
                                Image(systemName: duration.icon)
                                VStack(alignment: .leading, spacing: SpacingTokens.xxs) {
                                    Text(duration.rawValue)
                                        .font(TypographyScale.callout)
                                    Text(duration.description)
                                        .font(TypographyScale.caption2)
                                        .foregroundColor(ColorTokens.secondaryText)
                                }
                                
                                if isSelected(duration) {
                                    Spacer()
                                    Image(systemName: "checkmark")
                                        .foregroundColor(ColorTokens.agoraBrand)
                                }
                            }
                        }
                    }
                    
                    Divider()
                    
                    // Custom option
                    Button {
                        DesignSystemBridge.lightImpact()
                        // TODO: Present custom date picker
                    } label: {
                        HStack {
                            Image(systemName: "calendar")
                            VStack(alignment: .leading, spacing: SpacingTokens.xxs) {
                                Text("Custom")
                                    .font(TypographyScale.callout)
                                Text("Pick a specific date & time")
                                    .font(TypographyScale.caption2)
                                    .foregroundColor(ColorTokens.secondaryText)
                            }
                            
                            if case .custom = viewModel.selfDestructDuration {
                                Spacer()
                                Image(systemName: "checkmark")
                                    .foregroundColor(ColorTokens.agoraBrand)
                            }
                        }
                    }
                } label: {
                    Image(systemName: "timer")
                        .font(.system(size: 20))
                        .foregroundColor(timerIconColor)
                }
                .accessibilityLabel("Self-destruct timer")
                .accessibilityHint("Set when this post should automatically delete")
            }
            .padding(.horizontal, SpacingTokens.md)
            
            // Reply permissions
            HStack {
                Text("Anyone can reply & quote")
                    .font(TypographyScale.caption1)
                    .foregroundColor(ColorTokens.tertiaryText)
                
                Spacer()
            }
            .padding(.horizontal, SpacingTokens.md)
            
            Spacer()
        }
        .padding(SpacingTokens.md)
    }
    
    // Helper function to check if a duration is selected
    private func isSelected(_ duration: SelfDestructDuration) -> Bool {
        switch (viewModel.selfDestructDuration, duration) {
        case (.none, .none):
            return true
        case (.twentyFourHours, .twentyFourHours):
            return true
        case (.threeDays, .threeDays):
            return true
        case (.oneWeek, .oneWeek):
            return true
        case (.custom, _):
            return false
        case (_, .custom):
            return false
        default:
            return false
        }
    }
    
    // Timer icon color based on selection
    private var timerIconColor: Color {
        switch viewModel.selfDestructDuration {
        case .none:
            return ColorTokens.agoraBrand
        default:
            return ColorTokens.agoraBrand
        }
    }
}

struct ComposeToolbar: ToolbarContent {
    let viewModel: ComposeViewModel
    let dismiss: DismissAction
    
    var body: some ToolbarContent {
        #if os(iOS)
        ToolbarItem(placement: .navigationBarLeading) {
            Button(action: {
                // Add haptic feedback
                DesignSystemBridge.lightImpact()
                dismiss()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(ColorTokens.primaryText)
            }
            .accessibilityLabel("Cancel composing post")
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
            Button(action: {
                // Add haptic feedback
                DesignSystemBridge.mediumImpact()
                
                Task {
                    await viewModel.post()
                    if viewModel.error == nil {
                        dismiss()
                    }
                }
            }) {
                Image(systemName: "checkmark")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(viewModel.canPost ? ColorTokens.agoraBrand : ColorTokens.quaternaryText)
            }
            .disabled(!viewModel.canPost)
            .accessibilityLabel("Post content")
            .accessibilityHint(viewModel.canPost ? "Double tap to publish your post" : "Cannot post - content is empty or over character limit")
        }
        #else
        ToolbarItem(placement: .cancellationAction) {
            Button("Cancel") {
                // Add haptic feedback
                DesignSystemBridge.lightImpact()
                dismiss()
            }
            .foregroundColor(ColorTokens.primaryText)
            .accessibilityLabel("Cancel composing post")
        }
        
        ToolbarItem(placement: .confirmationAction) {
            Button("Post") {
                // Add haptic feedback
                DesignSystemBridge.mediumImpact()
                
                Task {
                    await viewModel.post()
                    if viewModel.error == nil {
                        dismiss()
                    }
                }
            }
            .disabled(!viewModel.canPost)
            .foregroundColor(viewModel.canPost ? ColorTokens.agoraBrand : ColorTokens.quaternaryText)
            .font(TypographyScale.calloutEmphasized)
            .accessibilityLabel("Post content")
            .accessibilityHint(viewModel.canPost ? "Double tap to publish your post" : "Cannot post - content is empty or over character limit")
        }
        #endif
    }
}

struct MediaPreviewView: View {
    let mediaItems: [MediaItem]
    let onRemove: (MediaItem) -> Void
    
    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: SpacingTokens.sm) {
                ForEach(mediaItems) { item in
                    MediaPreviewCard(item: item) {
                        onRemove(item)
                    }
                }
            }
            .padding(.horizontal, SpacingTokens.md)
        }
        .frame(height: 200)
    }
}

struct MediaPreviewCard: View {
    let item: MediaItem
    let onRemove: () -> Void
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            // Media content
            if item.type == .photo, let imageData = item.imageData {
                #if canImport(UIKit)
                if let uiImage = UIImage(data: imageData) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 180, height: 180)
                        .clipShape(RoundedRectangle(cornerRadius: BorderRadiusTokens.md))
                }
                #else
                Color.gray.opacity(0.3)
                    .frame(width: 180, height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: BorderRadiusTokens.md))
                #endif
            } else if item.type == .video, let videoURL = item.videoURL {
                VideoPlayer(player: AVPlayer(url: videoURL))
                    .frame(width: 320, height: 180)
                    .aspectRatio(16/9, contentMode: .fit)
                    .clipShape(RoundedRectangle(cornerRadius: BorderRadiusTokens.md))
                    .overlay(alignment: .bottomTrailing) {
                        // Muted indicator
                        Image(systemName: "speaker.slash.fill")
                            .font(.system(size: 14))
                            .foregroundColor(.white)
                            .padding(6)
                            .background(Color.black.opacity(0.6))
                            .clipShape(Circle())
                            .padding(SpacingTokens.xs)
                    }
            }
            
            // Remove button
            Button(action: {
                DesignSystemBridge.lightImpact()
                onRemove()
            }) {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 20, height: 20)
                    .background(Color.black.opacity(0.7))
                    .clipShape(Circle())
            }
            .padding(6)
            .accessibilityLabel("Remove \(item.type == .photo ? "photo" : "video")")
            .accessibilityHint("Double tap to remove this media item")
        }
    }
}

struct MediaPickerButtonView: View {
    let onMediaSelected: (MediaItem) -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            // Add haptic feedback
            DesignSystemBridge.lightImpact()
            
            // TODO: Present media picker
            // For now, add a placeholder media item
            let placeholderItem = MediaItem(type: .photo)
            onMediaSelected(placeholderItem)
        }) {
            HStack(spacing: SpacingTokens.xs) {
                Image(systemName: "photo")
                    .font(TypographyScale.callout)
                    .symbolEffect(.bounce, value: isPressed)
                
                Text("Add Photo or Video")
                    .font(TypographyScale.callout)
            }
            .foregroundColor(ColorTokens.agoraBrand)
            .padding(.vertical, SpacingTokens.sm)
            .padding(.horizontal, SpacingTokens.md)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: BorderRadiusTokens.sm))
            .overlay(
                RoundedRectangle(cornerRadius: BorderRadiusTokens.sm)
                    .stroke(ColorTokens.agoraBrand.opacity(0.3), lineWidth: 1.5)
            )
            .frame(minHeight: 44) // Ensure 44pt minimum height
        }
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .animation(.easeInOut(duration: 0.1), value: isPressed)
        .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .accessibilityLabel("Add photo or video")
        .accessibilityHint("Double tap to select media from your library")
    }
}

struct PostingOverlay: View {
    var body: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: SpacingTokens.md) {
                ProgressView()
                    .scaleEffect(1.2)
                
                Text("Posting...")
                    .font(TypographyScale.callout)
                    .foregroundColor(ColorTokens.secondaryText)
            }
            .padding(SpacingTokens.xl)
            .background(.thickMaterial, in: RoundedRectangle(cornerRadius: BorderRadiusTokens.xl))
            .agoraShadow(ShadowTokens.floating)
        }
    }
}

// MARK: - Media Picker Sheet Helpers

#if canImport(PhotosUI) && canImport(UIKit)
import PhotosUI

@available(iOS 26.0, *)
struct PhotoMediaPickerSheet: View {
    let viewModel: ComposeViewModel
    
    var body: some View {
        MediaPickerBridge(
            maxSelectionCount: 4,
            filter: .images
        ) { selectedItems in
            Task {
                await viewModel.processMediaPickerPhotos(selectedItems)
            }
        }
    }
}

@available(iOS 26.0, *)
struct VideoMediaPickerSheet: View {
    let viewModel: ComposeViewModel
    
    var body: some View {
        MediaPickerBridge(
            maxSelectionCount: 1,
            filter: .videos
        ) { selectedItems in
            Task {
                await viewModel.processMediaPickerVideo(selectedItems.first)
            }
        }
    }
}
#else
// Fallback for non-iOS platforms
struct PhotoMediaPickerSheet: View {
    let viewModel: ComposeViewModel
    var body: some View { EmptyView() }
}

struct VideoMediaPickerSheet: View {
    let viewModel: ComposeViewModel
    var body: some View { EmptyView() }
}
#endif

#if DEBUG
#Preview("Compose Post") {
    PreviewDeps.scoped {
        ComposeView()
    }
}

#Preview("Quote Post") {
    PreviewDeps.scoped {
        ComposeView(quotePostId: "preview-quote-id")
    }
}
#endif