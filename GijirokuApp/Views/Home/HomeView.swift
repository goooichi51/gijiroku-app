import SwiftUI

struct HomeView: View {
    @EnvironmentObject var meetingStore: MeetingStore
    @StateObject private var viewModel = HomeViewModel()

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
                        SettingsPlaceholderView()
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
                viewModel.showRecording = true
            }
            .padding(.top, 10)
        }
    }

    private var meetingList: some View {
        List {
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
                    viewModel.showRecording = true
                }
                Spacer()
            }
            .padding(.bottom, 8)
        }
    }
}

// 設定画面のプレースホルダー（フェーズ7で実装）
struct SettingsPlaceholderView: View {
    var body: some View {
        Text("設定（開発中）")
            .navigationTitle("設定")
    }
}
