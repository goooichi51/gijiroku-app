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
                    .font(.system(size: 56, weight: .light, design: .monospaced))
                    .padding(.top, 60)

                if viewModel.isPaused {
                    Text("一時停止中")
                        .foregroundColor(.orange)
                        .font(.subheadline)
                        .padding(.top, 4)
                }

                // 波形表示
                AudioWaveformView(level: viewModel.audioLevel)
                    .frame(height: 100)
                    .padding(.horizontal, 20)
                    .padding(.top, 40)

                Spacer()

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
                    // 一時停止/再開ボタン
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

                    // 停止ボタン
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
                .padding(.bottom, 60)
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
}
