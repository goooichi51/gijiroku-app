import XCTest
@testable import GijirokuApp

final class MeetingModelTests: XCTestCase {

    // MARK: - Meeting Codable

    func testMeetingCodableRoundTrip() throws {
        let meeting = Meeting(
            title: "週次定例会議",
            date: Date(timeIntervalSince1970: 1707660000),
            location: "会議室A",
            participants: ["田中", "鈴木", "佐藤"],
            template: .standard,
            status: .completed,
            audioDuration: 2700,
            transcriptionText: "テスト文字起こしテキスト"
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(meeting)

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let decoded = try decoder.decode(Meeting.self, from: data)

        XCTAssertEqual(meeting.id, decoded.id)
        XCTAssertEqual(meeting.title, decoded.title)
        XCTAssertEqual(meeting.location, decoded.location)
        XCTAssertEqual(meeting.participants, decoded.participants)
        XCTAssertEqual(meeting.template, decoded.template)
        XCTAssertEqual(meeting.status, decoded.status)
        XCTAssertEqual(meeting.audioDuration, decoded.audioDuration)
        XCTAssertEqual(meeting.transcriptionText, decoded.transcriptionText)
    }

    func testMeetingFormattedDuration() {
        var meeting = Meeting()

        meeting.audioDuration = 2700 // 45分
        XCTAssertEqual(meeting.formattedDuration, "45分")

        meeting.audioDuration = 5400 // 1時間30分
        XCTAssertEqual(meeting.formattedDuration, "1時間30分")

        meeting.audioDuration = nil
        XCTAssertEqual(meeting.formattedDuration, "")
    }

    // MARK: - MeetingTemplate

    func testMeetingTemplateAllCases() {
        let templates = MeetingTemplate.allCases
        XCTAssertEqual(templates.count, 4)
        XCTAssertTrue(templates.contains(.standard))
        XCTAssertTrue(templates.contains(.simple))
        XCTAssertTrue(templates.contains(.sales))
        XCTAssertTrue(templates.contains(.brainstorm))
    }

    func testMeetingTemplateDisplayNames() {
        XCTAssertEqual(MeetingTemplate.standard.displayName, "標準")
        XCTAssertEqual(MeetingTemplate.simple.displayName, "簡易メモ")
        XCTAssertEqual(MeetingTemplate.sales.displayName, "商談・営業")
        XCTAssertEqual(MeetingTemplate.brainstorm.displayName, "ブレスト")
    }

    // MARK: - MeetingStatus

    func testMeetingStatusIsProcessing() {
        XCTAssertTrue(MeetingStatus.recording.isProcessing)
        XCTAssertTrue(MeetingStatus.transcribing.isProcessing)
        XCTAssertTrue(MeetingStatus.summarizing.isProcessing)
        XCTAssertFalse(MeetingStatus.readyForSummary.isProcessing)
        XCTAssertFalse(MeetingStatus.completed.isProcessing)
    }

    // MARK: - TranscriptionSegment

    func testTranscriptionSegmentFormatTime() {
        let segment = TranscriptionSegment(
            startTime: 72.5,
            endTime: 85.0,
            text: "テストテキスト"
        )

        XCTAssertEqual(segment.formattedStartTime, "01:12")
        XCTAssertEqual(segment.formattedEndTime, "01:25")
        XCTAssertEqual(segment.duration, 12.5)
    }

    func testTranscriptionSegmentFormatTimeWithHours() {
        let segment = TranscriptionSegment(
            startTime: 3661,
            endTime: 3722,
            text: "テスト"
        )

        XCTAssertEqual(segment.formattedStartTime, "1:01:01")
        XCTAssertEqual(segment.formattedEndTime, "1:02:02")
    }

    // MARK: - MeetingSummary

    func testMeetingSummaryCodable() throws {
        var summary = MeetingSummary(rawText: "テスト要約テキスト")
        summary.agenda = ["議題1", "議題2"]
        summary.decisions = ["決定事項1"]
        summary.actionItems = [
            ActionItem(assignee: "田中", task: "タスク1", deadline: "3/15")
        ]

        let encoder = JSONEncoder()
        let data = try encoder.encode(summary)
        let decoded = try JSONDecoder().decode(MeetingSummary.self, from: data)

        XCTAssertEqual(decoded.rawText, "テスト要約テキスト")
        XCTAssertEqual(decoded.agenda, ["議題1", "議題2"])
        XCTAssertEqual(decoded.decisions, ["決定事項1"])
        XCTAssertEqual(decoded.actionItems?.count, 1)
        XCTAssertEqual(decoded.actionItems?.first?.assignee, "田中")
    }
}

// MARK: - MeetingStore Tests

@MainActor
final class MeetingStoreTests: XCTestCase {

    private var store: MeetingStore!
    private var testDefaults: UserDefaults!

    override func setUp() {
        super.setUp()
        testDefaults = UserDefaults(suiteName: "test_meeting_store")!
        testDefaults.removePersistentDomain(forName: "test_meeting_store")
        store = MeetingStore(userDefaults: testDefaults)
    }

    override func tearDown() {
        testDefaults.removePersistentDomain(forName: "test_meeting_store")
        super.tearDown()
    }

    func testAddMeeting() {
        let meeting = Meeting(title: "テスト会議")
        store.add(meeting)

        XCTAssertEqual(store.meetings.count, 1)
        XCTAssertEqual(store.meetings.first?.title, "テスト会議")
    }

    func testUpdateMeeting() {
        var meeting = Meeting(title: "テスト会議")
        store.add(meeting)

        meeting.title = "更新後の会議名"
        store.update(meeting)

        XCTAssertEqual(store.meetings.count, 1)
        XCTAssertEqual(store.meetings.first?.title, "更新後の会議名")
    }

    func testDeleteMeeting() {
        let meeting = Meeting(title: "テスト会議")
        store.add(meeting)
        XCTAssertEqual(store.meetings.count, 1)

        store.delete(meeting)
        XCTAssertEqual(store.meetings.count, 0)
    }

    func testSearchByTitle() {
        store.add(Meeting(title: "週次定例会議"))
        store.add(Meeting(title: "クライアントA商談"))
        store.add(Meeting(title: "ブレスト会議"))

        let results = store.search(query: "会議")
        XCTAssertEqual(results.count, 2)
    }

    func testSearchByParticipant() {
        store.add(Meeting(title: "会議1", participants: ["田中", "鈴木"]))
        store.add(Meeting(title: "会議2", participants: ["佐藤"]))

        let results = store.search(query: "田中")
        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.title, "会議1")
    }

    func testSearchEmptyQuery() {
        store.add(Meeting(title: "会議1"))
        store.add(Meeting(title: "会議2"))

        let results = store.search(query: "")
        XCTAssertEqual(results.count, 2)
    }

    func testPersistence() {
        store.add(Meeting(title: "永続化テスト"))

        // 新しいStoreインスタンスで読み込み
        let newStore = MeetingStore(userDefaults: testDefaults)
        XCTAssertEqual(newStore.meetings.count, 1)
        XCTAssertEqual(newStore.meetings.first?.title, "永続化テスト")
    }

    func testMeetingsThisMonth() {
        store.add(Meeting(title: "今月の会議"))

        // 先月の会議
        var oldMeeting = Meeting(title: "先月の会議")
        let calendar = Calendar.current
        if let lastMonth = calendar.date(byAdding: .month, value: -1, to: Date()) {
            oldMeeting.createdAt = lastMonth
        }
        store.meetings.append(oldMeeting)
        store.save()

        XCTAssertEqual(store.meetingsThisMonth(), 1)
    }
}
