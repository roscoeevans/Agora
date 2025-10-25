import SwiftUI
import AppFoundation
import DesignSystem

/// Individual conversation view with message history and composer
public struct ConversationView: View {
    let conversationId: UUID
    @State private var viewModel: ConversationViewModel
    
    public init(conversationId: UUID) {
        self.conversationId = conversationId
        self._viewModel = State(initialValue: ConversationViewModel(conversationId: conversationId))
    }
    
    public var body: some View {
        let _ = Self._printChanges() // Help compiler with type checking
        VStack {
            Text("Conversation: \(conversationId.uuidString)")
                .font(.title2)
            Text("Chat interface will be implemented here")
                .foregroundStyle(.secondary)
        }
        .navigationTitle("Chat")
        #if os(iOS)
        .navigationBarTitleDisplayMode(.inline)
        #endif
    }
}

#Preview {
    NavigationStack {
        ConversationView(conversationId: UUID())
    }
}