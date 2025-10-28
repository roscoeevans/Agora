// SearchKitTests: Unit tests for SearchKit module

import Testing
@testable import SearchKit

@Suite("SearchKit Tests")
struct SearchKitTests {
    
    @Test("SearchUser model encodes and decodes correctly")
    func searchUserCodable() throws {
        let user = SearchUser.preview
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        encoder.dateEncodingStrategy = .iso8601
        
        let data = try encoder.encode(user)
        let decoded = try decoder.decode(SearchUser.self, from: data)
        
        #expect(decoded.userId == user.userId)
        #expect(decoded.handle == user.handle)
        #expect(decoded.displayHandle == user.displayHandle)
        #expect(decoded.displayName == user.displayName)
    }
    
    @Test("Mock service returns filtered results")
    func mockServiceSearch() async throws {
        let service = UserSearchServiceMock.instant
        
        let results = try await service.search(q: "rocky", limit: 10, after: nil)
        
        #expect(!results.isEmpty)
        #expect(results.allSatisfy { user in
            user.handle.lowercased().contains("rocky") ||
            user.displayName.lowercased().contains("rocky")
        })
    }
    
    @Test("Mock service returns suggested creators")
    func mockServiceSuggestedCreators() async throws {
        let service = UserSearchServiceMock.instant
        
        let results = try await service.suggestedCreators(limit: 5)
        
        #expect(!results.isEmpty)
        #expect(results.count <= 5)
        
        // Verify sorted by followers descending
        for i in 0..<(results.count - 1) {
            #expect(results[i].followersCount >= results[i + 1].followersCount)
        }
    }
    
    @Test("Mock service handles exact handle lookup")
    func mockServiceLookupByHandle() async throws {
        let service = UserSearchServiceMock.instant
        
        let result = try await service.lookupByHandle("@rocky.evans")
        
        #expect(result != nil)
        #expect(result?.handle == "rocky.evans")
    }
    
    @Test("Mock service handles empty results")
    func mockServiceEmptyResults() async throws {
        let service = UserSearchServiceMock.empty
        
        let results = try await service.search(q: "nonexistent", limit: 10, after: nil)
        
        #expect(results.isEmpty)
    }
    
    @Test("Mock service handles errors")
    func mockServiceErrors() async {
        let service = UserSearchServiceMock.failing
        
        do {
            _ = try await service.search(q: "test", limit: 10, after: nil)
            Issue.record("Expected error to be thrown")
        } catch {
            #expect(error is UserSearchError)
        }
    }
    
    @Test("Mock service respects pagination")
    func mockServicePagination() async throws {
        let service = UserSearchServiceMock.instant
        
        // Get first page
        let page1 = try await service.search(q: "", limit: 2, after: nil)
        #expect(page1.count <= 2)
        
        // Get second page
        if !page1.isEmpty {
            let cursor = page1.last?.handle
            let page2 = try await service.search(q: "", limit: 2, after: cursor)
            
            // Pages should not overlap
            let page1Handles = Set(page1.map(\.handle))
            let page2Handles = Set(page2.map(\.handle))
            #expect(page1Handles.isDisjoint(with: page2Handles))
        }
    }
}

