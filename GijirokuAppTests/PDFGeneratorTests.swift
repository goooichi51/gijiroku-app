import XCTest
@testable import GijirokuApp

final class PDFGeneratorTests: XCTestCase {

    private let generator = PDFGenerator()

    // MARK: - Helper

    private func makeSummary(
        rawText: String = "テスト要約",
        agenda: [String]? = nil,
        discussion: String? = nil,
        decisions: [String]? = nil,
        actionItems: [ActionItem]? = nil,
        keyPoints: [String]? = nil,
        nextActions: [String]? = nil,
        customerName: String? = nil,
        hearingNotes: String? = nil,
        proposals: [String]? = nil,
        followUpDeadline: String? = nil,
        theme: String? = nil,
        ideas: [IdeaItem]? = nil,
        nextSteps: [String]? = nil
    ) -> MeetingSummary {
        var s = MeetingSummary(rawText: rawText)
        s.agenda = agenda
        s.discussion = discussion
        s.decisions = decisions
        s.actionItems = actionItems
        s.keyPoints = keyPoints
        s.nextActions = nextActions
        s.customerName = customerName
        s.hearingNotes = hearingNotes
        s.proposals = proposals
        s.followUpDeadline = followUpDeadline
        s.theme = theme
        s.ideas = ideas
        s.nextSteps = nextSteps
        return s
    }

    // MARK: - Standard Template

    func testGeneratePDFWithStandardTemplate() {
        var meeting = Meeting(title: "定例会議", template: .standard)
        meeting.location = "会議室A"
        meeting.participants = ["田中", "佐藤"]
        meeting.summary = makeSummary(
            agenda: ["議題1", "議題2"],
            discussion: "議論内容のテスト",
            decisions: ["決定事項1"],
            actionItems: [ActionItem(assignee: "田中", task: "資料作成", deadline: "2026-02-20")]
        )

        let data = generator.generatePDF(from: meeting)
        XCTAssertGreaterThan(data.count, 0)
    }

    // MARK: - Simple Template

    func testGeneratePDFWithSimpleTemplate() {
        var meeting = Meeting(title: "簡易メモ", template: .simple)
        meeting.summary = makeSummary(
            keyPoints: ["ポイント1", "ポイント2"],
            nextActions: ["アクション1"]
        )

        let data = generator.generatePDF(from: meeting)
        XCTAssertGreaterThan(data.count, 0)
    }

    // MARK: - Sales Template

    func testGeneratePDFWithSalesTemplate() {
        var meeting = Meeting(title: "商談記録", template: .sales)
        meeting.summary = makeSummary(
            customerName: "株式会社テスト",
            hearingNotes: "ヒアリング内容",
            proposals: ["提案1"],
            followUpDeadline: "2026-03-01"
        )

        let data = generator.generatePDF(from: meeting)
        XCTAssertGreaterThan(data.count, 0)
    }

    // MARK: - Brainstorm Template

    func testGeneratePDFWithBrainstormTemplate() {
        var meeting = Meeting(title: "ブレスト会議", template: .brainstorm)
        meeting.summary = makeSummary(
            theme: "新商品企画",
            ideas: [
                IdeaItem(idea: "アイデア1", priority: "high"),
                IdeaItem(idea: "アイデア2", priority: "medium")
            ],
            nextSteps: ["次のステップ1"]
        )

        let data = generator.generatePDF(from: meeting)
        XCTAssertGreaterThan(data.count, 0)
    }

    // MARK: - No Summary

    func testGeneratePDFWithoutSummary() {
        let meeting = Meeting(title: "要約なし会議", template: .standard)
        let data = generator.generatePDF(from: meeting)
        XCTAssertGreaterThan(data.count, 0)
    }

    // MARK: - With Transcription Only

    func testGeneratePDFWithTranscriptionOnly() {
        var meeting = Meeting(title: "文字起こしのみ", template: .standard)
        meeting.transcriptionText = "本日の会議内容のテスト文字起こしテキストです。"
        let data = generator.generatePDF(from: meeting)
        XCTAssertGreaterThan(data.count, 0)
    }

    // MARK: - PDF Format Validation

    func testPDFDataStartsWithPDFHeader() {
        var meeting = Meeting(title: "PDF検証", template: .standard)
        meeting.summary = makeSummary(
            agenda: ["議題"],
            discussion: "議論",
            decisions: ["決定"]
        )

        let data = generator.generatePDF(from: meeting)
        let header = String(data: data.prefix(5), encoding: .ascii)
        XCTAssertEqual(header, "%PDF-")
    }

    // MARK: - With Metadata

    func testGeneratePDFWithFullMetadata() {
        var meeting = Meeting(title: "フルメタデータ会議", template: .standard)
        meeting.location = "本社3F大会議室"
        meeting.participants = ["田中太郎", "佐藤花子", "鈴木一郎"]
        meeting.transcriptionText = "これはテスト用のテキストです。"
        meeting.summary = makeSummary(
            agenda: ["第1議題"],
            discussion: "詳細な議論内容",
            decisions: ["決定事項"],
            actionItems: [ActionItem(assignee: "田中", task: "確認", deadline: "明日")]
        )

        let data = generator.generatePDF(from: meeting)
        XCTAssertGreaterThan(data.count, 100)
    }
}
