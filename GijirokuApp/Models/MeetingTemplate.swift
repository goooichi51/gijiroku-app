import Foundation

enum MeetingTemplate: String, Codable, CaseIterable, Identifiable {
    case standard
    case simple
    case sales
    case brainstorm

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .standard: return "標準"
        case .simple: return "簡易メモ"
        case .sales: return "商談・営業"
        case .brainstorm: return "ブレスト"
        }
    }

    var icon: String {
        switch self {
        case .standard: return "doc.text"
        case .simple: return "note.text"
        case .sales: return "briefcase"
        case .brainstorm: return "lightbulb"
        }
    }

    var description: String {
        switch self {
        case .standard: return "議題・議論・決定事項・アクションアイテム"
        case .simple: return "要点まとめ・次回アクション"
        case .sales: return "ヒアリング・提案・フォローアップ"
        case .brainstorm: return "アイデア一覧・評価・ネクストステップ"
        }
    }
}
