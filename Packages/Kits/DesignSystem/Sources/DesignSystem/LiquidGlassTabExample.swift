import SwiftUI

/// Example implementation of iOS 26 Liquid Glass Tab View
/// Demonstrates tab view styling with modern iOS 26 features
@available(iOS 26.0, *)
public struct LiquidGlassTabExample: View {
    @State private var selectedTab = 0
    
    public init() {}
    
    public var body: some View {
        TabView(selection: $selectedTab) {
            HomeTab()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
                .tag(0)
            
            ExploreTab()
                .tabItem {
                    Label("Explore", systemImage: "compass.fill")
                }
                .tag(1)
            
            NotificationsTab()
                .tabItem {
                    Label("Notifications", systemImage: "bell.fill")
                }
                .tag(2)
            
            ProfileTab()
                .tabItem {
                    Label("Profile", systemImage: "person.fill")
                }
                .tag(3)
        }
        .tint(.blue)
    }
}

// MARK: - Tab Content Views

private struct HomeTab: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(0..<10) { index in
                        ContentCard(title: "Post \(index + 1)", color: .blue)
                    }
                }
                .padding()
            }
            .navigationTitle("Home")
            .background(Color(.systemGroupedBackground))
        }
    }
}

private struct ExploreTab: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 16) {
                    ForEach(0..<12) { index in
                        RoundedRectangle(cornerRadius: 12)
                            .fill(
                                LinearGradient(
                                    colors: [.purple, .pink],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(height: 150)
                            .overlay {
                                Text("Item \(index + 1)")
                                    .font(.headline)
                                    .foregroundStyle(.white)
                            }
                    }
                }
                .padding()
            }
            .navigationTitle("Explore")
            .background(Color(.systemGroupedBackground))
        }
    }
}

private struct NotificationsTab: View {
    var body: some View {
        NavigationStack {
            List {
                ForEach(0..<15) { index in
                    NotificationRow(index: index)
                }
            }
            .navigationTitle("Notifications")
        }
    }
}

private struct ProfileTab: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    // Profile Header
                    VStack(spacing: 12) {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [.orange, .red],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 100, height: 100)
                            .overlay {
                                Image(systemName: "person.fill")
                                    .font(.system(size: 40))
                                    .foregroundStyle(.white)
                            }
                        
                        Text("Jane Doe")
                            .font(.title2)
                            .fontWeight(.bold)
                        
                        Text("@janedoe")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.top)
                    
                    // Stats
                    HStack(spacing: 40) {
                        StatView(value: "1.2K", label: "Posts")
                        StatView(value: "45.3K", label: "Followers")
                        StatView(value: "892", label: "Following")
                    }
                    
                    // Recent Posts
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Recent Posts")
                            .font(.headline)
                            .padding(.horizontal)
                        
                        ForEach(0..<5) { index in
                            ContentCard(title: "My Post \(index + 1)", color: .green)
                                .padding(.horizontal)
                        }
                    }
                }
                .padding(.vertical)
            }
            .navigationTitle("Profile")
            .background(Color(.systemGroupedBackground))
        }
    }
}

// MARK: - Supporting Views

private struct ContentCard: View {
    let title: String
    let color: Color
    
    var body: some View {
        RoundedRectangle(cornerRadius: 12)
            .fill(color.gradient)
            .frame(height: 120)
            .overlay {
                VStack(spacing: 8) {
                    Image(systemName: "photo.fill")
                        .font(.largeTitle)
                        .foregroundStyle(.white.opacity(0.9))
                    
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.white)
                }
            }
            .shadow(color: color.opacity(0.3), radius: 8, x: 0, y: 4)
    }
}

private struct NotificationRow: View {
    let index: Int
    
    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [.blue, .cyan],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .frame(width: 44, height: 44)
                .overlay {
                    Image(systemName: notificationIcon)
                        .foregroundStyle(.white)
                }
            
            VStack(alignment: .leading, spacing: 4) {
                Text("Notification \(index + 1)")
                    .font(.headline)
                
                Text("This is a sample notification message")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Text("2h")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }
    
    private var notificationIcon: String {
        let icons = ["heart.fill", "message.fill", "person.fill.badge.plus", "arrow.2.squarepath"]
        return icons[index % icons.count]
    }
}

private struct StatView: View {
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.title3)
                .fontWeight(.bold)
            
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Preview

#if DEBUG
@available(iOS 26.0, *)
#Preview("Liquid Glass Tab View") {
    LiquidGlassTabExample()
}

@available(iOS 26.0, *)
#Preview("Home Tab Only") {
    HomeTab()
}

@available(iOS 26.0, *)
#Preview("Explore Tab Only") {
    ExploreTab()
}

@available(iOS 26.0, *)
#Preview("Notifications Tab Only") {
    NotificationsTab()
}

@available(iOS 26.0, *)
#Preview("Profile Tab Only") {
    ProfileTab()
}
#endif

