import SwiftUI

struct HomeView: View {
    @EnvironmentObject var meetingStore: MeetingStore
    @ObservedObject private var planManager = PlanManager.shared
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
                    .accessibilityLabel(isSyncing ? "同期中" : "クラウドと同期")
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    NavigationLink {
                        SettingsView()
                    } label: {
                        Image(systemName: "gearshape")
                    }
                    .accessibilityLabel("設定")
                }
            }
            .refreshable {
                await meetingStore.syncWithCloud()
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
                Text("下の録音ボタンを押して\n会議を録音しましょう")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

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
    }

    private var freeUsageLabel: some View {
        HStack {
            Image(systemName: "info.circle")
                .foregroundColor(.blue)
            Text("Freeプラン: 残り\(planManager.remainingFreeRecordings)回（今月）")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel("Freeプラン、今月の残り録音回数 \(planManager.remainingFreeRecordings)回")
    }
}
