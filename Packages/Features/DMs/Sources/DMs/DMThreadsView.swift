//
//  DMThreadsView.swift
//  Agora
//
//  Created by Agora Team on 2024.
//

import SwiftUI
import DesignSystem
import AppFoundation

public struct DMThreadsView: View {
    @Environment(\.deps) private var deps
    @State private var viewModel: DMThreadsViewModel?
    
    public init() {}
    
    public var body: some View {
        Group {
            if let viewModel = viewModel {
                NavigationStack {
                    ScrollView {
                        LazyVStack(spacing: 0) {
                            if viewModel.threads.isEmpty && !viewModel.isLoading {
                                EmptyStateView()
                            } else {
                                ForEach(viewModel.threads, id: \.id) { thread in
                                    DMThreadRow(thread: thread) {
                                        // TODO: Navigate to chat view
                                    }
                                }
                            }
                        }
                    }
                    .navigationTitle("Messages")
                    .navigationBarTitleDisplayMode(.large)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button(action: {
                                // TODO: Start new conversation
                            }) {
                                Image(systemName: "square.and.pencil")
                                    .foregroundColor(ColorTokens.agoraBrand)
                            }
                        }
                    }
                    .refreshable {
                        await viewModel.refresh()
                    }
                    .overlay {
                        if viewModel.isLoading && viewModel.threads.isEmpty {
                            LoadingView()
                        }
                    }
                    .task {
                        await viewModel.loadThreads()
                    }
                }
            } else {
                LoadingView()
            }
        }
        .task {
            // Initialize view model with dependencies from environment
            // Following DI rule: dependencies injected from environment
            self.viewModel = DMThreadsViewModel(networking: deps.networking)
        }
    }
}

struct DMThreadRow: View {
    let thread: DMThread
    let onTap: () -> Void
    
    var body: some View {
        HStack(spacing: SpacingTokens.sm) {
            // Avatar
            Circle()
                .fill(ColorTokens.agoraBrand)
                .frame(width: 48, height: 48)
                .overlay {
                    Text(String(thread.otherUser.displayName.prefix(1)))
                        .font(TypographyScale.callout)
                        .foregroundColor(.white)
                }
            
            // Content
            VStack(alignment: .leading, spacing: SpacingTokens.xxs) {
                HStack {
                    Text(thread.otherUser.displayName)
                        .font(thread.hasUnreadMessages ? TypographyScale.calloutEmphasized : TypographyScale.callout)
                        .foregroundColor(ColorTokens.primaryText)
                    
                    Spacer()
                    
                    Text(thread.lastMessage.timestamp, style: .relative)
                        .font(TypographyScale.caption1)
                        .foregroundColor(ColorTokens.tertiaryText)
                }
                
                HStack {
                    Text(thread.lastMessage.text)
                        .font(TypographyScale.body)
                        .foregroundColor(thread.hasUnreadMessages ? ColorTokens.primaryText : ColorTokens.secondaryText)
                        .lineLimit(2)
                    
                    Spacer()
                    
                    if thread.hasUnreadMessages {
                        Circle()
                            .fill(ColorTokens.agoraBrand)
                            .frame(width: 8, height: 8)
                    }
                }
            }
        }
        .padding(SpacingTokens.md)
        .background(ColorTokens.background)
        .onTapGesture {
            onTap()
        }
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: SpacingTokens.lg) {
            Image(systemName: "message")
                .font(.system(size: 48))
                .foregroundColor(ColorTokens.tertiaryText)
            
            Text("No Messages")
                .font(TypographyScale.title2)
                .foregroundColor(ColorTokens.primaryText)
            
            Text("Start a conversation by tapping the compose button above.")
                .font(TypographyScale.body)
                .foregroundColor(ColorTokens.secondaryText)
                .multilineTextAlignment(.center)
        }
        .padding(SpacingTokens.xl)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct LoadingView: View {
    var body: some View {
        VStack(spacing: SpacingTokens.md) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading messages...")
                .font(TypographyScale.callout)
                .foregroundColor(ColorTokens.secondaryText)
        }
        .padding(SpacingTokens.xl)
    }
}

#Preview {
    DMThreadsView()
}