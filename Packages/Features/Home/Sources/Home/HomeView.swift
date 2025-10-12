//
//  HomeView.swift
//  Agora
//
//  Created by Agora Team on 2024.
//

import SwiftUI
import HomeForYou
import HomeFollowing

public struct HomeView: View {
    @State private var selectedFeed: FeedType = .forYou
    
    public init() {}
    
    public var body: some View {
        NavigationStack {
            Group {
                switch selectedFeed {
                case .forYou:
                    HomeForYouView()
                case .following:
                    HomeFollowingView()
                }
            }
            .navigationTitle(selectedFeed.title)
            .navigationBarTitleDisplayMode(.large)
            .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
            .toolbar {
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


