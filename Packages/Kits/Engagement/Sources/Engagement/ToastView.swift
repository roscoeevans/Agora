//
//  ToastView.swift
//  Engagement
//
//  Toast notification view for brief feedback messages
//

import SwiftUI

/// Identifiable toast message
struct Toast: Identifiable, Equatable, Sendable {
    let id = UUID()
    let message: String
}

/// Toast notification view
/// Displays brief feedback message with glass material effect
struct ToastView: View {
    let message: String
    
    var body: some View {
        Text(message)
            .font(.footnote.weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.ultraThinMaterial, in: Capsule())
            .shadow(radius: 8)
            .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}


