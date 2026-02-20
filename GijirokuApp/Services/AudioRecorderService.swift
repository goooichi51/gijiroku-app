import AVFoundation
import Combine

@MainActor
class AudioRecorderService: ObservableObject {
    @Published var isRecording = false
    @Published var isPaused = false
    @Published var recordingTime: TimeInterval = 0
    @Published var audioLevel: Float = 0

    private var audioEngine: AVAudioEngine?
    private var audioFile: AVAudioFile?
    private var timer: Timer?
    private var startTime: Date?
    private var pausedDuration: TimeInterval = 0
    private var pauseStartTime: Date?

    // タップコールバックから書き込み制御（一時停止用）
    private var isWritingEnabled = true
    // タップコールバックから計算された音量レベル
    private var currentLevel: Float = -160

    /// 外部（LiveTranscriptionManager）へバッファを転送するコールバック
    var onAudioBuffer: ((AVAudioPCMBuffer) -> Void)?

    /// 録音中のネイティブフォーマット（SpeechAnalyzerのフォーマット変換に使用）
    var nativeFormat: AVAudioFormat? {
        audioEngine?.inputNode.outputFormat(forBus: 0)
    }

    deinit {
        timer?.invalidate()
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

    func requestMicrophonePermission() async -> Bool {
        await AVAudioApplication.requestRecordPermission()
    }

    /// 録音を開始（ハードウェアのネイティブフォーマットを使用）
    func startRecording() throws -> URL {
        let audioSession = AVAudioSession.sharedInstance()
        try audioSession.setCategory(.playAndRecord, mode: .default, options: [.defaultToSpeaker])
        try audioSession.setActive(true)

        let url = AudioFileManager.shared.generateRecordingURL()

        let engine = AVAudioEngine()
        let inputNode = engine.inputNode
        let nativeFormat = inputNode.outputFormat(forBus: 0)

        guard nativeFormat.channelCount > 0 else {
            throw RecordingError.failedToStart
        }

        audioFile = try AVAudioFile(forWriting: url, settings: nativeFormat.settings)
        isWritingEnabled = true

        // format: nil で最大互換性（実機でのクラッシュを防止）
        inputNode.installTap(onBus: 0, bufferSize: 4096, format: nil) { [weak self] buffer, _ in
            guard let self else { return }
            // ファイルへ書き込み（一時停止中はスキップ）
            if self.isWritingEnabled {
                try? self.audioFile?.write(from: buffer)
            }
            // 音量レベル計算
            self.calculateLevel(from: buffer)
            // リアルタイム文字起こしへ転送
            self.onAudioBuffer?(buffer)
        }

        try engine.start()
        audioEngine = engine

        isRecording = true
        isPaused = false
        startTime = Date()
        pausedDuration = 0
        startTimer()

        return url
    }

    func pauseRecording() {
        guard isRecording, !isPaused else { return }
        isWritingEnabled = false
        isPaused = true
        pauseStartTime = Date()
    }

    func resumeRecording() {
        guard isRecording, isPaused else { return }
        isWritingEnabled = true
        isPaused = false
        if let pauseStart = pauseStartTime {
            pausedDuration += Date().timeIntervalSince(pauseStart)
        }
        pauseStartTime = nil
    }

    func stopRecording() -> URL? {
        let url = audioFile?.url

        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        audioFile = nil
        onAudioBuffer = nil

        stopTimer()

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
        let url = audioFile?.url

        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        audioFile = nil
        onAudioBuffer = nil

        stopTimer()

        if let url = url {
            AudioFileManager.shared.deleteFile(at: url)
        }

        isRecording = false
        isPaused = false
        recordingTime = 0
        audioLevel = 0
    }

    // MARK: - Audio Level

    private func calculateLevel(from buffer: AVAudioPCMBuffer) {
        let frames = Int(buffer.frameLength)
        guard frames > 0 else { return }

        var sum: Float = 0

        if let channelData = buffer.floatChannelData?[0] {
            for i in 0..<frames {
                let sample = channelData[i]
                sum += sample * sample
            }
        } else if let channelData = buffer.int16ChannelData?[0] {
            for i in 0..<frames {
                let sample = Float(channelData[i]) / Float(Int16.max)
                sum += sample * sample
            }
        } else {
            return
        }

        let rms = sqrt(sum / Float(frames))
        let db = 20 * log10(max(rms, 1e-6))
        currentLevel = db
    }

    // MARK: - Timer

    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.updateRecordingTime()
            }
        }
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
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

        // 音量レベルを更新
        let level = currentLevel
        let normalizedLevel = max(0, (level + 50) / 50)
        audioLevel = normalizedLevel

        // 残り10分で警告
        if recordingTime >= warningThreshold && recordingTime < warningThreshold + 0.2 {
            onTimeWarning?()
        }

        // 上限で自動停止
        if recordingTime >= effectiveMaxDuration {
            onMaxDurationReached?()
        }
    }

    var formattedTime: String {
        let hours = Int(recordingTime) / 3600
        let minutes = (Int(recordingTime) % 3600) / 60
        let seconds = Int(recordingTime) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
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
