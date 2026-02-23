import Foundation

@MainActor
class MeetingCreationViewModel: ObservableObject {
    @Published var title = ""
    @Published var date = Date()
    @Published var location = ""
    @Published var participants: [String] = []
    @Published var selectedTemplate: MeetingTemplate = .standard
    @Published var selectedCustomTemplateId: UUID?

    @Published var isTranscribing = false
    @Published var transcriptionProgress: Double = 0.0
    @Published var transcriptionText: String?
    @Published var transcriptionSegments: [TranscriptionSegment]?
    @Published var errorMessage: String?
    @Published var isSummarizing = false
    @Published var summaryResult: MeetingSummary?
    @Published var notes: String?

    let audioFileURL: URL
    let audioDuration: TimeInterval
    private let transcriptionService = TranscriptionService()
    private let summarizationService = SummarizationService()
    private var transcriptionTask: Task<Void, Never>?

    var canGenerateSummary: Bool {
        transcriptionText != nil && !isTranscribing && !isSummarizing && summaryResult == nil && PlanManager.shared.canUseSummarization
    }

    var hasTranscription: Bool {
        transcriptionText != nil && !isTranscribing
    }

    var isProcessing: Bool {
        isTranscribing || isSummarizing
    }

    init(audioFileURL: URL, audioDuration: TimeInterval, initialTitle: String = "", initialLocation: String = "", initialParticipants: [String] = [], initialNotes: String? = nil, initialTemplate: MeetingTemplate = .standard, initialCustomTemplateId: UUID? = nil) {
        self.audioFileURL = audioFileURL
        self.audioDuration = audioDuration
        self.title = initialTitle
        self.location = initialLocation
        self.participants = initialParticipants
        self.notes = initialNotes
        self.selectedTemplate = initialTemplate
        self.selectedCustomTemplateId = initialCustomTemplateId
    }

    deinit {
        transcriptionTask?.cancel()
    }

    func startTranscription() async {
        guard !isTranscribing else { return }

        isTranscribing = true
        transcriptionProgress = 0
        errorMessage = nil

        transcriptionTask = Task {
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
                isTranscribing = false

                // 文字起こし完了後、自動でAI要約を開始
                if PlanManager.shared.canUseSummarization && !result.text.isEmpty {
                    await startSummarization()
                }
            } catch let error as TranscriptionError {
                errorMessage = error.errorDescription ?? "文字起こしに失敗しました"
                isTranscribing = false
            } catch {
                errorMessage = "文字起こしに失敗しました"
                isTranscribing = false
            }
        }
    }

    private func startSummarization() async {
        guard let text = transcriptionText else { return }

        isSummarizing = true
        errorMessage = nil

        do {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "ja_JP")
            formatter.dateFormat = "yyyy/MM/dd HH:mm"

            let metadata = MeetingMetadata(
                title: title.isEmpty ? "無題の議事録" : title,
                date: formatter.string(from: date),
                location: location,
                participants: participants,
                notes: notes
            )

            var customTemplate: CustomTemplate?
            if let customId = selectedCustomTemplateId {
                customTemplate = CustomTemplateStore.shared.template(for: customId)
            }

            let summary = try await summarizationService.summarize(
                transcription: text,
                template: selectedTemplate,
                metadata: metadata,
                customTemplate: customTemplate
            )
            summaryResult = summary
        } catch let error as SummarizationError {
            errorMessage = error.errorDescription ?? "AI要約に失敗しました"
        } catch {
            errorMessage = "AI要約に失敗しました"
        }

        isSummarizing = false
    }

    func createMeeting() -> Meeting {
        let status: MeetingStatus
        if summaryResult != nil {
            status = .completed
        } else if transcriptionText != nil {
            status = .readyForSummary
        } else {
            status = .transcribing
        }

        var meeting = Meeting(
            title: title.isEmpty ? "無題の議事録" : title,
            date: date,
            location: location,
            participants: participants,
            template: selectedTemplate,
            customTemplateId: selectedCustomTemplateId,
            status: status,
            audioFilePath: audioFileURL.path,
            audioDuration: audioDuration,
            transcriptionText: transcriptionText,
            transcriptionSegments: transcriptionSegments,
            notes: notes
        )
        meeting.summary = summaryResult
        return meeting
    }
}
