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

public struct HomeView: View {
    @State private var selectedFeed: FeedType = .forYou
    @State private var showingCompose = false
    
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
                    showingCompose = true
                } label: {
                    Image(systemName: "square.and.pencil")
                }
                .accessibilityLabel("Create a post")
            }
            
            ToolbarItem(placement: .navigationBarTrailing) {
                Picker("Feed Type", selection: $selectedFeed) {
                    ForEach(FeedType.allCases, id: \.self) { feedType in
                        Text(feedType.title)
                            .tag(feedType)
                    }
                }
                .pickerStyle(SegmentedPickerStyle())
                .frame(width: 200)
            }
        }
        .sheet(isPresented: $showingCompose) {
            ComposeView()
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

#Preview {
    HomeView()
}


