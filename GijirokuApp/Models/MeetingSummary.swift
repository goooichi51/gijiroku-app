import Foundation

struct MeetingSummary: Codable, Equatable {
    // 標準テンプレート
    var agenda: [String]?
    var discussion: String?
    var decisions: [String]?
    var actionItems: [ActionItem]?

    // 簡易メモテンプレート
    var keyPoints: [String]?
    var nextActions: [String]?

    // 商談・営業テンプレート
    var customerName: String?
    var hearingNotes: String?
    var proposals: [String]?
    var followUpDeadline: String?

    // ブレストテンプレート
    var theme: String?
    var ideas: [IdeaItem]?
    var nextSteps: [String]?

    // 共通: AI出力の生テキスト（編集用）
    var rawText: String

    init(rawText: String) {
        self.rawText = rawText
    }
}

struct ActionItem: Identifiable, Codable, Equatable {
    let id: UUID
    var assignee: String
    var task: String
    var deadline: String?
    var isCompleted: Bool

    init(id: UUID = UUID(), assignee: String, task: String, deadline: String? = nil, isCompleted: Bool = false) {
        self.id = id
        self.assignee = assignee
        self.task = task
        self.deadline = deadline
        self.isCompleted = isCompleted
    }
}

struct IdeaItem: Identifiable, Codable, Equatable {
    let id: UUID
    var idea: String
    var priority: String?

    init(id: UUID = UUID(), idea: String, priority: String? = nil) {
        self.id = id
        self.idea = idea
        self.priority = priority
    }
}
