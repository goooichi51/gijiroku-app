import Foundation

@MainActor
class MeetingDetailViewModel: ObservableObject {
    @Published var meeting: Meeting
    @Published var selectedTab: DetailTab = .summary

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
}
