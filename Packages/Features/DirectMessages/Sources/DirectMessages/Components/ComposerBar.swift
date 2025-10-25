import SwiftUI
import PhotosUI
import DesignSystem
import Media
import Persistence

// Import ServiceProtocols directly to get MediaPick without ambiguity
import struct AppFoundation.MediaPick
import protocol AppFoundation.MessagingMediaProtocol
import protocol AppFoundation.MessagingRealtimeProtocol
import struct AppFoundation.Dependencies
import struct AppFoundation.Attachment

struct ComposerBar: View {
    let conversationId: UUID
    @Binding var text: String
    @Binding var attachments: [Attachment]
    @FocusState private var isTextFieldFocused: Bool
    
    let onSend: () -> Void
    let onAttachmentTap: () -> Void
    
    @State private var textHeight: CGFloat = 38
    @State private var isSending: Bool = false
    @State private var showingPhotoPicker = false
    @State private var selectedPhotos: [PhotosPickerItem] = []
    @State private var uploadProgress: [UUID: Double] = [:]
    @State private var uploadErrors: [UUID: String] = [:]
    @State private var draftSaveTask: Task<Void, Never>?
    @State private var typingDetector: SimpleTypingDetector?
    @State private var hapticTrigger = false
    
    @Environment(\.deps) private var deps
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    private var canSend: Bool {
        !isSending && (!text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !attachments.isEmpty)
    }
    
    // Dynamic height calculations based on Dynamic Type size
    private var dynamicMinHeight: CGFloat {
        switch dynamicTypeSize {
        case .xSmall, .small: return 34
        case .medium, .large: return 38
        case .xLarge, .xxLarge: return 42
        case .xxxLarge: return 46
        case .accessibility1: return 50
        case .accessibility2: return 54
        case .accessibility3: return 58
        case .accessibility4: return 62
        case .accessibility5: return 66
        @unknown default: return 38
        }
    }
    
    private var dynamicMaxHeight: CGFloat {
        switch dynamicTypeSize {
        case .xSmall, .small: return 100
        case .medium, .large: return 120
        case .xLarge, .xxLarge: return 140
        case .xxxLarge: return 160
        case .accessibility1: return 180
        case .accessibility2: return 200
        case .accessibility3: return 220
        case .accessibility4: return 240
        case .accessibility5: return 260
        @unknown default: return 120
        }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Attachment previews
            if !attachments.isEmpty {
                attachmentPreviewsView
            }
            
            // Main composer bar
            HStack(alignment: .bottom, spacing: 8) {
                // Attachment button
                Button(action: { showingPhotoPicker = true }) {
                    Image(systemName: "plus")
                        .font(.title2)
                        .foregroundStyle(.secondary)
                        .frame(width: 32, height: 32)
                        .background(.regularMaterial, in: Circle())
                }
                .frame(minWidth: 44, minHeight: 44) // Ensure minimum touch target
                .accessibilityLabel("Add attachment")
                .photosPicker(
                    isPresented: $showingPhotoPicker,
                    selection: $selectedPhotos,
                    maxSelectionCount: 10,
                    matching: .any(of: [.images, .videos])
                )
                
                // Text input area
                textInputView
                
                // Send button
                Button(action: handleSend) {
                    Group {
                        if isSending {
                            ProgressView()
                                .scaleEffect(0.8)
                                .tint(.white)
                        } else {
                            Image(systemName: "arrow.up")
                                .font(.title3.weight(.semibold))
                        }
                    }
                    .foregroundStyle(.white)
                    .frame(width: 32, height: 32)
                    .background(canSend ? .blue : .secondary, in: Circle())
                }
                .frame(minWidth: 44, minHeight: 44) // Ensure minimum touch target
                .disabled(!canSend)
                .accessibilityLabel(isSending ? "Sending message" : "Send message")
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.regularMaterial)
        }
        .onChange(of: selectedPhotos) { _, newPhotos in
            Task {
                await processSelectedPhotos(newPhotos)
            }
        }
        .onChange(of: text) { _, newText in
            debouncedSaveDraft(newText)
            typingDetector?.textChanged(newText)
        }
        .sensoryFeedback(.selection, trigger: hapticTrigger)
        .onAppear {
            loadDraft()
            setupTypingDetection()
        }
    }
    
    private var textInputView: some View {
        ZStack(alignment: .topLeading) {
            // Background
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.regularMaterial)
                .frame(minHeight: 38, maxHeight: 120)
            
            // Text editor
            TextEditor(text: $text)
                .focused($isTextFieldFocused)
                .scrollContentBackground(.hidden)
                .font(TypographyScale.body)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .frame(minHeight: dynamicMinHeight, maxHeight: dynamicMaxHeight)
                .onSubmit {
                    if canSend {
                        handleSend()
                    }
                }
                .submitLabel(.send)
                .background(
                    GeometryReader { geometry in
                        Color.clear
                            .onAppear {
                                updateTextHeight(geometry.size.height)
                            }
                            .onChange(of: geometry.size.height) { _, newHeight in
                                updateTextHeight(newHeight)
                            }
                    }
                )
            
            // Placeholder
            if text.isEmpty {
                Text("Message")
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 18)
                    .allowsHitTesting(false)
            }
        }
    }
    
    private var attachmentPreviewsView: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(attachments) { attachment in
                    AttachmentPreviewChip(
                        attachment: attachment,
                        onRemove: { removeAttachment(attachment) },
                        uploadProgress: uploadProgress[attachment.id],
                        uploadError: uploadErrors[attachment.id]
                    )
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
        }
        .background(.regularMaterial)
    }
    
    private func handleSend() {
        guard canSend else { return }
        
        // Trigger haptic feedback using SwiftUI native sensoryFeedback
        hapticTrigger.toggle()
        
        // Set sending state
        isSending = true
        
        // Notify typing detector that message was sent
        typingDetector?.messageSent()
        
        // Call the send handler
        onSend()
        
        // Clear text and attachments after sending
        text = ""
        attachments.removeAll()
        
        // Clear draft after sending
        Task {
            try? await ConversationDraftStore.shared.deleteDraft(conversationId: conversationId)
        }
        
        // Reset sending state after a brief delay
        Task {
            try? await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds
            await MainActor.run {
                isSending = false
            }
        }
        
        // Maintain focus on text field
        isTextFieldFocused = true
    }
    
    private func removeAttachment(_ attachment: Attachment) {
        attachments.removeAll { $0.id == attachment.id }
    }
    
    private func updateTextHeight(_ height: CGFloat) {
        let newHeight = max(38, min(120, height))
        if abs(textHeight - newHeight) > 1 {
            textHeight = newHeight
        }
    }
    
    private func processSelectedPhotos(_ photos: [PhotosPickerItem]) async {
        for photo in photos {
            do {
                // Create a temporary attachment ID for progress tracking
                let tempId = UUID()
                
                await MainActor.run {
                    uploadProgress[tempId] = 0.0
                }
                
                // Convert PhotosPickerItem to MediaPick
                let mediaPick = try await convertToMediaPick(photo)
                
                // Update progress
                await MainActor.run {
                    uploadProgress[tempId] = 0.5
                }
                
                // Prepare attachment using messaging media service
                guard let messagingMedia = deps.messagingMedia else {
                    throw MediaError.invalidData
                }
                let attachment = try await messagingMedia.prepareAttachment(mediaPick)
                
                await MainActor.run {
                    // Add to attachments list
                    attachments.append(attachment)
                    
                    // Clean up progress tracking
                    uploadProgress.removeValue(forKey: tempId)
                    uploadErrors.removeValue(forKey: tempId)
                }
                
            } catch {
                await MainActor.run {
                    uploadErrors[UUID()] = error.localizedDescription
                    uploadProgress.removeValue(forKey: UUID())
                }
            }
        }
        
        // Clear selected photos
        await MainActor.run {
            selectedPhotos.removeAll()
        }
    }
    
    private func convertToMediaPick(_ item: PhotosPickerItem) async throws -> MediaPick {
        // This is a simplified conversion - in a real implementation,
        // you'd need to properly handle the PhotosPickerItem data
        guard let data = try await item.loadTransferable(type: Data.self) else {
            throw MediaError.invalidData
        }
        
        let filename = item.itemIdentifier ?? "attachment"
        let mimeType = item.supportedContentTypes.first?.preferredMIMEType ?? "application/octet-stream"
        
        return MediaPick(
            data: data,
            filename: filename,
            mimeType: mimeType
        )
    }
    
    private func loadDraft() {
        Task {
            do {
                if let draft = try await ConversationDraftStore.shared.getDraft(conversationId: conversationId) {
                    await MainActor.run {
                        text = draft.text
                    }
                }
            } catch {
                // Handle error silently for now
                print("Failed to load draft: \(error)")
            }
        }
    }
    
    private func debouncedSaveDraft(_ text: String) {
        // Cancel previous save task
        draftSaveTask?.cancel()
        
        // Create new debounced save task
        draftSaveTask = Task {
            // Wait for 500ms debounce
            try? await Task.sleep(nanoseconds: 500_000_000)
            
            // Save draft
            do {
                try await ConversationDraftStore.shared.saveDraft(
                    conversationId: conversationId,
                    text: text
                )
            } catch {
                // Handle error silently for now
                print("Failed to save draft: \(error)")
            }
        }
    }
    
    private func setupTypingDetection() {
        guard let messagingRealtime = deps.messagingRealtime else {
            return
        }
        typingDetector = SimpleTypingDetector(
            conversationId: conversationId,
            messagingRealtime: messagingRealtime
        )
    }
}
struct AttachmentPreviewChip: View {
    let attachment: Attachment
    let onRemove: () -> Void
    let uploadProgress: Double?
    let uploadError: String?
    
    var body: some View {
        HStack(spacing: 8) {
            // Thumbnail or icon with upload progress overlay
            ZStack {
                Group {
                    switch attachment.type {
                    case .image:
                        AsyncImage(url: attachment.thumbnailUrl ?? attachment.url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Rectangle()
                                .fill(.secondary.opacity(0.3))
                        }
                        .frame(width: 40, height: 40)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        
                    case .video:
                        ZStack {
                            AsyncImage(url: attachment.thumbnailUrl ?? attachment.url) { image in
                                image
                                    .resizable()
                                    .aspectRatio(contentMode: .fill)
                            } placeholder: {
                                Rectangle()
                                    .fill(.secondary.opacity(0.3))
                            }
                            
                            Image(systemName: "play.fill")
                                .foregroundStyle(.white)
                                .font(.caption)
                        }
                        .frame(width: 40, height: 40)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        
                    case .audio:
                        Image(systemName: "waveform")
                            .foregroundStyle(.secondary)
                            .frame(width: 40, height: 40)
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                            
                    case .document:
                        Image(systemName: "doc.fill")
                            .foregroundStyle(.secondary)
                            .frame(width: 40, height: 40)
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                    }
                }
                
                // Upload progress overlay
                if let progress = uploadProgress {
                    ZStack {
                        Circle()
                            .fill(.black.opacity(0.6))
                            .frame(width: 24, height: 24)
                        
                        ProgressView(value: progress)
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.6)
                    }
                }
                
                // Error overlay
                if let error = uploadError {
                    ZStack {
                        Circle()
                            .fill(.red.opacity(0.8))
                            .frame(width: 24, height: 24)
                        
                        Image(systemName: "exclamationmark")
                            .foregroundStyle(.white)
                            .font(.caption2)
                    }
                }
            }
            
            // Remove button
            Button(action: onRemove) {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.secondary)
                    .font(.caption)
            }
            .frame(minWidth: 44, minHeight: 44) // Ensure minimum touch target
            .accessibilityLabel("Remove attachment")
        }
        .padding(8)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    @State var text = ""
    @State var attachments: [Attachment] = []
    
    return VStack {
        Spacer()
        ComposerBar(
            conversationId: UUID(),
            text: $text,
            attachments: $attachments,
            onSend: { print("Send tapped") },
            onAttachmentTap: { print("Attachment tapped") }
        )
    }
    .background(.gray.opacity(0.1))
}