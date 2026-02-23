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

    /// テンプレートに対応する構造化フィールドが存在するか
    func hasStructuredFields(for template: MeetingTemplate) -> Bool {
        switch template {
        case .standard:
            return (agenda != nil && !agenda!.isEmpty) || discussion != nil ||
                   (decisions != nil && !decisions!.isEmpty) || (actionItems != nil && !actionItems!.isEmpty)
        case .simple:
            return (keyPoints != nil && !keyPoints!.isEmpty) || (nextActions != nil && !nextActions!.isEmpty)
        case .sales:
            return customerName != nil || hearingNotes != nil ||
                   (proposals != nil && !proposals!.isEmpty) || followUpDeadline != nil
        case .brainstorm:
            return theme != nil || (ideas != nil && !ideas!.isEmpty) || (nextSteps != nil && !nextSteps!.isEmpty)
        }
    }

    /// SummaryTabViewと同じ形式の表示用テキストを生成
    func displayText(for template: MeetingTemplate, isCustomTemplate: Bool = false, customTemplateName: String? = nil) -> String {
        if isCustomTemplate {
            return "■ \(customTemplateName ?? "カスタム")\n\(rawText)"
        }

        var sections: [String] = []

        switch template {
        case .standard:
            if let agenda = agenda, !agenda.isEmpty {
                let items = agenda.enumerated().map { "\($0.offset + 1). \($0.element)" }.joined(separator: "\n")
                sections.append("■ 議題\n\(items)")
            }
            if let discussion = discussion {
                sections.append("■ 議論内容\n\(discussion)")
            }
            if let decisions = decisions, !decisions.isEmpty {
                let items = decisions.map { "・\($0)" }.joined(separator: "\n")
                sections.append("■ 決定事項\n\(items)")
            }
            if let actions = actionItems, !actions.isEmpty {
                let items = actions.map { action in
                    var text = "・\(action.assignee): \(action.task)"
                    if let deadline = action.deadline {
                        text += "（\(deadline)まで）"
                    }
                    return text
                }.joined(separator: "\n")
                sections.append("■ アクションアイテム\n\(items)")
            }

        case .simple:
            if let points = keyPoints, !points.isEmpty {
                let items = points.map { "・\($0)" }.joined(separator: "\n")
                sections.append("■ 要点まとめ\n\(items)")
            }
            if let nextActions = nextActions, !nextActions.isEmpty {
                let items = nextActions.map { "・\($0)" }.joined(separator: "\n")
                sections.append("■ 次回アクション\n\(items)")
            }

        case .sales:
            if let customer = customerName {
                sections.append("■ 顧客名\n\(customer)")
            }
            if let hearing = hearingNotes {
                sections.append("■ ヒアリング内容\n\(hearing)")
            }
            if let proposals = proposals, !proposals.isEmpty {
                let items = proposals.map { "・\($0)" }.joined(separator: "\n")
                sections.append("■ 提案事項\n\(items)")
            }
            if let deadline = followUpDeadline {
                sections.append("■ フォローアップ期限\n\(deadline)")
            }
            if let actions = actionItems, !actions.isEmpty {
                let items = actions.map { action in
                    var text = "・\(action.assignee): \(action.task)"
                    if let deadline = action.deadline {
                        text += "（\(deadline)まで）"
                    }
                    return text
                }.joined(separator: "\n")
                sections.append("■ 次回アクション\n\(items)")
            }

        case .brainstorm:
            if let theme = theme {
                sections.append("■ テーマ\n\(theme)")
            }
            if let ideas = ideas, !ideas.isEmpty {
                let items = ideas.map { idea in
                    var text = "・\(idea.idea)"
                    if let priority = idea.priority {
                        text += "（優先度: \(priority)）"
                    }
                    return text
                }.joined(separator: "\n")
                sections.append("■ アイデア一覧\n\(items)")
            }
            if let steps = nextSteps, !steps.isEmpty {
                let items = steps.map { "・\($0)" }.joined(separator: "\n")
                sections.append("■ ネクストステップ\n\(items)")
            }
        }

        // 構造化フィールドが空の場合はrawTextをフォールバック
        return sections.isEmpty ? rawText : sections.joined(separator: "\n\n")
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
