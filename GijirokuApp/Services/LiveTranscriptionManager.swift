import Foundation
import Speech
import AVFoundation

@MainActor
class LiveTranscriptionManager: ObservableObject {
    @Published var liveText: String = ""
    @Published var isActive = false

    private var analyzer: SpeechAnalyzer?
    private var transcriber: SpeechTranscriber?
    private var audioEngine: AVAudioEngine?
    private var transcriptionTask: Task<Void, Never>?

    func start() async {
        guard !isActive else { return }

        liveText = ""
        isActive = true

        let transcriber = SpeechTranscriber(
            locale: Locale(identifier: "ja-JP"),
            preset: .progressiveTranscription
        )
        self.transcriber = transcriber

        let analyzer = SpeechAnalyzer(modules: [transcriber])
        self.analyzer = analyzer

        // マイク音声をAsyncStreamとしてSpeechAnalyzerに流す
        let audioEngine = AVAudioEngine()
        self.audioEngine = audioEngine

        let inputNode = audioEngine.inputNode
        let audioFormat = await SpeechAnalyzer.bestAvailableAudioFormat(
            compatibleWith: [transcriber],
            considering: inputNode.outputFormat(forBus: 0)
        )
        guard let format = audioFormat else {
            isActive = false
            return
        }

        let (stream, continuation) = AsyncStream<AnalyzerInput>.makeStream()

        inputNode.installTap(onBus: 0, bufferSize: 4096, format: format) { buffer, _ in
            continuation.yield(AnalyzerInput(buffer: buffer))
        }

        do {
            try audioEngine.start()
        } catch {
            print("AudioEngine起動失敗: \(error.localizedDescription)")
            isActive = false
            return
        }

        // SpeechAnalyzerに音声ストリームを供給
        Task {
            do {
                try await analyzer.start(inputSequence: stream)
            } catch {
                if !Task.isCancelled {
                    print("SpeechAnalyzer入力エラー: \(error.localizedDescription)")
                }
            }
        }

        // 文字起こし結果を受け取る
        transcriptionTask = Task {
            do {
                for try await result in transcriber.results {
                    guard !Task.isCancelled else { break }
                    let text = String(result.text.characters)
                    if !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                        liveText = text
                    }
                }
            } catch {
                if !Task.isCancelled {
                    print("リアルタイム文字起こしエラー: \(error.localizedDescription)")
                }
            }

            await MainActor.run {
                self.isActive = false
            }
        }
    }

    func stop() {
        transcriptionTask?.cancel()
        transcriptionTask = nil

        audioEngine?.inputNode.removeTap(onBus: 0)
        audioEngine?.stop()
        audioEngine = nil

        Task {
            await analyzer?.cancelAndFinishNow()
        }
        analyzer = nil
        transcriber = nil
        isActive = false
    }
}
