import SwiftUI

struct MeetingDetailView: View {
    @EnvironmentObject var meetingStore: MeetingStore
    @StateObject private var viewModel: MeetingDetailViewModel

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
        }
        .navigationTitle(viewModel.meeting.title.isEmpty ? "無題の議事録" : viewModel.meeting.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                // 編集ボタン（フェーズ6で実装）
                NavigationLink {
                    Text("編集画面（開発中）")
                } label: {
                    Image(systemName: "pencil")
                }

                // 共有ボタン（フェーズ6で実装）
                Button {
                    // フェーズ6で共有機能を実装
                } label: {
                    Image(systemName: "square.and.arrow.up")
                }
            }
        }
    }
}
