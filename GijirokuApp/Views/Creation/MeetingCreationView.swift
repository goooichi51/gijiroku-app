import SwiftUI

struct MeetingCreationView: View {
    @EnvironmentObject var meetingStore: MeetingStore
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: MeetingCreationViewModel

    init(audioFileURL: URL, audioDuration: TimeInterval) {
        _viewModel = StateObject(wrappedValue: MeetingCreationViewModel(
            audioFileURL: audioFileURL,
            audioDuration: audioDuration
        ))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // テンプレート選択
                TemplateSelectionView(selected: $viewModel.selectedTemplate)

                // 会議メタ情報
                MeetingMetadataFormView(
                    title: $viewModel.title,
                    date: $viewModel.date,
                    location: $viewModel.location,
                    participants: $viewModel.participants
                )

                // 文字起こし進捗
                if viewModel.isTranscribing {
                    TranscriptionProgressView(
                        progress: viewModel.transcriptionProgress,
                        statusText: "処理中..."
                    )
                } else if viewModel.transcriptionText != nil {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("文字起こし完了")
                            .font(.subheadline)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.green.opacity(0.1))
                    .cornerRadius(12)
                }

                // AI要約プラン制限表示
                if viewModel.hasTranscription && !PlanManager.shared.canUseSummarization {
                    HStack {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.orange)
                        Text("AI議事録はStandardプランで利用可能")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                }

                // 議事録保存/生成ボタン
                Button {
                    saveMeeting()
                } label: {
                    HStack {
                        Image(systemName: viewModel.canGenerateSummary ? "wand.and.stars" : "doc.badge.plus")
                        Text(viewModel.canGenerateSummary ? "AI議事録を生成" : "議事録を保存")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }

                // 文字起こし全文確認リンク
                if let segments = viewModel.transcriptionSegments, !segments.isEmpty {
                    NavigationLink {
                        TranscriptionTextView(segments: segments)
                    } label: {
                        HStack {
                            Text("文字起こし全文を確認")
                            Image(systemName: "chevron.right")
                        }
                        .font(.subheadline)
                        .foregroundColor(.blue)
                    }
                }

                if let error = viewModel.errorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.red)
                        .padding()
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                }
            }
            .padding()
        }
        .navigationTitle("議事録作成")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("キャンセル") { dismiss() }
            }
        }
        .task {
            await viewModel.startTranscription()
        }
    }

    private func saveMeeting() {
        let meeting = viewModel.createMeeting()
        meetingStore.add(meeting)
        dismiss()
    }
}
