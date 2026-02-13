import SwiftUI

@MainActor
class RecordingViewModel: ObservableObject {
    @Published var isRecording = false
    @Published var isPaused = false
    @Published var recordingTime: TimeInterval = 0
    @Published var audioLevel: Float = 0
    @Published var showTimeWarning = false
    @Published var showDiscardAlert = false
    @Published var errorMessage: String?
    @Published var showLiveTranscription = false

    let recorderService = AudioRecorderService()
    let liveTranscription = LiveTranscriptionManager()
    private let transcriptionService = TranscriptionService()
    private var recordingURL: URL?

    var formattedTime: String {
        recorderService.formattedTime
    }

    var onRecordingComplete: ((URL, TimeInterval) -> Void)?

    init() {
        setupBindings()
    }

    private func setupBindings() {
        let maxDuration = PlanManager.shared.maxRecordingDuration
        recorderService.overrideMaxDuration = maxDuration

        recorderService.onTimeWarning = { [weak self] in
            self?.showTimeWarning = true
        }
        recorderService.onMaxDurationReached = { [weak self] in
            self?.stopRecording()
        }
    }

    func startRecording() async {
        let granted = await recorderService.requestMicrophonePermission()
        guard granted else {
            errorMessage = RecordingError.microphonePermissionDenied.errorDescription
            return
        }

        do {
            recordingURL = try recorderService.startRecording()
            isRecording = true
            isPaused = false

            startObserving()

            // WhisperKitモデルが利用可能ならリアルタイム文字起こしを開始
            await startLiveTranscriptionIfAvailable()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func startLiveTranscriptionIfAvailable() async {
        do {
            try await transcriptionService.initialize()
            showLiveTranscription = true
            await liveTranscription.start(whisperKit: transcriptionService.whisperKit)
        } catch {
            // モデル未ダウンロードなどの場合はリアルタイム文字起こしをスキップ
            showLiveTranscription = false
        }
    }

    func togglePause() {
        if isPaused {
            recorderService.resumeRecording()
        } else {
            recorderService.pauseRecording()
        }
        isPaused = recorderService.isPaused
    }

    func stopRecording() {
        let duration = recorderService.recordingTime
        liveTranscription.stop()

        guard let url = recorderService.stopRecording() else { return }

        isRecording = false
        isPaused = false
        PlanManager.shared.recordMeetingUsage()
        onRecordingComplete?(url, duration)
    }

    func requestDiscard() {
        showDiscardAlert = true
    }

    func confirmDiscard() {
        liveTranscription.stop()
        recorderService.cancelRecording()
        isRecording = false
        isPaused = false
        recordingURL = nil
    }

    private func startObserving() {
        Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] timer in
            Task { @MainActor [weak self] in
                guard let self = self, self.isRecording else {
                    timer.invalidate()
                    return
                }
                self.recordingTime = self.recorderService.recordingTime
                self.audioLevel = self.recorderService.audioLevel
            }
        }
    }
}
