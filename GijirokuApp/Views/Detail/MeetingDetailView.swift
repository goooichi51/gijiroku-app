import SwiftUI

struct MeetingDetailView: View {
    @EnvironmentObject var meetingStore: MeetingStore
    @StateObject private var viewModel: MeetingDetailViewModel
    @State private var showShareSheet = false
    @State private var pdfData: Data?

    init(meeting: Meeting) {
        _viewModel = StateObject(wrappedValue: MeetingDetailViewModel(meeting: meeting))
    }

    var body: some View {
        VStack(spacing: 0) {
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
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
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
            if let data = pdfData {
                let fileName = "\(viewModel.meeting.title.isEmpty ? "議事録" : viewModel.meeting.title).pdf"
                let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
                let _ = try? data.write(to: tempURL)
                ShareSheet(activityItems: [tempURL])
            }
        }
    }

    private func generateAndShare() {
        pdfData = PDFGenerator().generatePDF(from: viewModel.meeting)
        showShareSheet = true
    }
}
