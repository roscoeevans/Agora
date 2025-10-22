//
//  EditHistorySheet.swift
//  Agora
//
//  Sheet for displaying post edit history
//

import SwiftUI
import DesignSystem
import AppFoundation

/// Post edit data model
public struct PostEdit: Identifiable, Codable, Sendable {
    public let id: String
    public let postId: String
    public let previousText: String
    public let editedAt: Date
    public let editedBy: String
    
    public init(id: String, postId: String, previousText: String, editedAt: Date, editedBy: String) {
        self.id = id
        self.postId = postId
        self.previousText = previousText
        self.editedAt = editedAt
        self.editedBy = editedBy
    }
}

/// Sheet view for displaying edit history
public struct EditHistorySheet: View {
    @Environment(\.deps) private var deps
    @Environment(\.dismiss) private var dismiss
    
    let postId: String
    let currentText: String
    
    @State private var edits: [PostEdit] = []
    @State private var isLoading = true
    @State private var error: Error?
    
    public init(postId: String, currentText: String) {
        self.postId = postId
        self.currentText = currentText
    }
    
    public var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    loadingView
                } else if let error = error {
                    errorView(error)
                } else {
                    contentView
                }
            }
            .navigationTitle("Edit History")
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            #endif
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(ColorTokens.tertiaryText)
                    }
                }
            }
            .task {
                await loadEditHistory()
            }
        }
    }
    
    // MARK: - Content Views
    
    private var contentView: some View {
        List {
            // Current version
            Section {
                EditVersionCard(
                    text: currentText,
                    timestamp: Date(),
                    isCurrent: true
                )
            } header: {
                Text("Current")
                    .font(TypographyScale.caption1)
                    .textCase(.uppercase)
                    .foregroundColor(ColorTokens.tertiaryText)
            }
            
            // Edit history
            if !edits.isEmpty {
                Section {
                    ForEach(edits) { edit in
                        EditVersionCard(
                            text: edit.previousText,
                            timestamp: edit.editedAt,
                            isCurrent: false
                        )
                    }
                } header: {
                    Text("Previous Versions")
                        .font(TypographyScale.caption1)
                        .textCase(.uppercase)
                        .foregroundColor(ColorTokens.tertiaryText)
                }
            }
        }
        #if os(iOS)
        .listStyle(.insetGrouped)
        #else
        .listStyle(.inset)
        #endif
    }
    
    private var loadingView: some View {
        VStack(spacing: SpacingTokens.lg) {
            ProgressView()
                .scaleEffect(1.2)
            
            Text("Loading edit history...")
                .font(TypographyScale.callout)
                .foregroundColor(ColorTokens.secondaryText)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private func errorView(_ error: Error) -> some View {
        VStack(spacing: SpacingTokens.lg) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(ColorTokens.tertiaryText)
            
            Text("Couldn't Load History")
                .font(TypographyScale.title3)
                .fontWeight(.semibold)
            
            Text("Please try again later.")
                .font(TypographyScale.body)
                .foregroundColor(ColorTokens.secondaryText)
            
            Button("Retry") {
                Task {
                    await loadEditHistory()
                }
            }
            .foregroundColor(ColorTokens.agoraBrand)
            .padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    // MARK: - Data Loading
    
    private func loadEditHistory() async {
        isLoading = true
        error = nil
        
        do {
            // TODO: Call get-edit-history Edge Function
            // let fetchedEdits = try await deps.networking.getEditHistory(postId: postId)
            // edits = fetchedEdits
            
            // Placeholder - simulate network delay
            try await Task.sleep(nanoseconds: 1_000_000_000)
            
            // Mock data for now
            edits = [
                PostEdit(
                    id: "1",
                    postId: postId,
                    previousText: "This is the first version of the post.",
                    editedAt: Date().addingTimeInterval(-3600),
                    editedBy: "user1"
                ),
                PostEdit(
                    id: "2",
                    postId: postId,
                    previousText: "Original post text before any edits.",
                    editedAt: Date().addingTimeInterval(-7200),
                    editedBy: "user1"
                )
            ]
            
            isLoading = false
            
        } catch {
            self.error = error
            isLoading = false
        }
    }
}

/// Card displaying a single edit version
struct EditVersionCard: View {
    let text: String
    let timestamp: Date
    let isCurrent: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: SpacingTokens.sm) {
            HStack {
                HStack(spacing: SpacingTokens.xxs) {
                    if isCurrent {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(ColorTokens.success)
                    }
                    
                    Text(timestamp, style: .relative)
                        .font(TypographyScale.caption1)
                        .foregroundColor(ColorTokens.tertiaryText)
                }
                
                Spacer()
                
                if isCurrent {
                    Text("Current")
                        .font(TypographyScale.caption2)
                        .fontWeight(.medium)
                        .foregroundColor(ColorTokens.success)
                        .padding(.horizontal, SpacingTokens.xs)
                        .padding(.vertical, 2)
                        .background(
                            ColorTokens.success.opacity(0.1),
                            in: RoundedRectangle(cornerRadius: BorderRadiusTokens.xs)
                        )
                }
            }
            
            Text(text)
                .font(TypographyScale.body)
                .foregroundColor(ColorTokens.primaryText)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.vertical, SpacingTokens.xs)
    }
}

// MARK: - Previews

#Preview("Edit History Sheet") {
    EditHistorySheet(
        postId: "123",
        currentText: "This is the current version of the post after multiple edits."
    )
}

