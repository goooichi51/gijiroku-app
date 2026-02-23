import SwiftUI

struct RecordingView: View {
    @StateObject private var viewModel = RecordingViewModel()
    @Environment(\.dismiss) private var dismiss

    var onComplete: ((URL, TimeInterval, String, String, [String], String?, MeetingTemplate, UUID?) -> Void)?

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isMinimalMode {
                    secretModeView
                } else {
                    normalModeView
                }
            }
            .navigationTitle(viewModel.isMinimalMode ? "Memo" : "録音中")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    if !viewModel.isMinimalMode {
                        Button {
                            viewModel.requestDiscard()
                        } label: {
                            Image(systemName: "xmark")
                                .foregroundColor(.primary)
                        }
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.3)) {
                            viewModel.isMinimalMode.toggle()
                        }
                    } label: {
                        if viewModel.isMinimalMode {
                            Image(systemName: "arrow.up.left.and.arrow.down.right")
                                .foregroundColor(.accentColor)
                        } else {
                            HStack(spacing: 4) {
                                Image(systemName: "note.text")
                                Text("メモ")
                                    .font(.subheadline)
                            }
                            .foregroundColor(.accentColor)
                        }
                    }
                    .accessibilityLabel(viewModel.isMinimalMode ? "録音画面に戻す" : "メモ画面に切替")
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
            .alert("音声認識の許可が必要です", isPresented: $viewModel.showSpeechPermissionAlert) {
                Button("設定を開く") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                    dismiss()
                }
                Button("キャンセル", role: .cancel) {
                    dismiss()
                }
            } message: {
                Text("このアプリは音声認識を使って文字起こしを行います。設定アプリから「音声認識」を許可してください。")
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
                viewModel.onRecordingComplete = { [weak viewModel] url, duration, title, location, participants, notes, template, customTemplateId in
                    onComplete?(url, duration, title, location, participants, notes, template, customTemplateId)
                    guard viewModel != nil else { return }
                    dismiss()
                }
            }
        }
    }

    // MARK: - 通常モード（会議情報入力 + 録音コントロール）

    private var normalModeView: some View {
        VStack(spacing: 0) {
            // 録音ヘッダー（タイマー + 波形）
            recordingHeader

            // 会議情報入力フォーム
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // ステータスバッジ
                    HStack(spacing: 6) {
                        Circle()
                            .fill(viewModel.isPaused ? Color.orange : Color.red)
                            .frame(width: 8, height: 8)
                        Text(viewModel.isPaused ? "一時停止中" : "録音中")
                            .font(.caption)
                            .foregroundColor(viewModel.isPaused ? .orange : .red)
                        Text("・終了後にAI文字起こし・要約を生成")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(.top, 12)

                    // テンプレート選択
                    TemplateSelectionView(
                        selected: $viewModel.selectedTemplate,
                        selectedCustomTemplateId: $viewModel.selectedCustomTemplateId
                    )

                    // タイトル
                    VStack(alignment: .leading, spacing: 4) {
                        Text("タイトル")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("会議のタイトル", text: $viewModel.meetingTitle)
                            .textFieldStyle(.roundedBorder)
                    }

                    // 場所
                    VStack(alignment: .leading, spacing: 4) {
                        Text("場所")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("場所", text: $viewModel.meetingLocation)
                            .textFieldStyle(.roundedBorder)
                    }

                    // 参加者
                    VStack(alignment: .leading, spacing: 4) {
                        Text("参加者")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        ParticipantTagView(participants: $viewModel.meetingParticipants)
                    }
                }
                .padding(.horizontal)
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
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
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
                .accessibilityLabel(viewModel.isPaused ? "録音を再開" : "録音を一時停止")

                Button {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
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
                .accessibilityLabel("録音を停止して保存")
            }
            .padding(.vertical, 20)
        }
    }

    // MARK: - 録音ヘッダー

    private var recordingHeader: some View {
        VStack(spacing: 0) {
            Text(viewModel.formattedTime)
                .font(.system(size: 40, weight: .light, design: .monospaced))
                .padding(.top, 16)
                .accessibilityLabel("録音時間 \(viewModel.formattedTime)")

            AudioWaveformView(level: viewModel.audioLevel)
                .frame(height: 50)
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .accessibilityHidden(true)

            // パルスアニメーション（録音中インジケーター）
            RecordingPulseView(
                audioLevel: viewModel.audioLevel,
                isPaused: viewModel.isPaused
            )
            .frame(height: 120)
            .padding(.top, 4)
        }
        .padding(.bottom, 8)
        .background(Color(.systemGroupedBackground))
    }

    // MARK: - シークレットモード（メモ帳風）

    private var secretModeView: some View {
        VStack(spacing: 0) {
            // メモ帳風テキストエディタ
            TextEditor(text: $viewModel.secretNoteText)
                .font(.body)
                .padding(.horizontal, 4)
                .scrollContentBackground(.hidden)
                .background(Color(.systemBackground))
                .overlay(alignment: .topLeading) {
                    if viewModel.secretNoteText.isEmpty {
                        Text("メモを入力...")
                            .font(.body)
                            .foregroundColor(.secondary.opacity(0.5))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 8)
                            .allowsHitTesting(false)
                    }
                }

            Divider()

            // 下部バー
            HStack {
                Spacer()
                Text("バックグラウンドでも動作します")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary.opacity(0.4))
                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(.systemGroupedBackground))
        }
    }
}
