import SwiftUI
import AppFoundation

/// ViewModel for individual conversation view
@Observable
public class ConversationViewModel {
    let conversationId: UUID
    
    // Placeholder for message state
    var messages: [String] = []
    
    public init(conversationId: UUID) {
        self.conversationId = conversationId
        // Initialize with dependencies when available
    }
    
    func loadMessages() async {
        // Implement message loading
    }
    
    func sendMessage(_ text: String) async {
        // Implement message sending
    }
}