import Foundation
import WhisperKit

@MainActor
class TranscriptionService: ObservableObject {
    @Published var isTranscribing = false
    @Published var progress: Double = 0.0
    @Published var currentText: String = ""

    private var whisperKit: WhisperKit?

    var isModelLoaded: Bool {
        whisperKit != nil
    }

    func initialize(modelName: String? = nil) async throws {
        let config = WhisperKitConfig(
            model: modelName,
            verbose: true,
            logLevel: .info,
            prewarm: true,
            load: true,
            download: true
        )
        whisperKit = try await WhisperKit(config)
    }

    func transcribe(audioPath: String) async throws -> (text: String, segments: [TranscriptionSegment]) {
        guard let whisperKit = whisperKit else {
            throw TranscriptionError.notInitialized
        }

        isTranscribing = true
        progress = 0.0
        currentText = ""
        defer {
            isTranscribing = false
            progress = 1.0
        }

        let options = DecodingOptions(
            task: .transcribe,
            language: "ja",
            temperature: 0.0,
            usePrefillPrompt: true,
            skipSpecialTokens: true,
            noSpeechThreshold: 0.6,
            chunkingStrategy: .vad
        )

        let results = try await whisperKit.transcribe(
            audioPath: audioPath,
            decodeOptions: options,
            callback: { [weak self] progressInfo in
                Task { @MainActor [weak self] in
                    self?.currentText = progressInfo.text
                    // progressInfoのテキスト長から概算進捗を計算
                    if !progressInfo.text.isEmpty {
                        self?.progress = min(0.95, (self?.progress ?? 0) + 0.01)
                    }
                }
                return nil
            }
        )

        let fullText = results.map { $0.text }.joined()
        let segments = results.flatMap { result in
            result.segments.map { segment in
                TranscriptionSegment(
                    startTime: TimeInterval(segment.start),
                    endTime: TimeInterval(segment.end),
                    text: segment.text.trimmingCharacters(in: .whitespacesAndNewlines)
                )
            }
        }

        return (fullText, segments)
    }

    func unloadModel() {
        whisperKit = nil
    }
}

// MARK: - Errors

enum TranscriptionError: LocalizedError {
    case notInitialized
    case transcriptionFailed(String)
    case modelDownloadFailed

    var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "AIモデルが初期化されていません。設定画面からモデルをダウンロードしてください。"
        case .transcriptionFailed(let detail):
            return "文字起こしに失敗しました: \(detail)"
        case .modelDownloadFailed:
            return "AIモデルのダウンロードに失敗しました。Wi-Fi接続を確認してください。"
        }
    }
}
