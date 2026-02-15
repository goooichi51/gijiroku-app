import SwiftUI

struct MainTabView: View {
    @EnvironmentObject var meetingStore: MeetingStore
    @EnvironmentObject var authService: AuthService
    @State private var selectedTab = 0
    @State private var showRecording = false
    @State private var showMeetingCreation = false
    @State private var recordedAudioURL: URL?
    @State private var recordedDuration: TimeInterval = 0
    @State private var showUpgradeAlert = false
    @ObservedObject private var planManager = PlanManager.shared

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tabItem {
                        Label("ホーム", systemImage: "house")
                    }
                    .tag(0)

                // 中央タブのプレースホルダー（録音ボタンで上書き）
                Color.clear
                    .tabItem {
                        Label("録音", systemImage: "mic")
                    }
                    .tag(1)

                SearchView()
                    .tabItem {
                        Label("検索", systemImage: "magnifyingglass")
                    }
                    .tag(2)
            }

            // 中央フローティング録音ボタン
            centerRecordButton
        }
        .fullScreenCover(isPresented: $showRecording) {
            RecordingView { url, duration in
                recordedAudioURL = url
                recordedDuration = duration
                showMeetingCreation = true
            }
        }
        .sheet(isPresented: $showMeetingCreation) {
            if let url = recordedAudioURL {
                NavigationStack {
                    MeetingCreationView(
                        audioFileURL: url,
                        audioDuration: recordedDuration
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
        .onChange(of: selectedTab) { _, newValue in
            if newValue == 1 {
                // 中央タブがタップされたら録音を開始
                selectedTab = 0
                startRecordingIfAllowed()
            }
        }
    }

    private var centerRecordButton: some View {
        Button {
            startRecordingIfAllowed()
        } label: {
            ZStack {
                Circle()
                    .fill(Color.red)
                    .frame(width: 56, height: 56)
                    .shadow(color: .red.opacity(0.3), radius: 8, y: 4)
                Image(systemName: "mic.fill")
                    .font(.title3)
                    .foregroundColor(.white)
            }
        }
        .offset(y: -24)
        .accessibilityLabel("録音を開始")
        .accessibilityHint("タップして会議の録音を開始します")
    }

    private func startRecordingIfAllowed() {
        if planManager.canStartRecording {
            showRecording = true
        } else {
            showUpgradeAlert = true
        }
    }
}
