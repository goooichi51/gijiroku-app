import SwiftUI

@main
struct GijirokuAppApp: App {
    @StateObject private var meetingStore = MeetingStore()
    @StateObject private var authService = AuthService()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some Scene {
        WindowGroup {
            Group {
                if !hasCompletedOnboarding {
                    OnboardingView {
                        hasCompletedOnboarding = true
                    }
                } else if authService.isLoading {
                    ProgressView("読み込み中...")
                } else if !authService.isAuthenticated {
                    LoginView()
                        .environmentObject(authService)
                } else {
                    MainTabView()
                        .environmentObject(meetingStore)
                        .environmentObject(authService)
                }
            }
            .task {
                await authService.restoreSession()
            }
        }
    }
}
