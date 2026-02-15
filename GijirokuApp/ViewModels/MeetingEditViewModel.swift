import Foundation

@MainActor
class MeetingEditViewModel: ObservableObject {
    @Published var title: String
    @Published var date: Date
    @Published var location: String
    @Published var participants: [String]
    @Published var summaryRawText: String
    @Published var saveError: String?
    @Published var isSaved = false

    private let meetingId: UUID
    private var meetingStore: MeetingStore?
    private var originalTitle: String
    private var originalLocation: String
    private var originalParticipants: [String]
    private var originalSummaryRawText: String

    var hasUnsavedChanges: Bool {
        title != originalTitle ||
        location != originalLocation ||
        participants != originalParticipants ||
        summaryRawText != originalSummaryRawText
    }

    init(meeting: Meeting) {
        self.meetingId = meeting.id
        self.title = meeting.title
        self.date = meeting.date
        self.location = meeting.location
        self.participants = meeting.participants
        self.summaryRawText = meeting.summary?.rawText ?? meeting.transcriptionText ?? ""
        self.originalTitle = meeting.title
        self.originalLocation = meeting.location
        self.originalParticipants = meeting.participants
        self.originalSummaryRawText = meeting.summary?.rawText ?? meeting.transcriptionText ?? ""
    }

    func setStore(_ store: MeetingStore) {
        self.meetingStore = store
    }

    func save() {
        saveError = nil
        guard var meeting = meetingStore?.meetings.first(where: { $0.id == meetingId }) else {
            saveError = "議事録が見つかりませんでした。削除された可能性があります。"
            return
        }
        meeting.title = title
        meeting.date = date
        meeting.location = location
        meeting.participants = participants
        if var summary = meeting.summary {
            summary.rawText = summaryRawText
            meeting.summary = summary
        }
        meetingStore?.update(meeting)
        isSaved = true
    }
}
