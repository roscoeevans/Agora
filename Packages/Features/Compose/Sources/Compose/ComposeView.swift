//
//  ComposeView.swift
//  Agora
//
//  Created by Agora Team on 2024.
//

import SwiftUI
import DesignSystem
import AppFoundation
import Verification

public struct ComposeView: View {
    @Environment(\.deps) private var deps
    @State private var viewModel: ComposeViewModel?
    @Environment(\.dismiss) private var dismiss
    
    public init() {}
    
    public var body: some View {
        content
            .task {
                // Initialize view model with dependencies from environment
                // Following DI rule: dependencies injected from environment
                self.viewModel = ComposeViewModel(
                    networking: deps.networking,
                    verificationManager: AppAttestManager.shared
                )
            }
    }
    
    @ViewBuilder
    private var content: some View {
        if let vm = viewModel {
            NavigationStack {
                    VStack(spacing: SpacingTokens.md) {
                        // Text input area
                        TextEditor(text: Binding(
                            get: { vm.text },
                            set: { vm.text = $0 }
                        ))
                            .font(TypographyScale.body)
                            .foregroundColor(ColorTokens.primaryText)
                            .padding(SpacingTokens.md)
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: BorderRadiusTokens.md))
                            .overlay(
                                RoundedRectangle(cornerRadius: BorderRadiusTokens.md)
                                    .stroke(
                                        vm.isOverLimit ? ColorTokens.error : ColorTokens.separator.opacity(0.3),
                                        lineWidth: vm.isOverLimit ? 2 : 1
                                    )
                            )
                            .frame(minHeight: 120)
                            .accessibilityLabel("Compose post text")
                            .accessibilityHint("Type your post content here")
                        
                        // Character count
                        HStack {
                            Spacer()
                            Text("\(vm.characterCount)/70")
                                .font(TypographyScale.caption1)
                                .foregroundColor(vm.isOverLimit ? ColorTokens.error : ColorTokens.tertiaryText)
                        }
                        
                        // Media selection area
                        if !vm.selectedMedia.isEmpty {
                            MediaPreviewView(mediaItems: vm.selectedMedia) { item in
                                vm.removeMedia(item)
                            }
                        }
                        
                        // Media picker button
                        MediaPickerButton { item in
                            vm.addMedia(item)
                        }
                        
                        Spacer()
                    }
                    .padding(SpacingTokens.md)
                    .navigationTitle("New Post")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Cancel") {
                                // Add haptic feedback
                                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                                impactFeedback.impactOccurred()
                                dismiss()
                            }
                            .foregroundColor(ColorTokens.primaryText)
                            .accessibilityLabel("Cancel composing post")
                        }
                        
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Post") {
                                // Add haptic feedback
                                let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
                                impactFeedback.impactOccurred()
                                
                                Task {
                                    await vm.post()
                                    if vm.error == nil {
                                        dismiss()
                                    }
                                }
                            }
                            .disabled(!vm.canPost)
                            .foregroundColor(vm.canPost ? ColorTokens.agoraBrand : ColorTokens.quaternaryText)
                            .font(TypographyScale.calloutEmphasized)
                            .accessibilityLabel("Post content")
                            .accessibilityHint(vm.canPost ? "Double tap to publish your post" : "Cannot post - content is empty or over character limit")
                        }
                    }
                    .overlay {
                        if vm.isPosting {
                            PostingOverlay()
                        }
                    }
                    .alert("Couldn't Post", isPresented: .constant(vm.error != nil)) {
                        Button("Try Again") {
                            vm.error = nil
                            Task {
                                await vm.post()
                            }
                        }
                        Button("Cancel", role: .cancel) {
                            vm.error = nil
                        }
                    } message: {
                        Text("Please check your connection and try again.")
                    }
                    .onAppear {
                        vm.loadDraft()
                    }
                    .onDisappear {
                        if !vm.text.isEmpty {
                            vm.saveDraft()
                        }
                    }
                }
        } else {
            PostingOverlay()
        }
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
    }
}

struct MediaPreviewCard: View {
    let item: MediaItem
    let onRemove: () -> Void
    @State private var isPressed = false
    
    var body: some View {
        ZStack(alignment: .topTrailing) {
            RoundedRectangle(cornerRadius: BorderRadiusTokens.md)
                .fill(.regularMaterial)
                .frame(width: 80, height: 80)
                .overlay {
                    Image(systemName: item.type == .photo ? "photo" : "video")
                        .font(.system(size: IconSizeTokens.lg))
                        .foregroundColor(ColorTokens.tertiaryText)
                }
                .agoraShadow(ShadowTokens.subtle)
            
            Button(action: {
                // Add haptic feedback
                let impactFeedback = UIImpactFeedbackGenerator(style: .light)
                impactFeedback.impactOccurred()
                onRemove()
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: IconSizeTokens.md))
                    .foregroundColor(ColorTokens.error)
                    .background(.regularMaterial, in: Circle())
                    .frame(width: 24, height: 24) // Ensure adequate touch target
            }
            .offset(x: 8, y: -8)
            .scaleEffect(isPressed ? 0.9 : 1.0)
            .animation(.easeInOut(duration: 0.1), value: isPressed)
            .onLongPressGesture(minimumDuration: 0, maximumDistance: .infinity, pressing: { pressing in
                isPressed = pressing
            }, perform: {})
            .accessibilityLabel("Remove \(item.type == .photo ? "photo" : "video")")
            .accessibilityHint("Double tap to remove this media item")
        }
    }
}

struct MediaPickerButton: View {
    let onMediaSelected: (MediaItem) -> Void
    @State private var isPressed = false
    
    var body: some View {
        Button(action: {
            // Add haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
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

#Preview {
    ComposeView()
}