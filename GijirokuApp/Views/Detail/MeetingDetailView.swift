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

            // 下部ボタン
            VStack(spacing: 12) {
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
