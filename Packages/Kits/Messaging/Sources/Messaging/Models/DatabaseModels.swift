//
//  DatabaseModels.swift
//  Messaging
//
//  Database models that match Supabase schema for direct messaging
//

import Foundation

// MARK: - Database Models (Supabase Schema)

/// Database model for dms_threads table
struct DMThreadDB: Codable, Sendable {
    let id: UUID
    let kind: String // "1:1" or "group"
    let createdAt: Date
    let updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case kind
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

/// Database model for dms_participants table
struct DMParticipantDB: Codable, Sendable {
    let threadId: UUID
    let userId: UUID
    let joinedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case threadId = "thread_id"
        case userId = "user_id"
        case joinedAt = "joined_at"
    }
}

/// Database model for dms_messages table
struct DMMessageDB: Codable, Sendable {
    let id: UUID
    let threadId: UUID
    let authorId: UUID
    let text: String
    let mediaBundleId: String?
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case threadId = "thread_id"
        case authorId = "author_id"
        case text
        case mediaBundleId = "media_bundle_id"
        case createdAt = "created_at"
    }
}

/// Combined conversation data from database
struct ConversationDB: Codable, Sendable {
    let thread: DMThreadDB
    let participants: [UserDB]
    let lastMessage: DMMessageDB?
    let unreadCount: Int
}

/// User data from database
struct UserDB: Codable, Sendable {
    let id: UUID
    let handle: String
    let displayHandle: String
    let displayName: String
    let avatarUrl: String?
    
    enum CodingKeys: String, CodingKey {
        case id
        case handle
        case displayHandle = "display_handle"
        case displayName = "display_name"
        case avatarUrl = "avatar_url"
    }
}



