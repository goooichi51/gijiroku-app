import SwiftUI

struct WatchMainView: View {
    @EnvironmentObject var sessionManager: WatchSessionManager
    @StateObject private var recorder = WatchAudioRecorder()
    @State private var showContinuationPrompt = false
    @State private var showStopConfirm = false
    @State private var recordedDuration: TimeInterval = 0

    var body: some View {
        NavigationStack {
            Group {
                if sessionManager.isTransferring || sessionManager.lastTransferSuccess {
                    transferView
                } else if recorder.isRecording {
                    recordingView
                } else {
                    idleView
                }
            }
            .navigationTitle("議事録")
            .navigationBarTitleDisplayMode(.inline)
        }
        .onChange(of: recorder.recordingTime) { _, newValue in
            checkContinuationPrompt(time: newValue)
        }
        .alert("30分経過", isPresented: $showContinuationPrompt) {
            Button("続ける") {}
            Button("停止", role: .destructive) {
                stopAndTransfer()
            }
        } message: {
            Text("録音を続けますか？")
        }
        .alert("録音を停止しますか？", isPresented: $showStopConfirm) {
            Button("停止して転送", role: .destructive) {
                stopAndTransfer()
            }
            Button("キャンセル", role: .cancel) {}
        }
    }

    // MARK: - Idle

    private var idleView: some View {
        VStack(spacing: 16) {
            Spacer()

            Button {
                recorder.startRecording()
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 80, height: 80)
                    Image(systemName: "mic.fill")
                        .font(.title)
                        .foregroundColor(.white)
                }
            }
            .buttonStyle(.plain)
            .accessibilityLabel("録音開始")

            Text("タップで録音開始")
                .font(.caption)
                .foregroundColor(.secondary)

            if !sessionManager.isReachable {
                HStack(spacing: 4) {
                    Image(systemName: "iphone.slash")
                        .font(.caption2)
                    Text("iPhone未接続")
                        .font(.caption2)
                }
                .foregroundColor(.orange)
            }

            Spacer()
        }
    }

    // MARK: - Recording

    private var recordingView: some View {
        VStack(spacing: 12) {
            HStack(spacing: 6) {
                Circle()
                    .fill(recorder.isPaused ? Color.orange : Color.red)
                    .frame(width: 8, height: 8)
                Text(recorder.isPaused ? "一時停止中" : "録音中")
                    .font(.caption)
                    .foregroundColor(recorder.isPaused ? .orange : .red)
            }

            Text(recorder.formattedTime)
                .font(.system(size: 28, weight: .medium, design: .monospaced))
                .monospacedDigit()

            // 波形
            WatchWaveformView(level: recorder.audioLevel, isActive: !recorder.isPaused)
                .frame(height: 30)

            HStack(spacing: 20) {
                // 一時停止/再開
                Button {
                    if recorder.isPaused {
                        recorder.resumeRecording()
                    } else {
                        recorder.pauseRecording()
                    }
                } label: {
                    Image(systemName: recorder.isPaused ? "play.fill" : "pause.fill")
                        .font(.title3)
                }
                .accessibilityLabel(recorder.isPaused ? "再開" : "一時停止")

                // 停止
                Button {
                    showStopConfirm = true
                } label: {
                    Image(systemName: "stop.fill")
                        .font(.title3)
                        .foregroundColor(.red)
                }
                .accessibilityLabel("録音停止")
            }
        }
    }

    // MARK: - Transfer

    private var transferView: some View {
        VStack(spacing: 12) {
            if sessionManager.lastTransferSuccess {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.green)
                Text("転送完了")
                    .font(.headline)

                Button("新しい録音") {
                    sessionManager.lastTransferSuccess = false
                }
                .padding(.top, 8)
            } else if let error = sessionManager.transferError {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.orange)
                Text("転送エラー")
                    .font(.headline)
                Text(error)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            } else {
                Image(systemName: "iphone.and.arrow.forward")
                    .font(.system(size: 30))
                    .foregroundColor(.blue)
                Text("iPhoneに転送中...")
                    .font(.subheadline)
                ProgressView()
            }
        }
    }

    // MARK: - Helpers

    private func stopAndTransfer() {
        recordedDuration = recorder.recordingTime
        guard let url = recorder.stopRecording() else { return }
        sessionManager.transferAudioFile(at: url, duration: recordedDuration)
    }

    private func checkContinuationPrompt(time: TimeInterval) {
        guard time > 0 else { return }
        let checkInterval = recorder.checkInterval
        let intervals = Int(time / checkInterval)
        let checkpoint = Double(intervals) * checkInterval
        if intervals > 0 && time >= checkpoint && time - checkpoint < 1.0 {
            showContinuationPrompt = true
        }
    }
}
