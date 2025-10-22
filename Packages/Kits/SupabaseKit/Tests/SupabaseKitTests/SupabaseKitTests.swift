//
//  SupabaseKitTests.swift
//  SupabaseKitTests
//
//  Tests for SupabaseKit module
//

import Testing
@testable import SupabaseKit

@Test("SupabaseKit module version")
func testModuleVersion() {
    #expect(SupabaseKit.version == "1.0.0")
}

@Test("SupabaseClientMock initialization")
func testSupabaseClientMockInit() {
    let mockClient = SupabaseClientMock()
    
    #expect(mockClient.auth is SupabaseAuthMock)
    #expect(mockClient.realtime is SupabaseRealtimeMock)
    #expect(mockClient.storage is SupabaseStorageMock)
    #expect(mockClient.database is SupabaseDatabaseMock)
}

@Test("SupabaseAuthMock session")
func testSupabaseAuthMockSession() async {
    let mockAuth = SupabaseAuthMock()
    let session = await mockAuth.session
    
    #expect(session != nil)
    #expect(session?.accessToken == "mock_access_token")
    #expect(session?.user.id == "mock_user_123")
}

@Test("SupabaseRealtimeMock engagement updates")
func testSupabaseRealtimeMockEngagement() async {
    let mockRealtime = SupabaseRealtimeMock()
    let updates = mockRealtime.subscribeToPostEngagement(postId: "test123")
    
    // Test that the stream is created (even if empty)
    #expect(updates != nil)
}

@Test("SupabaseStorageMock upload")
func testSupabaseStorageMockUpload() async throws {
    let mockStorage = SupabaseStorageMock()
    let testData = Data("test image".utf8)
    
    let url = try await mockStorage.uploadImage(data: testData, path: "test.jpg")
    
    #expect(url.absoluteString.contains("mock.supabase.co"))
    #expect(url.absoluteString.contains("test.jpg"))
}

@Test("SupabaseDatabaseMock posts")
func testSupabaseDatabaseMockPosts() async throws {
    let mockDatabase = SupabaseDatabaseMock()
    
    // Add some mock posts
    let mockPost = Post(
        id: "test123",
        authorId: "author123",
        authorDisplayHandle: "testuser",
        text: "Test post",
        createdAt: Date(),
        authorDisplayName: "Test User"
    )
    mockDatabase.mockPosts = [mockPost]
    
    let posts = try await mockDatabase.fetchPosts(limit: 10, cursor: nil)
    
    #expect(posts.count == 1)
    #expect(posts.first?.id == "test123")
}
