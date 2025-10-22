import SwiftUI
import DesignSystem

/// Message input area with text field and attachment options
public struct ComposerBar: View {
    @Binding var text: String
    let onSend: () -> Void
    
    public init(text: Binding<String>, onSend: @escaping () -> Void) {
        self._text = text
        self.onSend = onSend
    }
    
    public var body: some View {
        HStack(spacing: 8) {
            // Attachment button placeholder
            Button(action: {}) {
                Image(systemName: "plus.circle.fill")
                    .font(.title2)
                    .foregroundStyle(.secondary)
            }
            
            // Text input
            TextField("Message", text: $text, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(1...5)
            
            // Send button
            Button(action: onSend) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.title2)
                    .foregroundStyle(text.isEmpty ? Color.secondary : Color.blue)
            }
            .disabled(text.isEmpty)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.regularMaterial)
    }
}

#Preview {
    @Previewable @State var text = ""
    
    return ComposerBar(text: $text) {
        print("Send tapped")
    }
}