import SwiftUI
import AppFoundation
import DesignSystem

/// Individual conversation view with message history and composer
public struct ConversationView: View {
    let conversationId: UUID
    @State private var viewModel: ConversationViewModel
    @State private var messageText = ""
    @State private var attachments: [Attachment] = []
    @Environment(\.deps) private var deps
    
    public init(conversationId: UUID) {
        self.conversationId = conversationId
        self._viewModel = State(initialValue: ConversationViewModel(conversationId: conversationId))
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Messages list
            if viewModel.isLoadingMessages && viewModel.messages.isEmpty {
                // Loading state
                VStack {
                    Spacer()
                    ProgressView()
                    Text("Loading messages...")
                        .font(TypographyScale.caption1)
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                    Spacer()
                }
            } else if viewModel.messages.isEmpty {
                // Empty state
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "message.circle")
                        .font(.system(size: 64))
                        .foregroundStyle(.secondary)
                    Text("No messages yet")
                        .font(TypographyScale.title2)
                        .fontWeight(.semibold)
                    Text("Start the conversation!")
                        .font(TypographyScale.body)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
            } else {
                // Message list
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            // Load more button for pagination
                            if !viewModel.hasReachedEnd {
                                Button {
                                    Task {
                                        await viewModel.loadOlderMessages()
                                    }
                                } label: {
                                    if viewModel.isLoadingOlderMessages {
                                        ProgressView()
                                            .scaleEffect(0.8)
                                    } else {
                                        Text("Load older messages")
                                            .font(TypographyScale.caption1)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding()
                            }
                            
                            // Messages
                            ForEach(viewModel.messages) { message in
                                MessageBubble(
                                    message: message,
                                    currentUserId: getCurrentUserId(),
                                    onCopy: {
                                        #if os(iOS)
                                        UIPasteboard.general.string = message.content
                                        #endif
                                    },
                                    onReply: {
                                        // TODO: Implement reply
                                    },
                                    onDelete: {
                                        // TODO: Implement delete
                                    },
                                    onReport: {
                                        // TODO: Implement report
                                    },
                                    onBlock: {
                                        // TODO: Implement block
                                    }
                                )
                                .id(message.id)
                            }
                        }
                        .padding()
                    }
                    .onChange(of: viewModel.messages.count) { _, _ in
                        // Auto-scroll to bottom on new messages
                        if let lastMessage = viewModel.messages.last {
                            withAnimation {
                                proxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }
            }
            
            // Typing indicator
            if viewModel.isAnyoneTyping {
                HStack {
                    Text(viewModel.typingIndicatorText)
                        .font(TypographyScale.caption1)
                        .foregroundStyle(.secondary)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 4)
                    Spacer()
                }
            }
            
            // Composer bar
            ComposerBar(
                conversationId: conversationId,
                text: $messageText,
                attachments: $attachments,
                onSend: {
                    Task {
                        await viewModel.sendMessage(messageText, attachments: attachments)
                        messageText = ""
                        attachments.removeAll()
                    }
                },
                onAttachmentTap: {
                    // Handled by ComposerBar internally
                }
            )
        }
        .navigationTitle(viewModel.conversationTitle)
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar(.hidden, for: .tabBar)
        #endif
        .task {
            // Initialize with dependencies
            viewModel = ConversationViewModel(
                conversationId: conversationId,
                messagingService: deps.messaging,
                messagingRealtime: deps.messagingRealtime,
                messagingMedia: deps.messagingMedia,
                eventTracker: deps.eventTracker
            )
            
            // Track conversation opened
            viewModel.trackConversationOpened()
            
            // Load messages
            await viewModel.loadMessages()
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    private func getCurrentUserId() -> String {
        // TODO: Get from auth service
        return UUID().uuidString
    }
}

#Preview {
    NavigationStack {
        ConversationView(conversationId: UUID())
    }
}