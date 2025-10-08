import XCTest
@testable import Persistence

final class PersistenceTests: XCTestCase {
    
    func testPersistenceModuleExists() {
        let persistence = Persistence.shared
        XCTAssertNotNil(persistence)
    }
    
    func testSwiftDataStoreInitialization() {
        let store = SwiftDataStore.shared
        XCTAssertNotNil(store)
    }
    
    func testCacheManagerInitialization() {
        let cacheManager = CacheManager.shared
        XCTAssertNotNil(cacheManager)
    }
    
    func testDraftStoreInitialization() {
        let draftStore = DraftStore.shared
        XCTAssertNotNil(draftStore)
    }
    
    func testComposeDraftCreation() {
        let draft = ComposeDraft(text: "Test draft", mediaAttachments: ["test.jpg"])
        
        XCTAssertEqual(draft.text, "Test draft")
        XCTAssertEqual(draft.mediaAttachments, ["test.jpg"])
        XCTAssertNotNil(draft.id)
        XCTAssertNotNil(draft.createdAt)
        XCTAssertNotNil(draft.updatedAt)
    }
    
    func testComposeDraftTextUpdate() {
        var draft = ComposeDraft(text: "Original text")
        let originalUpdatedAt = draft.updatedAt
        
        // Small delay to ensure updatedAt changes
        Thread.sleep(forTimeInterval: 0.01)
        
        draft.updateText("Updated text")
        
        XCTAssertEqual(draft.text, "Updated text")
        XCTAssertGreaterThan(draft.updatedAt, originalUpdatedAt)
    }
    
    func testMemoryCache() {
        let cacheManager = CacheManager.shared
        let testObject = NSString(string: "test value")
        
        cacheManager.setMemoryCache(testObject, forKey: "test_key")
        let retrievedObject = cacheManager.getMemoryCache(forKey: "test_key", type: NSString.self)
        
        XCTAssertEqual(retrievedObject, testObject)
        
        cacheManager.removeMemoryCache(forKey: "test_key")
        let removedObject = cacheManager.getMemoryCache(forKey: "test_key", type: NSString.self)
        
        XCTAssertNil(removedObject)
    }
    
    func testDraftStoreCreateAndRetrieve() async throws {
        let draftStore = DraftStore.shared
        
        // Clean up any existing drafts
        try await draftStore.deleteAllDrafts()
        
        let draft = try await draftStore.createDraft(text: "Test draft content")
        let retrievedDraft = try await draftStore.getDraft(id: draft.id)
        
        XCTAssertNotNil(retrievedDraft)
        XCTAssertEqual(retrievedDraft?.text, "Test draft content")
        XCTAssertEqual(retrievedDraft?.id, draft.id)
        
        // Clean up
        try await draftStore.deleteDraft(id: draft.id)
    }
}