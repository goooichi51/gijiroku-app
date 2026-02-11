import Foundation

@MainActor
class MeetingCreationViewModel: ObservableObject {
    @Published var title = ""
    @Published var date = Date()
    @Published var location = ""
    @Published var participants: [String] = []
    @Published var selectedTemplate: MeetingTemplate = .standard

    @Published var isTranscribing = false
    @Published var transcriptionProgress: Double = 0.0
    @Published var transcriptionText: String?
    @Published var transcriptionSegments: [TranscriptionSegment]?
    @Published var errorMessage: String?

    let audioFileURL: URL
    let audioDuration: TimeInterval
    private let transcriptionService = TranscriptionService()

    var canGenerateSummary: Bool {
        transcriptionText != nil && !isTranscribing
    }

    init(audioFileURL: URL, audioDuration: TimeInterval) {
        self.audioFileURL = audioFileURL
        self.audioDuration = audioDuration
    }

    func startTranscription() async {
        isTranscribing = true
        transcriptionProgress = 0
        errorMessage = nil

        do {
            try await transcriptionService.initialize()

            // 進捗を監視
            let progressTask = Task {
                while !Task.isCancelled {
                    transcriptionProgress = transcriptionService.progress
                    try? await Task.sleep(nanoseconds: 200_000_000)
                }
            }

            let result = try await transcriptionService.transcribe(audioPath: audioFileURL.path)
            progressTask.cancel()

            transcriptionText = result.text
            transcriptionSegments = result.segments
            transcriptionProgress = 1.0
        } catch {
            errorMessage = error.localizedDescription
        }

        isTranscribing = false
    }

    func createMeeting() -> Meeting {
        Meeting(
            title: title.isEmpty ? "無題の議事録" : title,
            date: date,
            location: location,
            participants: participants,
            template: selectedTemplate,
            status: transcriptionText != nil ? .readyForSummary : .transcribing,
            audioFilePath: audioFileURL.path,
            audioDuration: audioDuration,
            transcriptionText: transcriptionText,
            transcriptionSegments: transcriptionSegments
        )
    }
}
