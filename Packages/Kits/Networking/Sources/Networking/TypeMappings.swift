import Foundation
import AppFoundation

// MARK: - Type Mappings between Components.Schemas and AppFoundation

/// This file provides mapping functions to convert between OpenAPI-generated types
/// (Components.Schemas.*) and AppFoundation protocol types.
///
/// Why these mappings exist:
/// - Protocol defines types in AppFoundation to avoid circular dependencies
/// - OpenAPI generates its own types from the API spec
/// - We need to convert between them at the Networking Kit boundary

// MARK: - User Mapping

extension Components.Schemas.User {
    /// Convert generated User to AppFoundation User
    func toAppFoundation() -> User {
        User(
            id: self.id,
            handle: self.handle,
            displayHandle: self.displayHandle,
            displayName: self.displayName,
            bio: self.bio,
            avatarUrl: self.avatarUrl,
            createdAt: self.createdAt
        )
    }
}

extension User {
    /// Convert AppFoundation User to generated User
    func toComponentsSchemas() -> Components.Schemas.User {
        Components.Schemas.User(
            id: self.id,
            handle: self.handle,
            displayHandle: self.displayHandle,
            displayName: self.displayName,
            bio: self.bio,
            avatarUrl: self.avatarUrl,
            createdAt: self.createdAt
        )
    }
}

// MARK: - CheckHandleResponse Mapping

extension Components.Schemas.CheckHandleResponse {
    /// Convert generated CheckHandleResponse to AppFoundation CheckHandleResponse
    func toAppFoundation() -> CheckHandleResponse {
        CheckHandleResponse(
            available: self.available,
            suggestions: self.suggestions
        )
    }
}

extension CheckHandleResponse {
    /// Convert AppFoundation CheckHandleResponse to generated CheckHandleResponse
    func toComponentsSchemas() -> Components.Schemas.CheckHandleResponse {
        Components.Schemas.CheckHandleResponse(
            available: self.available,
            suggestions: self.suggestions
        )
    }
}

// MARK: - CreateProfileRequest Mapping

extension Components.Schemas.CreateProfileRequest {
    /// Convert generated CreateProfileRequest to AppFoundation CreateProfileRequest
    func toAppFoundation() -> CreateProfileRequest {
        CreateProfileRequest(
            handle: self.handle,
            displayHandle: self.displayHandle,
            displayName: self.displayName,
            avatarUrl: self.avatarUrl
        )
    }
}

extension CreateProfileRequest {
    /// Convert AppFoundation CreateProfileRequest to generated CreateProfileRequest
    func toComponentsSchemas() -> Components.Schemas.CreateProfileRequest {
        Components.Schemas.CreateProfileRequest(
            handle: self.handle,
            displayHandle: self.displayHandle,
            displayName: self.displayName,
            avatarUrl: self.avatarUrl
        )
    }
}

// MARK: - UpdateProfileRequest Mapping

extension Components.Schemas.UpdateProfileRequest {
    /// Convert generated UpdateProfileRequest to AppFoundation UpdateProfileRequest
    func toAppFoundation() -> UpdateProfileRequest {
        UpdateProfileRequest(
            displayHandle: self.displayHandle,
            displayName: self.displayName,
            bio: self.bio,
            avatarUrl: self.avatarUrl
        )
    }
}

extension UpdateProfileRequest {
    /// Convert AppFoundation UpdateProfileRequest to generated UpdateProfileRequest
    func toComponentsSchemas() -> Components.Schemas.UpdateProfileRequest {
        Components.Schemas.UpdateProfileRequest(
            displayHandle: self.displayHandle,
            displayName: self.displayName,
            bio: self.bio,
            avatarUrl: self.avatarUrl
        )
    }
}

// MARK: - AuthResponse Mapping

extension Components.Schemas.AuthResponse {
    /// Convert generated AuthResponse to AppFoundation AuthResponse
    func toAppFoundation() -> AuthResponse {
        AuthResponse(
            accessToken: self.accessToken,
            refreshToken: self.refreshToken,
            user: self.user.toAppFoundation()
        )
    }
}

extension AuthResponse {
    /// Convert AppFoundation AuthResponse to generated AuthResponse
    func toComponentsSchemas() -> Components.Schemas.AuthResponse {
        Components.Schemas.AuthResponse(
            accessToken: self.accessToken,
            refreshToken: self.refreshToken,
            user: self.user.toComponentsSchemas()
        )
    }
}

// MARK: - SWABeginResponse Mapping

extension Components.Schemas.SWABeginResponse {
    /// Convert generated SWABeginResponse to AppFoundation SWABeginResponse
    func toAppFoundation() -> SWABeginResponse {
        SWABeginResponse(authUrl: self.authUrl)
    }
}

extension SWABeginResponse {
    /// Convert AppFoundation SWABeginResponse to generated SWABeginResponse
    func toComponentsSchemas() -> Components.Schemas.SWABeginResponse {
        Components.Schemas.SWABeginResponse(authUrl: self.authUrl)
    }
}

