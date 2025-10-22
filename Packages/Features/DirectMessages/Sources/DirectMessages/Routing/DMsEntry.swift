import SwiftUI
import AppFoundation

/// Public entry point for the DirectMessages feature
public struct DMsEntry: View {
    let route: DMsRoute
    
    public init(route: DMsRoute) {
        self.route = route
    }
    
    public var body: some View {
        switch route {
        case .list:
            DirectMessagesView()
        case .conversation(let id):
            ConversationView(conversationId: id)
        }
    }
}

#Preview("Conversation List") {
    DMsEntry(route: .list)
}

#Preview("Individual Conversation") {
    NavigationStack {
        DMsEntry(route: .conversation(id: UUID()))
    }
}