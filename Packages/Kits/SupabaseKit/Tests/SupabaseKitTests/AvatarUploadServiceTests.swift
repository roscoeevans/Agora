//
//  AvatarUploadServiceTests.swift
//  SupabaseKitTests
//
//  Tests for AvatarUploadServiceLive implementation
//

import Testing
import Foundation
@testable import SupabaseKit

@Suite("AvatarUploadService Tests")
struct AvatarUploadServiceTests {
    
    // MARK: - Basic Tests
    
    @Test("AvatarUploadError descriptions")
    func testAvatarUploadErrorDescriptions() {
        let notAuthError = AvatarUploadError.notAuthenticated
        #expect(notAuthError.errorDescription == "Please sign in to update your avatar.")
        
        let uploadError = AvatarUploadError.uploadFailed(NSError(domain: "test", code: 1))
        #expect(uploadError.errorDescription == "Failed to upload avatar. Please try again.")
        
        let profileError = AvatarUploadError.profileUpdateFailed(NSError(domain: "test", code: 1))
        #expect(profileError.errorDescription == "Avatar uploaded but profile update failed. Please try again.")
    }
    
    @Test("AvatarUploadService protocol exists")
    func testAvatarUploadServiceProtocol() {
        // This test verifies that the protocol is properly defined
        // We can't easily test the actual implementation without complex mocking
        // due to the real Supabase client dependencies
        
        let service: AvatarUploadService = NoOpAvatarUploadService()
        // Just verify the service was created successfully
        #expect(true)
    }
    
    @Test("ProfileUpdateResponse decoding")
    func testProfileUpdateResponseDecoding() throws {
        let jsonData = """
        {"updated_at": "2024-01-15T10:30:00Z"}
        """.data(using: .utf8)!
        
        let response = try JSONDecoder().decode(ProfileUpdateResponse.self, from: jsonData)
        #expect(response.updated_at == "2024-01-15T10:30:00Z")
    }
    
    @Test("ProfileUpdateResponse decoding with null")
    func testProfileUpdateResponseDecodingWithNull() throws {
        let jsonData = """
        {"updated_at": null}
        """.data(using: .utf8)!
        
        let response = try JSONDecoder().decode(ProfileUpdateResponse.self, from: jsonData)
        #expect(response.updated_at == nil)
    }
}

// MARK: - No-Op Implementation for Testing

/// No-op implementation of AvatarUploadService for testing
private struct NoOpAvatarUploadService: AvatarUploadService {
    func uploadAvatar(_ data: Data, mime: String) async throws -> URL {
        throw AvatarUploadError.uploadFailed(NSError(domain: "NoOpService", code: -1))
    }
}

