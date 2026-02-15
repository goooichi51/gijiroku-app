import AVFoundation
import Combine

class WatchAudioRecorder: NSObject, ObservableObject {
    @Published var isRecording = false
    @Published var isPaused = false
    @Published var recordingTime: TimeInterval = 0
    @Published var audioLevel: Float = 0
    @Published var errorMessage: String?

    private var audioRecorder: AVAudioRecorder?
    private var timer: Timer?
    private var startTime: Date?
    private var accumulatedTime: TimeInterval = 0

    // 最大4時間
    let maxDuration: TimeInterval = 4 * 60 * 60
    // 30分ごとの確認間隔
    let checkInterval: TimeInterval = 30 * 60

    var formattedTime: String {
        let hours = Int(recordingTime) / 3600
        let minutes = (Int(recordingTime) % 3600) / 60
        let seconds = Int(recordingTime) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }

    var shouldShowContinuationPrompt: Bool {
        guard recordingTime > 0 else { return false }
        let intervals = Int(recordingTime / checkInterval)
        let lastCheckpoint = Double(intervals) * checkInterval
        return recordingTime >= lastCheckpoint && recordingTime - lastCheckpoint < 1.0 && intervals > 0
    }

    private var recordingURL: URL? {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first
        return dir?.appendingPathComponent("watch_recording_\(UUID().uuidString).m4a")
    }

    func startRecording() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.record, mode: .default)
            try session.setActive(true)
        } catch {
            errorMessage = "オーディオセッションの設定に失敗しました"
            return
        }

        guard let url = recordingURL else {
            errorMessage = "録音ファイルのパスを作成できませんでした"
            return
        }

        // MPEG4AAC, 44100Hz, モノラル
        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.record()
            isRecording = true
            isPaused = false
            startTime = Date()
            accumulatedTime = 0
            startTimer()
        } catch {
            errorMessage = "録音の開始に失敗しました: \(error.localizedDescription)"
        }
    }

    func pauseRecording() {
        audioRecorder?.pause()
        isPaused = true
        accumulatedTime = recordingTime
        startTime = nil
    }

    func resumeRecording() {
        audioRecorder?.record()
        isPaused = false
        startTime = Date()
    }

    func stopRecording() -> URL? {
        let url = audioRecorder?.url
        audioRecorder?.stop()
        timer?.invalidate()
        timer = nil
        isRecording = false
        isPaused = false
        recordingTime = 0
        accumulatedTime = 0
        startTime = nil

        do {
            try AVAudioSession.sharedInstance().setActive(false)
        } catch {
            print("オーディオセッションの停止に失敗: \(error)")
        }

        return url
    }

    func cancelRecording() {
        if let url = audioRecorder?.url {
            audioRecorder?.stop()
            try? FileManager.default.removeItem(at: url)
        }
        timer?.invalidate()
        timer = nil
        isRecording = false
        isPaused = false
        recordingTime = 0
        accumulatedTime = 0
        startTime = nil
    }

    private func startTimer() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            if !self.isPaused, let start = self.startTime {
                self.recordingTime = self.accumulatedTime + Date().timeIntervalSince(start)
            }

            self.audioRecorder?.updateMeters()
            let power = self.audioRecorder?.averagePower(forChannel: 0) ?? -160
            // -160〜0 dB を 0〜1 に正規化
            self.audioLevel = max(0, min(1, (power + 50) / 50))

            // 最大時間チェック
            if self.recordingTime >= self.maxDuration {
                _ = self.stopRecording()
            }
        }
    }
}
