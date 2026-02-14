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
                    loadingView
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

    private var loadingView: some View {
        VStack(spacing: 16) {
            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 60))
                .foregroundStyle(.purple.opacity(0.6))
            ProgressView()
                .controlSize(.large)
            Text("読み込み中...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}
