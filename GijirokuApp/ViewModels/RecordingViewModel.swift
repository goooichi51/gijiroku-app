import SwiftUI
import AVFoundation
import Speech
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
    @Published var showSpeechPermissionAlert = false
    @Published var isMinimalMode = false

    // 録音中に入力する会議情報
    @Published var meetingTitle = ""
    @Published var meetingLocation = ""
    @Published var meetingParticipants: [String] = []

    // シークレットモード用メモ
    @Published var secretNoteText = ""

    var isRecording: Bool { state != .idle }
    var isPaused: Bool { state == .paused }

    let recorderService = AudioRecorderService()
    private var recordingURL: URL?
    private var backgroundObserver: Any?
    private var foregroundObserver: Any?

    var formattedTime: String {
        recorderService.formattedTime
    }

    var onRecordingComplete: ((URL, TimeInterval, String, String, [String], String?) -> Void)?

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

        // 音声認識の権限を確認・リクエスト（文字起こしに必須）
        let speechStatus = SFSpeechRecognizer.authorizationStatus()
        if speechStatus == .notDetermined {
            let authorized = await withCheckedContinuation { continuation in
                SFSpeechRecognizer.requestAuthorization { status in
                    continuation.resume(returning: status == .authorized)
                }
            }
            if !authorized {
                showSpeechPermissionAlert = true
                return
            }
        } else if speechStatus != .authorized {
            showSpeechPermissionAlert = true
            return
        }

        // バックグラウンド通知の許可をリクエスト
        _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])

        do {
            recordingURL = try recorderService.startRecording()
            state = .recording
            startObserving()
        } catch let error as RecordingError {
            errorMessage = error.errorDescription
        } catch {
            errorMessage = "録音の開始に失敗しました"
        }
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
        guard let url = recorderService.stopRecording() else { return }

        state = .idle
        UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: ["recording_background"])
        PlanManager.shared.recordMeetingUsage()
        let notes = secretNoteText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : secretNoteText.trimmingCharacters(in: .whitespacesAndNewlines)
        onRecordingComplete?(url, duration, meetingTitle, meetingLocation, meetingParticipants, notes)
    }

    func requestDiscard() {
        showDiscardAlert = true
    }

    func confirmDiscard() {
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
