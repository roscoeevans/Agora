import XCTest
@testable import Networking

/// Smoke test to ensure generated OpenAPI code is importable
/// This test helps catch missing imports or configuration issues early
final class OpenAPIGeneratedImportTest: XCTestCase {
    
    func testGeneratedTypesAreImportable() {
        // This test will need to be updated once OpenAPI generation is complete
        // For now, it just verifies our hand-written protocol and implementations exist
        
        // Verify protocol exists
        XCTAssertTrue(AgoraAPIClient.self is any Sendable.Type)
        
        // Verify stub implementation exists
        let stubClient = StubAgoraClient()
        XCTAssertNotNil(stubClient)
        
        // Verify production implementation exists
        let prodClient = OpenAPIAgoraClient(
            baseURL: URL(string: "https://api.agora.app")!,
            authToken: nil
        )
        XCTAssertNotNil(prodClient)
        
        print("✅ All networking types are importable")
    }
    
    func testStubClientReturnsData() async throws {
        let client = StubAgoraClient()
        
        // Test feed endpoint
        let feed = try await client.fetchForYouFeed(cursor: nil, limit: 20)
        XCTAssertGreaterThan(feed.posts.count, 0, "Stub should return mock posts")
        XCTAssertNotNil(feed.nextCursor, "Stub should return pagination cursor")
        
        print("✅ Stub client returns mock data")
    }
    
    func testResponseModelsAreDecodable() throws {
        // Test that our response models can be decoded from JSON
        let postJSON = """
        {
            "id": "test-id",
            "authorId": "author-123",
            "text": "Test post",
            "likeCount": 10,
            "repostCount": 2,
            "replyCount": 3,
            "visibility": "public",
            "createdAt": "2024-01-01T00:00:00Z"
        }
        """
        
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        
        let post = try decoder.decode(Post.self, from: Data(postJSON.utf8))
        XCTAssertEqual(post.id, "test-id")
        XCTAssertEqual(post.text, "Test post")
        XCTAssertEqual(post.visibility, .public)
        
        print("✅ Response models are properly decodable")
    }
}

