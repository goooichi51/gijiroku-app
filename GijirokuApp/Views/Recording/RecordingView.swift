import SwiftUI

struct RecordingView: View {
    @StateObject private var viewModel = RecordingViewModel()
    @Environment(\.dismiss) private var dismiss

    var onComplete: ((URL, TimeInterval) -> Void)?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // 経過時間
                Text(viewModel.formattedTime)
                    .font(.system(size: 48, weight: .light, design: .monospaced))
                    .padding(.top, 40)

                if viewModel.isPaused {
                    Text("一時停止中")
                        .foregroundColor(.orange)
                        .font(.subheadline)
                        .padding(.top, 4)
                }

                // 波形表示
                AudioWaveformView(level: viewModel.audioLevel)
                    .frame(height: 80)
                    .padding(.horizontal, 20)
                    .padding(.top, 20)

                // リアルタイム文字起こしプレビュー
                if viewModel.showLiveTranscription {
                    liveTranscriptionView
                } else {
                    Spacer()
                }

                // 残り10分警告
                if viewModel.showTimeWarning {
                    HStack {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Text("残り10分で自動停止します")
                            .font(.subheadline)
                    }
                    .padding()
                    .background(Color.orange.opacity(0.1))
                    .cornerRadius(10)
                    .padding(.horizontal)
                }

                // 操作ボタン
                HStack(spacing: 60) {
                    Button {
                        viewModel.togglePause()
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: viewModel.isPaused ? "play.circle.fill" : "pause.circle.fill")
                                .font(.system(size: 56))
                                .foregroundColor(.primary)
                            Text(viewModel.isPaused ? "再開" : "一時停止")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Button {
                        viewModel.stopRecording()
                    } label: {
                        VStack(spacing: 8) {
                            Image(systemName: "stop.circle.fill")
                                .font(.system(size: 56))
                                .foregroundColor(.red)
                            Text("停止")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.bottom, 40)
            }
            .navigationTitle("録音中")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        viewModel.requestDiscard()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.primary)
                    }
                }
            }
            .alert("録音を破棄しますか？", isPresented: $viewModel.showDiscardAlert) {
                Button("破棄", role: .destructive) {
                    viewModel.confirmDiscard()
                    dismiss()
                }
                Button("キャンセル", role: .cancel) {}
            } message: {
                Text("この録音データは削除され、復元できません。")
            }
            .alert("エラー", isPresented: .init(
                get: { viewModel.errorMessage != nil },
                set: { if !$0 { viewModel.errorMessage = nil } }
            )) {
                Button("OK") { viewModel.errorMessage = nil }
            } message: {
                if let message = viewModel.errorMessage {
                    Text(message)
                }
            }
            .task {
                await viewModel.startRecording()
            }
            .onAppear {
                viewModel.onRecordingComplete = { [weak viewModel] url, duration in
                    onComplete?(url, duration)
                    guard viewModel != nil else { return }
                    dismiss()
                }
            }
        }
    }

    private var liveTranscriptionView: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: "text.bubble")
                    .foregroundColor(.accentColor)
                Text("リアルタイム文字起こし")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                if viewModel.liveTranscription.liveText.isEmpty {
                    ProgressView()
                        .scaleEffect(0.7)
                    Text("音声を認識中...")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }
            .padding(.horizontal)

            ScrollViewReader { proxy in
                ScrollView {
                    Text(viewModel.liveTranscription.liveText.isEmpty
                         ? "録音中の音声をリアルタイムで文字起こしします..."
                         : viewModel.liveTranscription.liveText)
                        .font(.subheadline)
                        .foregroundColor(viewModel.liveTranscription.liveText.isEmpty ? .secondary : .primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                        .id("transcriptionBottom")
                }
                .onChange(of: viewModel.liveTranscription.liveText) {
                    withAnimation {
                        proxy.scrollTo("transcriptionBottom", anchor: .bottom)
                    }
                }
            }
        }
        .frame(maxHeight: 200)
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .padding(.horizontal)
        .padding(.top, 16)
    }
}
