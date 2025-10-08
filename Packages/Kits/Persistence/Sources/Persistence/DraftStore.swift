import Foundation

/// Represents a compose draft
public struct ComposeDraft: Codable, Identifiable {
    public let id: UUID
    public var text: String
    public var mediaAttachments: [String] // URLs or local file paths
    public var createdAt: Date
    public var updatedAt: Date
    
    public init(text: String = "", mediaAttachments: [String] = []) {
        self.id = UUID()
        self.text = text
        self.mediaAttachments = mediaAttachments
        self.createdAt = Date()
        self.updatedAt = Date()
    }
    
    public mutating func updateText(_ newText: String) {
        self.text = newText
        self.updatedAt = Date()
    }
    
    public mutating func addMediaAttachment(_ attachment: String) {
        self.mediaAttachments.append(attachment)
        self.updatedAt = Date()
    }
    
    public mutating func removeMediaAttachment(_ attachment: String) {
        self.mediaAttachments.removeAll { $0 == attachment }
        self.updatedAt = Date()
    }
}

/// Manages compose draft persistence
@MainActor
public final class DraftStore {
    public static let shared = DraftStore()
    
    private let userDefaults = UserDefaults.standard
    private let draftsKey = "agora.compose.drafts"
    
    private init() {}
    
    /// Saves a draft
    public func saveDraft(_ draft: ComposeDraft) async throws {
        var drafts = try await getAllDrafts()
        
        // Update existing draft or add new one
        if let index = drafts.firstIndex(where: { $0.id == draft.id }) {
            drafts[index] = draft
        } else {
            drafts.append(draft)
        }
        
        // Keep only the most recent 10 drafts
        drafts = Array(drafts.sorted { $0.updatedAt > $1.updatedAt }.prefix(10))
        
        let data = try JSONEncoder().encode(drafts)
        userDefaults.set(data, forKey: draftsKey)
    }
    
    /// Retrieves a specific draft by ID
    public func getDraft(id: UUID) async throws -> ComposeDraft? {
        let drafts = try await getAllDrafts()
        return drafts.first { $0.id == id }
    }
    
    /// Retrieves all drafts, sorted by most recently updated
    public func getAllDrafts() async throws -> [ComposeDraft] {
        guard let data = userDefaults.data(forKey: draftsKey) else {
            return []
        }
        
        let drafts = try JSONDecoder().decode([ComposeDraft].self, from: data)
        return drafts.sorted { $0.updatedAt > $1.updatedAt }
    }
    
    /// Deletes a specific draft
    public func deleteDraft(id: UUID) async throws {
        var drafts = try await getAllDrafts()
        drafts.removeAll { $0.id == id }
        
        let data = try JSONEncoder().encode(drafts)
        userDefaults.set(data, forKey: draftsKey)
    }
    
    /// Deletes all drafts
    public func deleteAllDrafts() async throws {
        userDefaults.removeObject(forKey: draftsKey)
    }
    
    /// Gets the most recent draft
    public func getMostRecentDraft() async throws -> ComposeDraft? {
        let drafts = try await getAllDrafts()
        return drafts.first
    }
    
    /// Creates a new draft with the given text
    public func createDraft(text: String = "") async throws -> ComposeDraft {
        let draft = ComposeDraft(text: text)
        try await saveDraft(draft)
        return draft
    }
    
    /// Updates an existing draft's text
    public func updateDraftText(id: UUID, text: String) async throws {
        guard var draft = try await getDraft(id: id) else {
            throw DraftStoreError.draftNotFound
        }
        
        draft.updateText(text)
        try await saveDraft(draft)
    }
}

/// Errors that can occur in DraftStore operations
public enum DraftStoreError: LocalizedError {
    case draftNotFound
    case encodingError
    case decodingError
    
    public var errorDescription: String? {
        switch self {
        case .draftNotFound:
            return "Draft not found"
        case .encodingError:
            return "Failed to encode draft data"
        case .decodingError:
            return "Failed to decode draft data"
        }
    }
}