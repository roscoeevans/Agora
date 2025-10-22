import SwiftUI
import AppFoundation
import DesignSystem

/// Main conversation list view showing all user conversations
public struct DirectMessagesView: View {
    @State private var viewModel = DirectMessagesViewModel()
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            VStack {
                Text("Direct Messages")
                    .font(.title)
                Text("Conversation list will be implemented here")
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("Messages")
        }
    }
}

#Preview {
    DirectMessagesView()
}