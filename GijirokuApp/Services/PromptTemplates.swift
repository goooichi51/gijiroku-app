import Foundation

enum PromptTemplates {
    static func buildPrompt(
        template: MeetingTemplate,
        metadata: MeetingMetadata
    ) -> String {
        var base = """
        あなたは議事録作成のプロフェッショナルです。
        以下の文字起こしテキストから、指定されたJSON形式で議事録を作成してください。
        日本語で、丁寧語（です・ます調）で記述してください。
        必ず有効なJSONのみを出力してください。マークダウンや説明文は不要です。

        会議情報:
        - タイトル: \(metadata.title)
        - 日時: \(metadata.date)
        - 場所: \(metadata.location)
        - 参加者: \(metadata.participants.joined(separator: ", "))

        重要な指示:
        - 会議のタイトルを踏まえて、その主題に沿った要約を作成してください。
        - 参加者名が提供されている場合、発言内容やアクションアイテムの担当者として積極的に使用してください。文字起こしで「私」「自分」などの不明確な表現があれば、文脈から参加者名に置き換えてください。
        """

        if let notes = metadata.notes, !notes.isEmpty {
            base += "\n\n    記録者のメモ（要約に反映してください）:\n    \(notes)"
        }

        switch template {
        case .standard:
            return base + standardFormat
        case .simple:
            return base + simpleFormat
        case .sales:
            return base + salesFormat
        case .brainstorm:
            return base + brainstormFormat
        }
    }

    static func buildCustomPrompt(
        customTemplate: CustomTemplate,
        metadata: MeetingMetadata
    ) -> String {
        var base = """
        あなたは議事録作成のプロフェッショナルです。
        以下の文字起こしテキストから議事録を作成してください。
        日本語で、丁寧語（です・ます調）で記述してください。

        会議情報:
        - タイトル: \(metadata.title)
        - 日時: \(metadata.date)
        - 場所: \(metadata.location)
        - 参加者: \(metadata.participants.joined(separator: ", "))

        重要な指示:
        - 会議のタイトルを踏まえて、その主題に沿った要約を作成してください。
        - 参加者名が提供されている場合、発言内容やアクションアイテムの担当者として積極的に使用してください。文字起こしで「私」「自分」などの不明確な表現があれば、文脈から参加者名に置き換えてください。
        """

        if let notes = metadata.notes, !notes.isEmpty {
            base += "\n\n    記録者のメモ（要約に反映してください）:\n    \(notes)"
        }

        base += """

        \n    出力形式の指示:
            \(customTemplate.promptFormat)
        """
        return base
    }

    private static let standardFormat = """

    以下のJSON形式で出力してください:
    {
      "agenda": ["議題1", "議題2"],
      "discussion": "議論内容の要約テキスト",
      "decisions": ["決定事項1", "決定事項2"],
      "actionItems": [
        {"assignee": "担当者名", "task": "タスク内容", "deadline": "期限"}
      ]
    }
    """

    private static let simpleFormat = """

    以下のJSON形式で出力してください:
    {
      "keyPoints": ["要点1", "要点2", "要点3"],
      "nextActions": ["次回アクション1", "次回アクション2"]
    }
    """

    private static let salesFormat = """

    以下のJSON形式で出力してください:
    {
      "customerName": "顧客名",
      "hearingNotes": "ヒアリング内容の要約",
      "proposals": ["提案事項1", "提案事項2"],
      "followUpDeadline": "フォローアップ期限",
      "actionItems": [
        {"assignee": "担当者名", "task": "タスク内容", "deadline": "期限"}
      ]
    }
    """

    private static let brainstormFormat = """

    以下のJSON形式で出力してください:
    {
      "theme": "ブレストのテーマ",
      "ideas": [
        {"idea": "アイデア内容", "priority": "高/中/低"}
      ],
      "nextSteps": ["ネクストステップ1", "ネクストステップ2"]
    }
    """
}

struct MeetingMetadata {
    let title: String
    let date: String
    let location: String
    let participants: [String]
    var notes: String?
}
