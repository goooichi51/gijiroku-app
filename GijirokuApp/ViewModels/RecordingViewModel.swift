import SwiftUI
import UserNotifications

@MainActor
class RecordingViewModel: ObservableObject {
    enum RecordingState: Equatable {
        case idle
        case recording
        case paused
    }

    @Published var state: RecordingState = .idle
    @Published var recordingTime: TimeInterval = 0
    @Published var audioLevel: Float = 0
    @Published var showTimeWarning = false
    @Published var showDiscardAlert = false
    @Published var errorMessage: String?
    @Published var showLiveTranscription = false

    var isRecording: Bool { state != .idle }
    var isPaused: Bool { state == .paused }

    let recorderService = AudioRecorderService()
    let liveTranscription = LiveTranscriptionManager()
    private var recordingURL: URL?
    private var backgroundObserver: Any?
    private var foregroundObserver: Any?

    var formattedTime: String {
        recorderService.formattedTime
    }

    var onRecordingComplete: ((URL, TimeInterval) -> Void)?

    init() {
        setupBindings()
        setupBackgroundNotifications()
    }

    deinit {
        if let obs = backgroundObserver { NotificationCenter.default.removeObserver(obs) }
        if let obs = foregroundObserver { NotificationCenter.default.removeObserver(obs) }
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

    private func setupBackgroundNotifications() {
        backgroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handleEnterBackground()
            }
        }
        foregroundObserver = NotificationCenter.default.addObserver(
            forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.handleEnterForeground()
            }
        }
    }

    private func handleEnterBackground() {
        guard isRecording else { return }
        let content = UNMutableNotificationContent()
        content.title = "録音中"
        content.body = "バックグラウンドで録音を継続しています"
        content.sound = nil
        let request = UNNotificationRequest(identifier: "recording_background", content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }

    private func handleEnterForeground() {
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ["recording_background"])
    }

    func startRecording() async {
        let granted = await recorderService.requestMicrophonePermission()
        guard granted else {
            errorMessage = RecordingError.microphonePermissionDenied.errorDescription
            return
        }

        // バックグラウンド通知の許可をリクエスト
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])

        do {
            recordingURL = try recorderService.startRecording()
            state = .recording

            startObserving()

            // リアルタイム文字起こしを開始
            await startLiveTranscription()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    private func startLiveTranscription() async {
        showLiveTranscription = true
        await liveTranscription.start()
    }

    func togglePause() {
        if isPaused {
            recorderService.resumeRecording()
        } else {
            recorderService.pauseRecording()
        }
        state = recorderService.isPaused ? .paused : .recording
    }

    func stopRecording() {
        let duration = recorderService.recordingTime
        liveTranscription.stop()

        guard let url = recorderService.stopRecording() else { return }

        state = .idle
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ["recording_background"])
        PlanManager.shared.recordMeetingUsage()
        onRecordingComplete?(url, duration)
    }

    func requestDiscard() {
        showDiscardAlert = true
    }

    func confirmDiscard() {
        liveTranscription.stop()
        recorderService.cancelRecording()
        state = .idle
        recordingURL = nil
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ["recording_background"])
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
