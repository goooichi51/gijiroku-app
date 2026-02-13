import SwiftUI

struct HomeView: View {
    @EnvironmentObject var meetingStore: MeetingStore
    @StateObject private var viewModel = HomeViewModel()
    @ObservedObject private var planManager = PlanManager.shared
    @State private var showUpgradeAlert = false

    var body: some View {
        NavigationStack {
            ZStack {
                if meetingStore.meetings.isEmpty {
                    emptyState
                } else {
                    meetingList
                }
            }
            .navigationTitle("議事録")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .fullScreenCover(isPresented: $viewModel.showRecording) {
                RecordingView { url, duration in
                    viewModel.onRecordingComplete(url: url, duration: duration)
                }
            }
            .sheet(isPresented: $viewModel.showMeetingCreation) {
                if let url = viewModel.recordedAudioURL {
                    NavigationStack {
                        MeetingCreationView(
                            audioFileURL: url,
                            audioDuration: viewModel.recordedDuration
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
        }
    }

    private func startRecordingIfAllowed() {
        if planManager.canStartRecording {
            viewModel.showRecording = true
        } else {
            showUpgradeAlert = true
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "mic.circle")
                .font(.system(size: 60))
                .foregroundColor(.secondary)
            Text("議事録がありません")
                .font(.title3)
                .foregroundColor(.secondary)
            Text("録音ボタンを押して会議を録音しましょう")
                .font(.subheadline)
                .foregroundColor(.secondary)

            RecordButton {
                startRecordingIfAllowed()
            }
            .padding(.top, 10)

            if planManager.currentPlan == .free {
                freeUsageLabel
            }
        }
    }

    private var meetingList: some View {
        List {
            if planManager.currentPlan == .free {
                Section {
                    freeUsageLabel
                }
            }

            ForEach(meetingStore.meetings) { meeting in
                NavigationLink {
                    MeetingDetailView(meeting: meeting)
                        .environmentObject(meetingStore)
                } label: {
                    MeetingListItemView(meeting: meeting)
                }
            }
            .onDelete { offsets in
                meetingStore.delete(at: offsets)
            }
        }
        .safeAreaInset(edge: .bottom) {
            HStack {
                Spacer()
                RecordButton {
                    startRecordingIfAllowed()
                }
                Spacer()
            }
            .padding(.bottom, 8)
        }
    }

    private var freeUsageLabel: some View {
        HStack {
            Image(systemName: "info.circle")
                .foregroundColor(.blue)
            Text("Freeプラン: 残り\(planManager.remainingFreeRecordings)回（今月）")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
}
