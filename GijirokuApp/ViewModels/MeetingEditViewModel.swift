import Foundation

@MainActor
class MeetingEditViewModel: ObservableObject {
    @Published var title: String
    @Published var date: Date
    @Published var location: String
    @Published var participants: [String]
    @Published var summaryRawText: String

    private let meetingId: UUID
    private var meetingStore: MeetingStore?

    init(meeting: Meeting) {
        self.meetingId = meeting.id
        self.title = meeting.title
        self.date = meeting.date
        self.location = meeting.location
        self.participants = meeting.participants
        self.summaryRawText = meeting.summary?.rawText ?? meeting.transcriptionText ?? ""
    }

    func setStore(_ store: MeetingStore) {
        self.meetingStore = store
    }

    func save() {
        guard var meeting = meetingStore?.meetings.first(where: { $0.id == meetingId }) else { return }
        meeting.title = title
        meeting.date = date
        meeting.location = location
        meeting.participants = participants
        if var summary = meeting.summary {
            summary.rawText = summaryRawText
            meeting.summary = summary
        }
        meetingStore?.update(meeting)
    }
}
