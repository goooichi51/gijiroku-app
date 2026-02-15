import SwiftUI

@main
struct GijirokuWatchApp: App {
    @StateObject private var sessionManager = WatchSessionManager.shared

    var body: some Scene {
        WindowGroup {
            WatchMainView()
                .environmentObject(sessionManager)
        }
    }
}
