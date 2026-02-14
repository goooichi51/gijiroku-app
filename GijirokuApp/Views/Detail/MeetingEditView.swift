import SwiftUI

struct MeetingEditView: View {
    @EnvironmentObject var meetingStore: MeetingStore
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: MeetingEditViewModel
    @State private var showDiscardAlert = false

    init(meeting: Meeting) {
        _viewModel = StateObject(wrappedValue: MeetingEditViewModel(meeting: meeting))
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // タイトル
                VStack(alignment: .leading, spacing: 4) {
                    Text("タイトル")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("タイトル", text: $viewModel.title)
                        .textFieldStyle(.roundedBorder)
                }

                // 日時
                VStack(alignment: .leading, spacing: 4) {
                    Text("日時")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    DatePicker("", selection: $viewModel.date, displayedComponents: [.date, .hourAndMinute])
                        .labelsHidden()
                        .environment(\.locale, Locale(identifier: "ja_JP"))
                }

                // 場所
                VStack(alignment: .leading, spacing: 4) {
                    Text("場所")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    TextField("場所", text: $viewModel.location)
                        .textFieldStyle(.roundedBorder)
                }

                // 参加者
                VStack(alignment: .leading, spacing: 4) {
                    Text("参加者")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    ParticipantTagView(participants: $viewModel.participants)
                }

                Divider()

                // 議事録内容
                VStack(alignment: .leading, spacing: 4) {
                    Text("議事録内容")
                        .font(.headline)
                    TextEditor(text: $viewModel.summaryRawText)
                        .frame(minHeight: 300)
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color(.systemGray4), lineWidth: 1)
                        )
                }
            }
            .padding()
        }
        .navigationTitle("編集")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("キャンセル") {
                    if viewModel.hasUnsavedChanges {
                        showDiscardAlert = true
                    } else {
                        dismiss()
                    }
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("保存") {
                    viewModel.save()
                    dismiss()
                }
                .fontWeight(.bold)
            }
        }
        .alert("変更を破棄しますか？", isPresented: $showDiscardAlert) {
            Button("破棄", role: .destructive) {
                dismiss()
            }
            Button("編集を続ける", role: .cancel) {}
        } message: {
            Text("保存されていない変更があります。")
        }
        .onAppear {
            viewModel.setStore(meetingStore)
        }
        .interactiveDismissDisabled(viewModel.hasUnsavedChanges)
    }
}
