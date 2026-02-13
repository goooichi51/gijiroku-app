import Foundation
import Speech
import AVFoundation

@MainActor
class TranscriptionService: ObservableObject {
    @Published var isTranscribing = false
    @Published var progress: Double = 0.0
    @Published var currentText: String = ""

    private var analyzer: SpeechAnalyzer?
    private var isReady = false

    func initialize() async throws {
        let status = SFSpeechRecognizer.authorizationStatus()
        if status == .notDetermined {
            let granted = await withCheckedContinuation { continuation in
                SFSpeechRecognizer.requestAuthorization { status in
                    continuation.resume(returning: status == .authorized)
                }
            }
            guard granted else {
                throw TranscriptionError.permissionDenied
            }
        } else if status != .authorized {
            throw TranscriptionError.permissionDenied
        }
        isReady = true
    }

    func transcribe(audioPath: String) async throws -> (text: String, segments: [TranscriptionSegment]) {
        guard isReady else {
            throw TranscriptionError.notInitialized
        }

        let audioURL = URL(fileURLWithPath: audioPath)
        guard FileManager.default.fileExists(atPath: audioPath) else {
            throw TranscriptionError.transcriptionFailed("音声ファイルが見つかりません")
        }

        isTranscribing = true
        progress = 0.0
        currentText = ""
        defer {
            isTranscribing = false
            progress = 1.0
            analyzer = nil
        }

        let transcriber = SpeechTranscriber(
            locale: Locale(identifier: "ja-JP"),
            preset: .timeIndexedTranscriptionWithAlternatives
        )

        let audioFile = try AVAudioFile(forReading: audioURL)
        let analyzer = try await SpeechAnalyzer(
            inputAudioFile: audioFile,
            modules: [transcriber],
            finishAfterFile: true
        )
        self.analyzer = analyzer

        var allText = ""
        var allSegments: [TranscriptionSegment] = []
        var segmentIndex = 0

        do {
            for try await result in transcriber.results {
                let text = String(result.text.characters)
                guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { continue }

                let startTime = CMTimeGetSeconds(result.range.start)
                let endTime = CMTimeGetSeconds(CMTimeAdd(result.range.start, result.range.duration))

                allText += text
                allSegments.append(TranscriptionSegment(
                    startTime: startTime,
                    endTime: endTime,
                    text: text.trimmingCharacters(in: .whitespacesAndNewlines)
                ))
                segmentIndex += 1
                currentText = allText
                progress = min(0.95, Double(segmentIndex) * 0.05)
            }
        } catch {
            throw TranscriptionError.transcriptionFailed(error.localizedDescription)
        }

        return (allText, allSegments)
    }

    func cancel() {
        Task {
            await analyzer?.cancelAndFinishNow()
        }
        analyzer = nil
    }
}

// MARK: - Errors

enum TranscriptionError: LocalizedError {
    case notInitialized
    case permissionDenied
    case transcriptionFailed(String)

    var errorDescription: String? {
        switch self {
        case .notInitialized:
            return "音声認識が初期化されていません。"
        case .permissionDenied:
            return "音声認識の権限が許可されていません。設定アプリから許可してください。"
        case .transcriptionFailed(let detail):
            return "文字起こしに失敗しました: \(detail)"
        }
    }
}
