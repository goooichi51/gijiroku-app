import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var meetingStore: MeetingStore
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("ホーム", systemImage: "house")
                }
                .tag(0)

            SearchView()
                .tabItem {
                    Label("検索", systemImage: "magnifyingglass")
                }
                .tag(1)
        }
        .task {
            await meetingStore.syncWithCloud()
        }
    }
}
