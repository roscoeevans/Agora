import SwiftUI
import AppFoundation
import DesignSystem

/// Main conversation list view showing all user conversations
public struct DirectMessagesView: View {
    @State private var viewModel: DirectMessagesViewModel
    @State private var searchText = ""
    @Environment(\.deps) private var deps
    @Environment(\.navigateToConversation) private var navigateToConversation
    
    public init() {
        self._viewModel = State(initialValue: DirectMessagesViewModel())
    }
    
    public var body: some View {
        Group {
            if viewModel.isLoading && viewModel.conversations.isEmpty {
                // Initial loading state
                loadingView
            } else if viewModel.conversations.isEmpty && !viewModel.isLoading {
                // Empty state
                emptyStateView
            } else {
                // Conversation list
                conversationList
            }
        }
        .navigationTitle("Messages")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.large)
        .toolbar(.hidden, for: .tabBar)
        .searchable(
            text: $searchText,
            placement: .navigationBarDrawer(displayMode: .always),
            prompt: "Search conversations"
        )
        #else
        .searchable(text: $searchText, prompt: "Search conversations")
        #endif
        .onChange(of: searchText) { _, newValue in
            viewModel.searchText = newValue
        }
        .task {
            // Initialize viewModel with dependencies
            viewModel = DirectMessagesViewModel(dependencies: deps)
            
            // Track that conversation list was opened
            viewModel.trackListOpened()
            
            await viewModel.loadConversations()
        }
        .alert("Error", isPresented: .constant(viewModel.errorMessage != nil)) {
            Button("OK") {
                viewModel.errorMessage = nil
            }
            Button("Retry") {
                Task {
                    await viewModel.refresh()
                }
            }
        } message: {
            if let errorMessage = viewModel.errorMessage {
                Text(errorMessage)
            }
        }
    }
    
    // MARK: - Subviews
    
    private var conversationList: some View {
        List {
            ForEach(Array(viewModel.filteredConversations.enumerated()), id: \.element.id) { index, conversation in
                Button {
                    navigateToConversation?.action(conversation.id)
                } label: {
                    ConversationRow(conversation: conversation)
                }
                .buttonStyle(.plain)
                .listRowSeparator(index == 0 ? .hidden : .visible, edges: .top)
            }
        }
        .refreshable {
            await viewModel.refresh()
        }
        .listStyle(.plain)
    }
    
    private var loadingView: some View {
        VStack(spacing: 16) {
            // Skeleton loading rows
            ForEach(0..<6, id: \.self) { _ in
                ConversationRowSkeleton()
            }
            Spacer()
        }
        .padding()
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 16) {
            Spacer()
            
            Image(systemName: "message.circle")
                .font(.system(size: 64))
                .foregroundStyle(.secondary)
            
            Text("No Conversations")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Start a conversation to see it here")
                .font(.body)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
            
            Spacer()
        }
        .padding()
    }
}

/// Skeleton loading view for conversation rows
private struct ConversationRowSkeleton: View {
    @State private var isAnimating = false
    
    var body: some View {
        HStack(spacing: 12) {
            // Avatar skeleton
            Circle()
                .fill(.secondary.opacity(0.2))
                .frame(width: 50, height: 50)
                .shimmer(isAnimating: isAnimating)
            
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    // Title skeleton
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.secondary.opacity(0.2))
                        .frame(width: 120, height: 16)
                        .shimmer(isAnimating: isAnimating)
                    
                    Spacer()
                    
                    // Timestamp skeleton
                    RoundedRectangle(cornerRadius: 4)
                        .fill(.secondary.opacity(0.2))
                        .frame(width: 60, height: 12)
                        .shimmer(isAnimating: isAnimating)
                }
                
                // Message preview skeleton
                RoundedRectangle(cornerRadius: 4)
                    .fill(.secondary.opacity(0.2))
                    .frame(width: 200, height: 14)
                    .shimmer(isAnimating: isAnimating)
            }
        }
        .padding(.vertical, 4)
        .onAppear {
            withAnimation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true)) {
                isAnimating = true
            }
        }
    }
}

/// Shimmer effect modifier for skeleton loading
private struct ShimmerModifier: ViewModifier {
    let isAnimating: Bool
    
    func body(content: Content) -> some View {
        content
            .opacity(isAnimating ? 0.6 : 1.0)
    }
}

private extension View {
    func shimmer(isAnimating: Bool) -> some View {
        modifier(ShimmerModifier(isAnimating: isAnimating))
    }
}

#Preview {
    DirectMessagesView()
}