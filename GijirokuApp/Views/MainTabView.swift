import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var meetingStore: MeetingStore
    @EnvironmentObject var authService: AuthService
    @State private var selectedTab = 0
    @State private var showRecording = false
    @State private var showMeetingCreation = false
    @State private var recordedAudioURL: URL?
    @State private var recordedDuration: TimeInterval = 0
    @State private var recordedTitle = ""
    @State private var recordedLocation = ""
    @State private var recordedParticipants: [String] = []
    @State private var recordedNotes: String?
    @State private var showUpgradeAlert = false
    @ObservedObject private var planManager = PlanManager.shared

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView(onRecordTap: startRecordingIfAllowed)
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
        .fullScreenCover(isPresented: $showRecording) {
            RecordingView { url, duration, title, location, participants, notes in
                recordedAudioURL = url
                recordedDuration = duration
                recordedTitle = title
                recordedLocation = location
                recordedParticipants = participants
                recordedNotes = notes
                showMeetingCreation = true
            }
        }
        .sheet(isPresented: $showMeetingCreation) {
            if let url = recordedAudioURL {
                NavigationStack {
                    MeetingCreationView(
                        audioFileURL: url,
                        audioDuration: recordedDuration,
                        initialTitle: recordedTitle,
                        initialLocation: recordedLocation,
                        initialParticipants: recordedParticipants,
                        initialNotes: recordedNotes
                    )
                    .environmentObject(meetingStore)
                }
            }
        }
        .alert("録音回数の上限に達しました", isPresented: $showUpgradeAlert) {
            Button("OK") {}
        } message: {
            Text("Freeプランでは月5回まで録音できます。Standardプランにアップグレードすると無制限に録音できます。")
        }
        .task {
            await meetingStore.syncWithCloud()
        }
    }

    private func startRecordingIfAllowed() {
        if planManager.canStartRecording {
            showRecording = true
        } else {
            showUpgradeAlert = true
        }
    }
}
