import AVFoundation
import Combine

@MainActor
class AudioRecorderService: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var isPaused = false
    @Published var recordingTime: TimeInterval = 0
    @Published var audioLevel: Float = 0

    private var audioRecorder: AVAudioRecorder?
    private var timer: Timer?
    private var levelTimer: Timer?
    private var startTime: Date?
    private var pausedDuration: TimeInterval = 0
    private var pauseStartTime: Date?

    deinit {
        timer?.invalidate()
        levelTimer?.invalidate()
    }

    static let maxDuration: TimeInterval = 4 * 60 * 60 // 4時間

    /// プランに応じた録音時間上限（未設定時はmaxDuration）
    var overrideMaxDuration: TimeInterval?

    private var effectiveMaxDuration: TimeInterval {
        overrideMaxDuration ?? Self.maxDuration
    }

    private var warningThreshold: TimeInterval {
        effectiveMaxDuration - 10 * 60
    }

    var onTimeWarning: (() -> Void)?
    var onMaxDurationReached: (() -> Void)?

    // 録音設定（16kHz/1ch/PCM）
    private let recordingSettings: [String: Any] = [
        AVFormatIDKey: Int(kAudioFormatLinearPCM),
        AVSampleRateKey: 16000.0,
        AVNumberOfChannelsKey: 1,
        AVLinearPCMBitDepthKey: 16,
        AVLinearPCMIsBigEndianKey: false,
        AVLinearPCMIsFloatKey: false
    ]

    func requestMicrophonePermission() async -> Bool {
        await AVAudioApplication.requestRecordPermission()
    }

    func startRecording() throws -> URL {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try audioSession.setActive(true)

        let url = AudioFileManager.shared.generateRecordingURL()

        audioRecorder = try AVAudioRecorder(url: url, settings: recordingSettings)
        audioRecorder?.isMeteringEnabled = true
        audioRecorder?.delegate = self

        guard audioRecorder?.record() == true else {
            throw RecordingError.failedToStart
        }

        isRecording = true
        isPaused = false
        startTime = Date()
        pausedDuration = 0
        startTimers()

        return url
    }

    func pauseRecording() {
        guard isRecording, !isPaused else { return }
        audioRecorder?.pause()
        isPaused = true
        pauseStartTime = Date()
        stopLevelTimer()
    }

    func resumeRecording() {
        guard isRecording, isPaused else { return }
        audioRecorder?.record()
        isPaused = false
        if let pauseStart = pauseStartTime {
            pausedDuration += Date().timeIntervalSince(pauseStart)
        }
        pauseStartTime = nil
        startLevelTimer()
    }

    func stopRecording() -> URL? {
        let url = audioRecorder?.url
        audioRecorder?.stop()
        stopTimers()

        isRecording = false
        isPaused = false
        recordingTime = 0
        audioLevel = 0

        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            AppLogger.recording.error("オーディオセッションの停止に失敗: \(error.localizedDescription)")
        }

        return url
    }

    func cancelRecording() {
        let url = audioRecorder?.url
        audioRecorder?.stop()
        stopTimers()

        // 録音ファイルを削除
        if let url = url {
            AudioFileManager.shared.deleteFile(at: url)
        }

        isRecording = false
        isPaused = false
        recordingTime = 0
        audioLevel = 0
    }

    // MARK: - Timer Management

    private func startTimers() {
        startRecordingTimer()
        startLevelTimer()
    }

    private func stopTimers() {
        timer?.invalidate()
        timer = nil
        stopLevelTimer()
    }

    private func startRecordingTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateRecordingTime()
            }
        }
    }

    private func startLevelTimer() {
        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateAudioLevel()
            }
        }
    }

    private func stopLevelTimer() {
        levelTimer?.invalidate()
        levelTimer = nil
    }

    private func updateRecordingTime() {
        guard let startTime = startTime, !isPaused else { return }

        let currentPauseDuration: TimeInterval
        if let pauseStart = pauseStartTime {
            currentPauseDuration = pausedDuration + Date().timeIntervalSince(pauseStart)
        } else {
            currentPauseDuration = pausedDuration
        }

        recordingTime = Date().timeIntervalSince(startTime) - currentPauseDuration

        // 残り10分で警告
        if recordingTime >= warningThreshold && recordingTime < warningThreshold + 0.2 {
            onTimeWarning?()
        }

        // 上限で自動停止
        if recordingTime >= effectiveMaxDuration {
            onMaxDurationReached?()
        }
    }

    private func updateAudioLevel() {
        audioRecorder?.updateMeters()
        let level = audioRecorder?.averagePower(forChannel: 0) ?? -160
        // -160dB ~ 0dB を 0.0 ~ 1.0 に正規化
        let normalizedLevel = max(0, (level + 50) / 50)
        audioLevel = normalizedLevel
    }

    var formattedTime: String {
        let hours = Int(recordingTime) / 3600
        let minutes = (Int(recordingTime) % 3600) / 60
        let seconds = Int(recordingTime) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

// MARK: - AVAudioRecorderDelegate

extension AudioRecorderService: AVAudioRecorderDelegate {
    nonisolated func audioRecorderDidFinishRecording(_ recorder: AVAudioRecorder, successfully flag: Bool) {
        if !flag {
            AppLogger.recording.error("録音が異常終了しました")
        }
    }
}

// MARK: - Errors

enum RecordingError: LocalizedError {
    case microphonePermissionDenied
    case failedToStart
    case noActiveRecording

    var errorDescription: String? {
        switch self {
        case .microphonePermissionDenied:
            return "マイクへのアクセスが許可されていません。設定アプリから許可してください。"
        case .failedToStart:
            return "録音の開始に失敗しました。"
        case .noActiveRecording:
            return "録音中ではありません。"
        }
    }
}
