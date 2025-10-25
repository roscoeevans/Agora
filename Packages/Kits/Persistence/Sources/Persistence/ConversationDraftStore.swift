import Foundation

/// Represents a conversation draft
public struct ConversationDraft: Codable {
    public let conversationId: UUID
    public var text: String
    public var updatedAt: Date
    
    public init(conversationId: UUID, text: String = "") {
        self.conversationId = conversationId
        self.text = text
        self.updatedAt = Date()
    }
    
    public mutating func updateText(_ newText: String) {
        self.text = newText
        self.updatedAt = Date()
    }
}

/// Manages conversation draft persistence
@MainActor
public final class ConversationDraftStore {
    public static let shared = ConversationDraftStore()
    
    private let userDefaults = UserDefaults.standard
    private let draftsKey = "agora.conversation.drafts"
    
    private init() {}
    
    /// Saves a draft for a specific conversation
    public func saveDraft(conversationId: UUID, text: String) async throws {
        var drafts = try await getAllDrafts()
        
        if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            // Remove draft if text is empty
            drafts.removeValue(forKey: conversationId)
        } else {
            // Update or create draft
            var draft = drafts[conversationId] ?? ConversationDraft(conversationId: conversationId)
            draft.updateText(text)
            drafts[conversationId] = draft
        }
        
        let data = try JSONEncoder().encode(drafts)
        userDefaults.set(data, forKey: draftsKey)
    }
    
    /// Retrieves a draft for a specific conversation
    public func getDraft(conversationId: UUID) async throws -> ConversationDraft? {
        let drafts = try await getAllDrafts()
        return drafts[conversationId]
    }
    
    /// Retrieves all drafts
    private func getAllDrafts() async throws -> [UUID: ConversationDraft] {
        guard let data = userDefaults.data(forKey: draftsKey) else {
            return [:]
        }
        
        return try JSONDecoder().decode([UUID: ConversationDraft].self, from: data)
    }
    
    /// Deletes a draft for a specific conversation
    public func deleteDraft(conversationId: UUID) async throws {
        var drafts = try await getAllDrafts()
        drafts.removeValue(forKey: conversationId)
        
        let data = try JSONEncoder().encode(drafts)
        userDefaults.set(data, forKey: draftsKey)
    }
    
    /// Deletes all drafts
    public func deleteAllDrafts() async throws {
        userDefaults.removeObject(forKey: draftsKey)
    }
}

/// Errors that can occur in ConversationDraftStore operations
public enum ConversationDraftStoreError: LocalizedError {
    case draftNotFound
    case encodingError
    case decodingError
    
    public var errorDescription: String? {
        switch self {
        case .draftNotFound:
            return "Conversation draft not found"
        case .encodingError:
            return "Failed to encode draft data"
        case .decodingError:
            return "Failed to decode draft data"
        }
    }
}