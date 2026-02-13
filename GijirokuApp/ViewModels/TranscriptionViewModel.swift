import Foundation

@MainActor
class TranscriptionViewModel: ObservableObject {
    @Published var isTranscribing = false
    @Published var progress: Double = 0.0
    @Published var currentText: String = ""
    @Published var segments: [TranscriptionSegment] = []
    @Published var fullText: String = ""
    @Published var errorMessage: String?
    @Published var isModelReady = false

    let transcriptionService = TranscriptionService()

    func initializeModel() async {
        do {
            try await transcriptionService.initialize()
            isModelReady = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func transcribe(audioURL: URL) async {
        isTranscribing = true
        progress = 0
        errorMessage = nil

        // 進捗を監視
        let progressTask = Task {
            while !Task.isCancelled {
                progress = transcriptionService.progress
                currentText = transcriptionService.currentText
                try? await Task.sleep(nanoseconds: 100_000_000)
            }
        }

        do {
            let result = try await transcriptionService.transcribe(audioPath: audioURL.path)
            fullText = result.text
            segments = result.segments
            progress = 1.0
        } catch {
            errorMessage = error.localizedDescription
        }

        progressTask.cancel()
        isTranscribing = false
    }

    var estimatedRemainingTime: String? {
        guard isTranscribing, progress > 0.05 else { return nil }
        // 概算のため表示は控えめに
        return "処理中..."
    }
}
