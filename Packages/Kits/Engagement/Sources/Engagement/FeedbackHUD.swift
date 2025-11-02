//
//  FeedbackHUD.swift
//  Engagement
//
//  Visual feedback HUD for async operations (sending, success, failure)
//

import SwiftUI

/// State of the feedback HUD
enum HUDState: Equatable, Sendable {
    case hidden
    case sending
    case success
    case failure
}

/// Feedback HUD for displaying async operation states
/// Shows centered overlay with glass material effect
struct FeedbackHUD: View {
    let state: HUDState
    
    var body: some View {
        Group {
            switch state {
            case .hidden:
                EmptyView()
                
            case .sending:
                Capsule()
                    .fill(.ultraThinMaterial)
                    .frame(width: 132, height: 56)
                    .overlay {
                        HStack(spacing: 10) {
                            ProgressView()
                            Text("Sending…")
                                .font(.callout)
                        }
                    }
                    .shadow(radius: 8)
                
            case .success:
                Capsule()
                    .fill(.ultraThinMaterial)
                    .frame(width: 132, height: 56)
                    .overlay {
                        HStack(spacing: 8) {
                            Image(systemName: "checkmark.circle.fill")
                                .imageScale(.large)
                                .foregroundStyle(.green)
                            Text("Sent")
                                .font(.callout)
                                .bold()
                        }
                    }
                    .shadow(radius: 8)
                    .transition(.opacity.combined(with: .scale))
                
            case .failure:
                Capsule()
                    .fill(.ultraThinMaterial)
                    .frame(width: 156, height: 56)
                    .overlay {
                        HStack(spacing: 8) {
                            Image(systemName: "xmark.octagon.fill")
                                .imageScale(.large)
                                .foregroundStyle(.red)
                            Text("Failed")
                                .font(.callout)
                                .bold()
                        }
                    }
                    .shadow(radius: 8)
                    .transition(.opacity.combined(with: .scale))
            }
        }
        .animation(.snappy, value: state)
    }
}


