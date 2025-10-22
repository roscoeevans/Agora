//
//  RichTextView.swift
//  DesignSystem
//
//  Rich text view with @mention and URL parsing
//

import SwiftUI
import AppFoundation

/// Rich text view with @mention and URL parsing
public struct RichTextView: View {
    let text: String
    let onMentionTap: (String) -> Void
    let onLinkTap: (URL) -> Void
    
    @State private var attributedText = AttributedString()
    
    public init(
        text: String,
        onMentionTap: @escaping (String) -> Void = { _ in },
        onLinkTap: @escaping (URL) -> Void = { _ in }
    ) {
        self.text = text
        self.onMentionTap = onMentionTap
        self.onLinkTap = onLinkTap
    }
    
    public var body: some View {
        Text(attributedText)
            .font(TypographyScale.body)
            .foregroundColor(ColorTokens.primaryText)
            .fixedSize(horizontal: false, vertical: true)
            .onAppear {
                attributedText = parseRichText(text)
            }
            .onChange(of: text) { _, newText in
                attributedText = parseRichText(newText)
            }
    }
    
    private func parseRichText(_ text: String) -> AttributedString {
        var attributedString = AttributedString(text)
        
        // Parse @mentions
        parseMentions(in: &attributedString, text: text)
        
        // Parse URLs
        parseURLs(in: &attributedString, text: text)
        
        return attributedString
    }
    
    private func parseMentions(in attributedString: inout AttributedString, text: String) {
        let mentionPattern = #"(?<!\w)@([a-zA-Z0-9_]+)"#
        
        do {
            let regex = try NSRegularExpression(pattern: mentionPattern, options: [.caseInsensitive])
            let matches = regex.matches(in: text, options: [], range: NSRange(location: 0, length: text.count))
            
            for match in matches.reversed() {
                let range = Range(match.range, in: text)!
                let mentionText = String(text[range])
                
                // Extract handle without @ symbol
                let handle = String(mentionText.dropFirst())
                
                // Apply styling
                if let attributedRange = Range(range, in: attributedString) {
                    attributedString[attributedRange].foregroundColor = ColorTokens.agoraBrand
                    attributedString[attributedRange].link = URL(string: "mention://\(handle)")
                }
            }
        } catch {
            // If regex fails, continue without parsing
        }
    }
    
    private func parseURLs(in attributedString: inout AttributedString, text: String) {
        let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
        let matches = detector?.matches(in: text, options: [], range: NSRange(location: 0, length: text.count)) ?? []
        
        for match in matches.reversed() {
            guard let url = match.url else { continue }
            let range = Range(match.range, in: text)!
            
            // Apply styling
            if let attributedRange = Range(range, in: attributedString) {
                attributedString[attributedRange].foregroundColor = ColorTokens.agoraBrand
                attributedString[attributedRange].link = url
            }
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Rich Text with Mentions and URLs") {
    VStack(alignment: .leading, spacing: SpacingTokens.md) {
        RichTextView(
            text: "Check out @john_doe's amazing work at https://example.com!",
            onMentionTap: { handle in
                print("Mention tapped: @\(handle)")
            },
            onLinkTap: { url in
                print("Link tapped: \(url)")
            }
        )
        
        RichTextView(
            text: "Just a regular text post with no special formatting.",
            onMentionTap: { _ in },
            onLinkTap: { _ in }
        )
    }
    .padding()
}
#endif