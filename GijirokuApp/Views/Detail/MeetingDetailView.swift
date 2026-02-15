import SwiftUI

struct MeetingDetailView: View {
    @EnvironmentObject var meetingStore: MeetingStore
    @StateObject private var viewModel: MeetingDetailViewModel
    @StateObject private var audioPlayer = AudioPlayerService()
    @State private var showShareSheet = false
    @State private var pdfData: Data?
    @State private var shareURL: URL?
    @State private var shareError: String?

    init(meeting: Meeting) {
        _viewModel = StateObject(wrappedValue: MeetingDetailViewModel(meeting: meeting))
    }

    var body: some View {
        VStack(spacing: 0) {
            // 音声プレイヤー
            if let audioPath = viewModel.meeting.audioFilePath,
               AudioFileManager.shared.fileExists(at: audioPath) {
                audioPlayerView(path: audioPath)
            }

            // セグメントコントロール
            Picker("表示", selection: $viewModel.selectedTab) {
                Label("要約", systemImage: "doc.text")
                    .tag(MeetingDetailViewModel.DetailTab.summary)
                Label("全文", systemImage: "text.quote")
                    .tag(MeetingDetailViewModel.DetailTab.fullText)
            }
            .pickerStyle(.segmented)
            .padding(.horizontal)
            .padding(.top, 8)

            // タブ内容
            switch viewModel.selectedTab {
            case .summary:
                SummaryTabView(meeting: viewModel.meeting)
            case .fullText:
                FullTextTabView(segments: viewModel.meeting.transcriptionSegments ?? [])
            }

            // AI要約生成
            if viewModel.canGenerateSummary {
                Button {
                    Task {
                        await viewModel.generateSummary()
                        if viewModel.hasSummary {
                            meetingStore.update(viewModel.meeting)
                        }
                    }
                } label: {
                    HStack {
                        Image(systemName: "wand.and.stars")
                        Text("AI議事録を生成")
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.purple)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .padding(.horizontal)
            }

            if viewModel.isSummarizing {
                ProgressView("AI議事録を生成中...")
                    .padding()
            }

            if let error = viewModel.summarizationError {
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                        Text(error)
                            .font(.subheadline)
                            .fontWeight(.medium)
                    }
                    if let suggestion = viewModel.summarizationRecoverySuggestion {
                        Text(suggestion)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.red.opacity(0.1))
                .cornerRadius(12)
                .padding(.horizontal)
            }

            // 下部ボタン
            VStack(spacing: 12) {
                if PlanManager.shared.canExportPDF {
                    NavigationLink {
                        PDFPreviewView(meeting: viewModel.meeting)
                    } label: {
                        HStack {
                            Image(systemName: "doc.text")
                            Text("PDFプレビュー")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                    }

                    Button {
                        generateAndShare()
                    } label: {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("共有（LINE等）")
                        }
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                } else {
                    HStack {
                        Image(systemName: "lock.fill")
                            .foregroundColor(.orange)
                        VStack(alignment: .leading, spacing: 4) {
                            Text("PDF出力・共有はStandardプランで利用可能")
                                .font(.subheadline)
                            Text("アップグレードで議事録をPDFとして保存・共有できます")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(12)
                }
            }
            .padding()
        }
        .navigationTitle(viewModel.meeting.title.isEmpty ? "無題の議事録" : viewModel.meeting.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                NavigationLink {
                    MeetingEditView(meeting: viewModel.meeting)
                        .environmentObject(meetingStore)
                } label: {
                    Image(systemName: "pencil")
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = shareURL {
                ShareSheet(activityItems: [url])
            }
        }
        .alert("エラー", isPresented: .init(get: { shareError != nil }, set: { if !$0 { shareError = nil } })) {
            Button("OK") { shareError = nil }
        } message: {
            Text(shareError ?? "")
        }
    }

    private func audioPlayerView(path: String) -> some View {
        HStack(spacing: 12) {
            Button {
                if audioPlayer.duration == 0 {
                    audioPlayer.load(url: URL(fileURLWithPath: path))
                }
                audioPlayer.playPause()
            } label: {
                Image(systemName: audioPlayer.isPlaying ? "pause.circle.fill" : "play.circle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.accentColor)
            }
            .accessibilityLabel(audioPlayer.isPlaying ? "音声を一時停止" : "音声を再生")

            if audioPlayer.duration > 0 {
                VStack(spacing: 4) {
                    Slider(
                        value: $audioPlayer.currentTime,
                        in: 0...max(audioPlayer.duration, 1)
                    ) { editing in
                        if !editing {
                            audioPlayer.seek(to: audioPlayer.currentTime)
                        }
                    }

                    HStack {
                        Text(audioPlayer.formattedCurrentTime)
                        Spacer()
                        Text(audioPlayer.formattedDuration)
                    }
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .monospacedDigit()
                    .accessibilityElement(children: .combine)
                    .accessibilityLabel("\(audioPlayer.formattedCurrentTime) / \(audioPlayer.formattedDuration)")
                }
            } else {
                Text("音声を再生")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Spacer()
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .onDisappear {
            audioPlayer.stop()
        }
    }

    private func generateAndShare() {
        let data = PDFGenerator().generatePDF(from: viewModel.meeting)
        guard !data.isEmpty else {
            shareError = "PDFの生成に失敗しました"
            return
        }
        let fileName = "\(viewModel.meeting.title.isEmpty ? "議事録" : viewModel.meeting.title).pdf"
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        do {
            try data.write(to: tempURL)
            pdfData = data
            shareURL = tempURL
            showShareSheet = true
        } catch {
            shareError = "PDFの保存に失敗しました: \(error.localizedDescription)"
        }
    }
}
