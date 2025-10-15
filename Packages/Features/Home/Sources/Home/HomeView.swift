//
//  HomeView.swift
//  Agora
//
//  Created by Agora Team on 2024.
//

import SwiftUI
import HomeForYou
import HomeFollowing
import Compose
import DMs

public struct HomeView: View {
    @State private var selectedFeed: FeedType = .forYou
    @State private var showingCompose = false
    @State private var showingFeedSettings = false
    @State private var showingMessages = false
    
    public init() {}
    
    public var body: some View {
        Group {
            switch selectedFeed {
            case .forYou:
                HomeForYouView(onComposeAction: { showingCompose = true })
            case .following:
                HomeFollowingView()
            }
        }
        .navigationTitle(selectedFeed.title)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    showingFeedSettings = true
                } label: {
                    Image(systemName: "slider.horizontal.3")
                }
                .accessibilityLabel("Feed settings")
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    showingMessages = true
                } label: {
                    Image(systemName: "message")
                }
                .accessibilityLabel("Messages")
            }
        }
        .sheet(isPresented: $showingCompose) {
            ComposeView()
        }
        .sheet(isPresented: $showingFeedSettings) {
            FeedSettingsView(selectedFeed: $selectedFeed)
        }
        .sheet(isPresented: $showingMessages) {
            NavigationStack {
                DMThreadsView()
            }
        }
    }
}

enum FeedType: String, CaseIterable {
    case forYou = "forYou"
    case following = "following"
    
    var title: String {
        switch self {
        case .forYou:
            return "For You"
        case .following:
            return "Following"
        }
    }
}

struct FeedSettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selectedFeed: FeedType
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(FeedType.allCases, id: \.self) { feedType in
                        Button {
                            selectedFeed = feedType
                            dismiss()
                        } label: {
                            HStack {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(feedType.title)
                                        .font(.body)
                                        .foregroundColor(.primary)
                                    
                                    Text(feedType == .forYou ? "Personalized recommendations" : "Posts from people you follow")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                if selectedFeed == feedType {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.blue)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Feed Type")
                }
                
                Section {
                    Text("More feed settings coming soon...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                } header: {
                    Text("Additional Settings")
                }
            }
            .navigationTitle("Feed Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    HomeView()
}


