import Testing
@testable import AuthFeature
import Networking
import AppFoundation

@Test("Handle format validation - valid handle")
func testHandleFormatValidation_Valid() async {
    let mockClient = StubAgoraClient()
    let validator = HandleValidator(apiClient: mockClient)
    
    let result = await validator.validateFormat("johndoe")
    #expect(result == .valid)
}

@Test("Handle format validation - too short")
func testHandleFormatValidation_TooShort() async {
    let mockClient = StubAgoraClient()
    let validator = HandleValidator(apiClient: mockClient)
    
    let result = await validator.validateFormat("ab")
    #expect(result == .tooShort)
}

@Test("Handle format validation - too long")
func testHandleFormatValidation_TooLong() async {
    let mockClient = StubAgoraClient()
    let validator = HandleValidator(apiClient: mockClient)
    
    let result = await validator.validateFormat("verylonghandlename123")
    #expect(result == .tooLong)
}

@Test("Handle format validation - invalid characters")
func testHandleFormatValidation_InvalidCharacters() async {
    let mockClient = StubAgoraClient()
    let validator = HandleValidator(apiClient: mockClient)
    
    let result = await validator.validateFormat("john@doe")
    #expect(result == .invalidCharacters)
}

@Test("Handle format validation - starts with underscore")
func testHandleFormatValidation_StartsWithUnderscore() async {
    let mockClient = StubAgoraClient()
    let validator = HandleValidator(apiClient: mockClient)
    
    let result = await validator.validateFormat("_johndoe")
    #expect(result == .startsWithUnderscore)
}

@Test("Handle format validation - all numbers")
func testHandleFormatValidation_AllNumbers() async {
    let mockClient = StubAgoraClient()
    let validator = HandleValidator(apiClient: mockClient)
    
    let result = await validator.validateFormat("12345")
    #expect(result == .allNumbers)
}

@Test("Handle format validation - reserved handle")
func testHandleFormatValidation_Reserved() async {
    let mockClient = StubAgoraClient()
    let validator = HandleValidator(apiClient: mockClient)
    
    let result = await validator.validateFormat("admin")
    #expect(result == .reserved)
}

@Test("Handle availability check - available")
func testHandleAvailability_Available() async throws {
    let mockClient = StubAgoraClient()
    let validator = HandleValidator(apiClient: mockClient)
    
    let availability = try await validator.checkAvailability("uniquehandle")
    #expect(availability.available == true)
}

@Test("Handle availability check - unavailable")
func testHandleAvailability_Unavailable() async throws {
    let mockClient = StubAgoraClient()
    let validator = HandleValidator(apiClient: mockClient)
    
    let availability = try await validator.checkAvailability("admin")
    #expect(availability.available == false)
    #expect(availability.suggestions.isEmpty == false)
}

@Test("Auth state - initial state is initializing")
func testAuthStateInitial() {
    let state = AuthState.initializing
    #expect(state.isAuthenticated == false)
    #expect(state.hasProfile == false)
}

@Test("Auth state - authenticated without profile")
func testAuthStateAuthenticatedNoProfile() {
    let state = AuthState.authenticatedNoProfile(userId: "test-user")
    #expect(state.isAuthenticated == true)
    #expect(state.hasProfile == false)
}

@Test("Auth state - fully authenticated")
func testAuthStateAuthenticated() {
    let profile = UserProfile(
        id: "test-id",
        handle: "testuser",
        displayHandle: "TestUser",
        displayName: "Test User",
        createdAt: Date()
    )
    let state = AuthState.authenticated(profile: profile)
    #expect(state.isAuthenticated == true)
    #expect(state.hasProfile == true)
    #expect(state.currentUser?.handle == "testuser")
}

@Test("UserProfile - initialization from API user")
func testUserProfileFromAPIUser() {
    let apiUser = Components.Schemas.User(
        id: "test-id",
        handle: "testuser",
        displayHandle: "TestUser",
        displayName: "Test User",
        createdAt: ISO8601DateFormatter().string(from: Date())
    )
    
    let profile = UserProfile(from: apiUser)
    #expect(profile.id == "test-id")
    #expect(profile.handle == "testuser")
    #expect(profile.displayHandle == "TestUser")
    #expect(profile.displayName == "Test User")
}

