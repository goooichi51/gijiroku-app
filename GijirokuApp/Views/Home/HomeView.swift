import SwiftUI

struct HomeView: View {
    @EnvironmentObject var meetingStore: MeetingStore
    @StateObject private var viewModel = HomeViewModel()
    @ObservedObject private var planManager = PlanManager.shared
    @State private var showUpgradeAlert = false
    @State private var meetingToDelete: Meeting?
    @State private var isSyncing = false

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
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        Task {
                            isSyncing = true
                            await meetingStore.syncWithCloud()
                            isSyncing = false
                        }
                    } label: {
                        if isSyncing {
                            ProgressView()
                                .controlSize(.small)
                        } else {
                            Image(systemName: "arrow.triangle.2.circlepath")
                        }
                    }
                    .disabled(isSyncing)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape")
                    }
                }
            }
            .refreshable {
                await meetingStore.syncWithCloud()
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
            .confirmationDialog(
                "この議事録を削除しますか？",
                isPresented: Binding(
                    get: { meetingToDelete != nil },
                    set: { if !$0 { meetingToDelete = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("削除", role: .destructive) {
                    if let meeting = meetingToDelete {
                        meetingStore.delete(meeting)
                        meetingToDelete = nil
                    }
                }
                Button("キャンセル", role: .cancel) {
                    meetingToDelete = nil
                }
            } message: {
                Text("削除した議事録は元に戻せません。")
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
        VStack(spacing: 24) {
            Spacer()

            Image(systemName: "waveform.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.purple.opacity(0.6))

            VStack(spacing: 8) {
                Text("議事録がありません")
                    .font(.title2)
                    .fontWeight(.semibold)
                Text("録音ボタンを押して\n会議を録音しましょう")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            RecordButton {
                startRecordingIfAllowed()
            }
            .padding(.top, 8)

            if planManager.currentPlan == .free {
                freeUsageLabel
            }

            Spacer()
        }
        .padding()
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
                if let first = offsets.first {
                    meetingToDelete = meetingStore.meetings[first]
                }
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
