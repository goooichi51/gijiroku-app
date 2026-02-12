import AVFoundation
import WhisperKit

@MainActor
class LiveTranscriptionManager: ObservableObject {
    @Published var liveText: String = ""
    @Published var isActive = false

    private var audioEngine: AVAudioEngine?
    private var audioSamples: [Float] = []
    private var transcriptionTimer: Timer?
    private var whisperKit: WhisperKit?
    private var isProcessing = false

    private let sampleRate: Double = 16000
    private let transcriptionInterval: TimeInterval = 15
    // 最後に文字起こし済みのサンプル位置
    private var lastTranscribedSampleCount: Int = 0
    private var allTranscribedText: String = ""

    func start(whisperKit: WhisperKit?) async {
        guard let whisperKit = whisperKit else { return }
        self.whisperKit = whisperKit
        audioSamples = []
        lastTranscribedSampleCount = 0
        allTranscribedText = ""
        liveText = ""
        isActive = true

        setupAudioEngine()
        startTranscriptionTimer()
    }

    func stop() {
        isActive = false
        transcriptionTimer?.invalidate()
        transcriptionTimer = nil

        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil
        audioSamples = []
    }

    private func setupAudioEngine() {
        audioEngine = AVAudioEngine()
        guard let engine = audioEngine else { return }

        let inputNode = engine.inputNode
        let recordingFormat = AVAudioFormat(
            commonFormat: .pcmFormatFloat32,
            sampleRate: sampleRate,
            channels: 1,
            interleaved: false
        )!

        // 入力フォーマットに合わせてコンバータを使う
        let inputFormat = inputNode.outputFormat(forBus: 0)

        // コンバータが必要な場合に対応
        if inputFormat.sampleRate != sampleRate || inputFormat.channelCount != 1 {
            inputNode.installTap(onBus: 0, bufferSize: 4096, format: inputFormat) { [weak self] buffer, _ in
                self?.processBuffer(buffer, inputSampleRate: inputFormat.sampleRate)
            }
        } else {
            inputNode.installTap(onBus: 0, bufferSize: 4096, format: recordingFormat) { [weak self] buffer, _ in
                self?.appendSamples(from: buffer)
            }
        }

        do {
            try engine.start()
        } catch {
            print("AudioEngine起動失敗: \(error.localizedDescription)")
        }
    }

    private func processBuffer(_ buffer: AVAudioPCMBuffer, inputSampleRate: Double) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameCount = Int(buffer.frameLength)

        // ダウンサンプリング（簡易版）
        let ratio = inputSampleRate / sampleRate
        var resampled: [Float] = []
        resampled.reserveCapacity(Int(Double(frameCount) / ratio))

        var index: Double = 0
        while Int(index) < frameCount {
            resampled.append(channelData[Int(index)])
            index += ratio
        }

        Task { @MainActor in
            self.audioSamples.append(contentsOf: resampled)
        }
    }

    private func appendSamples(from buffer: AVAudioPCMBuffer) {
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameCount = Int(buffer.frameLength)
        let samples = Array(UnsafeBufferPointer(start: channelData, count: frameCount))

        Task { @MainActor in
            self.audioSamples.append(contentsOf: samples)
        }
    }

    private func startTranscriptionTimer() {
        transcriptionTimer = Timer.scheduledTimer(
            withTimeInterval: transcriptionInterval,
            repeats: true
        ) { [weak self] _ in
            Task { @MainActor [weak self] in
                await self?.transcribeLatestChunk()
            }
        }
    }

    private func transcribeLatestChunk() async {
        guard !isProcessing, isActive, let whisperKit = whisperKit else { return }

        let currentSampleCount = audioSamples.count
        // 最低2秒分のサンプルが溜まってから処理
        let minSamples = Int(sampleRate * 2)
        guard currentSampleCount - lastTranscribedSampleCount >= minSamples else { return }

        isProcessing = true
        defer { isProcessing = false }

        // 全体の音声を渡して文字起こし（累積方式）
        let samplesToTranscribe = Array(audioSamples.prefix(currentSampleCount))

        let options = DecodingOptions(
            task: .transcribe,
            language: "ja",
            temperature: 0.0,
            usePrefillPrompt: true,
            skipSpecialTokens: true,
            noSpeechThreshold: 0.6
        )

        do {
            let results = try await whisperKit.transcribe(
                audioArray: samplesToTranscribe,
                decodeOptions: options
            )

            let text = results.map { $0.text }.joined()
            if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                allTranscribedText = text
                liveText = allTranscribedText
                lastTranscribedSampleCount = currentSampleCount
            }
        } catch {
            print("リアルタイム文字起こしエラー: \(error.localizedDescription)")
        }
    }
}
