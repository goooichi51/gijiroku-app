import SwiftUI

@main
struct GijirokuAppApp: App {
    @StateObject private var meetingStore = MeetingStore()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(meetingStore)
        }
    }
}
