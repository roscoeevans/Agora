//
//  DatabaseMappers.swift
//  Messaging
//
//  Mappers to convert database models to domain models
//

import Foundation
import AppFoundation

// MARK: - Database to Domain Mappers

extension ConversationDB {
    /// Converts database conversation to domain model
    func toDomain() -> Conversation {
        let domainParticipants = participants.map { $0.toDomain() }
        
        return Conversation(
            id: thread.id,
            participants: domainParticipants,
            lastMessage: lastMessage?.toDomain(conversationId: thread.id),
            lastActivity: lastMessage?.createdAt ?? thread.updatedAt,
            unreadCount: unreadCount,
            unreadMentionsCount: 0, // TODO: Track mentions separately
            isArchived: false, // TODO: Add to DB schema if needed
            isPinned: false, // TODO: Add to DB schema if needed
            isMuted: false, // TODO: Add to DB schema if needed
            lastReadMessageId: nil, // TODO: Track read receipts
            draftText: nil, // TODO: Persist drafts
            isGroup: thread.kind == "group",
            title: thread.kind == "group" ? "Group Chat" : nil, // TODO: Add group title to DB
            avatarUrl: nil // TODO: Add group avatar support
        )
    }
}

extension DMMessageDB {
    /// Converts database message to domain model
    func toDomain(conversationId: UUID) -> Message {
        return Message(
            id: id,
            conversationId: conversationId,
            senderId: authorId,
            content: text,
            attachments: [], // TODO: Load attachments from media_bundle_id
            timestamp: createdAt,
            deliveryStatus: .sent, // TODO: Track delivery status
            replyTo: nil, // TODO: Add reply support
            nonce: nil,
            editedAt: nil, // TODO: Add edit support
            deletedAt: nil, // TODO: Add soft delete support
            expiresAt: nil, // TODO: Add expiring messages support
            systemKind: nil,
            linkPreview: nil // TODO: Add link preview support
        )
    }
}

extension UserDB {
    /// Converts database user to domain model
    func toDomain() -> User {
        return User(
            id: id.uuidString,
            handle: handle,
            displayHandle: displayHandle,
            displayName: displayName,
            bio: nil, // Not needed for DM list
            avatarUrl: avatarUrl, // String, not URL
            createdAt: Date() // Not critical for DMs
        )
    }
}

