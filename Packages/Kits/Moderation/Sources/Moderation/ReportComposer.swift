import Foundation
import SwiftUI

/// Report types for content moderation
public enum ReportType: String, CaseIterable {
    case spam = "spam"
    case harassment = "harassment"
    case hateSpeech = "hate_speech"
    case violence = "violence"
    case sexualContent = "sexual_content"
    case misinformation = "misinformation"
    case copyright = "copyright"
    case other = "other"
    
    public var displayName: String {
        switch self {
        case .spam:
            return "Spam"
        case .harassment:
            return "Harassment"
        case .hateSpeech:
            return "Hate Speech"
        case .violence:
            return "Violence"
        case .sexualContent:
            return "Sexual Content"
        case .misinformation:
            return "Misinformation"
        case .copyright:
            return "Copyright Violation"
        case .other:
            return "Other"
        }
    }
    
    public var description: String {
        switch self {
        case .spam:
            return "Unwanted or repetitive content"
        case .harassment:
            return "Targeted harassment or bullying"
        case .hateSpeech:
            return "Content that promotes hatred"
        case .violence:
            return "Violent or graphic content"
        case .sexualContent:
            return "Inappropriate sexual content"
        case .misinformation:
            return "False or misleading information"
        case .copyright:
            return "Unauthorized use of copyrighted material"
        case .other:
            return "Other policy violation"
        }
    }
}

/// Content report data structure
public struct ContentReport {
    public let id: UUID
    public let contentId: String
    public let contentType: ContentType
    public let reportType: ReportType
    public let description: String
    public let reporterId: String?
    public let createdAt: Date
    
    public init(
        contentId: String,
        contentType: ContentType,
        reportType: ReportType,
        description: String,
        reporterId: String? = nil
    ) {
        self.id = UUID()
        self.contentId = contentId
        self.contentType = contentType
        self.reportType = reportType
        self.description = description
        self.reporterId = reporterId
        self.createdAt = Date()
    }
}

/// Content types that can be reported
public enum ContentType: String, CaseIterable {
    case post = "post"
    case reply = "reply"
    case user = "user"
    case directMessage = "direct_message"
}

/// Report submission errors
public enum ReportError: LocalizedError {
    case networkError(Error)
    case invalidContent
    case alreadyReported
    case rateLimited
    
    public var errorDescription: String? {
        switch self {
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidContent:
            return "Invalid content to report"
        case .alreadyReported:
            return "Content has already been reported"
        case .rateLimited:
            return "Too many reports submitted. Please try again later."
        }
    }
}

/// Report composer for content moderation
public final class ReportComposer: ObservableObject {
    @Published public var selectedReportType: ReportType?
    @Published public var reportDescription: String = ""
    @Published public var isSubmitting: Bool = false
    
    public init() {}
    
    /// Submits a content report
    public func submitReport(
        contentId: String,
        contentType: ContentType,
        reportType: ReportType,
        description: String
    ) async throws {
        isSubmitting = true
        defer { isSubmitting = false }
        
        let report = ContentReport(
            contentId: contentId,
            contentType: contentType,
            reportType: reportType,
            description: description
        )
        
        // TODO: Submit report to backend API
        try await Task.sleep(nanoseconds: 1_000_000_000) // Simulate network delay
        
        print("Report submitted: \(report)")
        
        // Reset form
        selectedReportType = nil
        reportDescription = ""
    }
    
    /// Validates report data
    public func validateReport() -> Bool {
        guard let _ = selectedReportType else { return false }
        return !reportDescription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

/// SwiftUI view for report composition
public struct ReportComposerView: View {
    @StateObject private var composer = ReportComposer()
    @Environment(\.dismiss) private var dismiss
    
    let contentId: String
    let contentType: ContentType
    
    public init(contentId: String, contentType: ContentType) {
        self.contentId = contentId
        self.contentType = contentType
    }
    
    public var body: some View {
        NavigationView {
            Form {
                Section("Report Type") {
                    ForEach(ReportType.allCases, id: \.self) { reportType in
                        Button(action: {
                            composer.selectedReportType = reportType
                        }) {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text(reportType.displayName)
                                        .foregroundColor(.primary)
                                    Text(reportType.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                                if composer.selectedReportType == reportType {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                }
                
                if composer.selectedReportType != nil {
                    Section("Additional Details") {
                        TextField("Describe the issue...", text: $composer.reportDescription, axis: .vertical)
                            .lineLimit(3...6)
                    }
                }
            }
            .navigationTitle("Report Content")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Submit") {
                        Task {
                            guard let reportType = composer.selectedReportType else { return }
                            
                            do {
                                try await composer.submitReport(
                                    contentId: contentId,
                                    contentType: contentType,
                                    reportType: reportType,
                                    description: composer.reportDescription
                                )
                                dismiss()
                            } catch {
                                // Handle error
                                print("Failed to submit report: \(error)")
                            }
                        }
                    }
                    .disabled(!composer.validateReport() || composer.isSubmitting)
                }
            }
        }
    }
}