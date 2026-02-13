import Foundation

@MainActor
class MeetingDetailViewModel: ObservableObject {
    @Published var meeting: Meeting
    @Published var selectedTab: DetailTab = .summary
    @Published var isSummarizing = false
    @Published var summarizationError: String?

    private let summarizationService = SummarizationService()

    enum DetailTab {
        case summary
        case fullText
    }

    init(meeting: Meeting) {
        self.meeting = meeting
    }

    var hasSummary: Bool {
        meeting.summary != nil
    }

    var hasTranscription: Bool {
        meeting.transcriptionText != nil
    }

    var canGenerateSummary: Bool {
        hasTranscription && !hasSummary && !isSummarizing && PlanManager.shared.canUseSummarization
    }

    func generateSummary() async {
        guard let text = meeting.transcriptionText else { return }

        isSummarizing = true
        summarizationError = nil

        do {
            let metadata = MeetingMetadata(
                title: meeting.title,
                date: meeting.formattedDate,
                location: meeting.location,
                participants: meeting.participants
            )
            let summary = try await summarizationService.summarize(
                transcription: text,
                template: meeting.template,
                metadata: metadata
            )
            meeting.summary = summary
            meeting.status = .completed
        } catch {
            summarizationError = error.localizedDescription
        }

        isSummarizing = false
    }
}
