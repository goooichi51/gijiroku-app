import Foundation

@MainActor
class MeetingEditViewModel: ObservableObject {
    @Published var title: String
    @Published var date: Date
    @Published var location: String
    @Published var participants: [String]
    @Published var summaryDisplayText: String
    @Published var saveError: String?
    @Published var isSaved = false

    private let meetingId: UUID
    private var meetingStore: MeetingStore?
    private var originalTitle: String
    private var originalLocation: String
    private var originalParticipants: [String]
    private var originalSummaryDisplayText: String

    var hasUnsavedChanges: Bool {
        title != originalTitle ||
        location != originalLocation ||
        participants != originalParticipants ||
        summaryDisplayText != originalSummaryDisplayText
    }

    init(meeting: Meeting) {
        self.meetingId = meeting.id
        self.title = meeting.title
        self.date = meeting.date
        self.location = meeting.location
        self.participants = meeting.participants

        // 要約タブと同じ形式の表示用テキストを生成
        let displayText: String
        if let summary = meeting.summary {
            displayText = summary.displayText(
                for: meeting.template,
                isCustomTemplate: meeting.isCustomTemplate,
                customTemplateName: meeting.effectiveTemplateName
            )
        } else {
            displayText = meeting.transcriptionText ?? ""
        }
        self.summaryDisplayText = displayText
        self.originalTitle = meeting.title
        self.originalLocation = meeting.location
        self.originalParticipants = meeting.participants
        self.originalSummaryDisplayText = displayText
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
        if meeting.summary != nil {
            // 手動編集後は構造化フィールドをクリアし、編集テキストをrawTextに保存
            var summary = MeetingSummary(rawText: summaryDisplayText)
            summary.rawText = summaryDisplayText
            meeting.summary = summary
        }
        meetingStore?.update(meeting)
        isSaved = true
    }
}
