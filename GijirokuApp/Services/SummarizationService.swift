import Foundation
import Supabase

@MainActor
class SummarizationService: ObservableObject {
    @Published var isSummarizing = false
    @Published var errorMessage: String?

    private let maxRetries = 2

    func summarize(
        transcription: String,
        template: MeetingTemplate,
        metadata: MeetingMetadata,
        customTemplate: CustomTemplate? = nil
    ) async throws -> MeetingSummary {
        isSummarizing = true
        errorMessage = nil
        defer { isSummarizing = false }

        guard NetworkMonitor.shared.isConnected else {
            throw SummarizationError.offline
        }

        let prompt: String
        if let custom = customTemplate {
            prompt = PromptTemplates.buildCustomPrompt(
                customTemplate: custom,
                metadata: metadata
            )
        } else {
            prompt = PromptTemplates.buildPrompt(
                template: template,
                metadata: metadata
            )
        }

        let requestBody = SummarizeRequest(
            prompt: prompt,
            transcription: transcription
        )

        // 文字起こしが空の場合はエラー
        guard !transcription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            throw SummarizationError.emptyTranscription
        }

        var lastError: Error?
        for attempt in 0...maxRetries {
            do {
                let response: SummarizeResponse = try await SupabaseManager.shared.client
                    .functions
                    .invoke(
                        "summarize",
                        options: .init(body: requestBody)
                    )
                if customTemplate != nil {
                    return MeetingSummary(rawText: response.summary)
                }
                return parseSummary(response.summary, template: template)
            } catch {
                lastError = error
                if attempt < maxRetries {
                    try await Task.sleep(for: .seconds(Double(attempt + 1) * 2))
                }
            }
        }

        // Supabase SDKの英語エラーを日本語に変換
        throw mapToLocalizedError(lastError)
    }

    private func parseSummary(_ jsonString: String, template: MeetingTemplate) -> MeetingSummary {
        var summary = MeetingSummary(rawText: jsonString)

        guard let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            // JSON解析失敗時は生テキストを保持しつつエラーをログ
            AppLogger.summarization.warning("AI要約のJSON解析に失敗しました。生テキストとして保存します。")
            errorMessage = "AI要約の構造化に失敗しましたが、テキストとして保存しました"
            return summary
        }

        switch template {
        case .standard:
            summary.agenda = json["agenda"] as? [String]
            summary.discussion = json["discussion"] as? String
            summary.decisions = json["decisions"] as? [String]
            summary.actionItems = parseActionItems(json["actionItems"])

        case .simple:
            summary.keyPoints = json["keyPoints"] as? [String]
            summary.nextActions = json["nextActions"] as? [String]

        case .sales:
            summary.customerName = json["customerName"] as? String
            summary.hearingNotes = json["hearingNotes"] as? String
            summary.proposals = json["proposals"] as? [String]
            summary.followUpDeadline = json["followUpDeadline"] as? String
            summary.actionItems = parseActionItems(json["actionItems"])

        case .brainstorm:
            summary.theme = json["theme"] as? String
            summary.ideas = parseIdeas(json["ideas"])
            summary.nextSteps = json["nextSteps"] as? [String]
        }

        return summary
    }

    private func mapToLocalizedError(_ error: Error?) -> SummarizationError {
        guard let error else { return .serverError }
        let message = error.localizedDescription
        if message.contains("400") {
            return .badRequest
        } else if message.contains("401") || message.contains("403") {
            return .notAuthenticated
        } else if message.contains("429") {
            return .rateLimited
        } else if message.contains("500") || message.contains("502") || message.contains("503") {
            return .serverError
        }
        return .serverError
    }

    private func parseActionItems(_ value: Any?) -> [ActionItem]? {
        guard let items = value as? [[String: Any]] else { return nil }
        return items.compactMap { item in
            guard let assignee = item["assignee"] as? String,
                  let task = item["task"] as? String else { return nil }
            return ActionItem(
                assignee: assignee,
                task: task,
                deadline: item["deadline"] as? String
            )
        }
    }

    private func parseIdeas(_ value: Any?) -> [IdeaItem]? {
        guard let items = value as? [[String: Any]] else { return nil }
        return items.compactMap { item in
            guard let idea = item["idea"] as? String else { return nil }
            return IdeaItem(
                idea: idea,
                priority: item["priority"] as? String
            )
        }
    }
}

// MARK: - API Models

struct SummarizeRequest: Encodable {
    let prompt: String
    let transcription: String
}

struct SummarizeResponse: Decodable {
    let summary: String
}

// MARK: - Errors

enum SummarizationError: LocalizedError {
    case offline
    case serverError
    case parseError
    case notAuthenticated
    case networkError(String)
    case badRequest
    case rateLimited
    case emptyTranscription

    var errorDescription: String? {
        switch self {
        case .offline:
            return "インターネットに接続されていません"
        case .serverError:
            return "サーバーとの通信に失敗しました"
        case .parseError:
            return "AI要約の結果を解析できませんでした"
        case .notAuthenticated:
            return "ログインが必要です"
        case .networkError:
            return "ネットワークエラーが発生しました"
        case .badRequest:
            return "AI要約のリクエストに失敗しました"
        case .rateLimited:
            return "リクエスト回数の上限に達しました"
        case .emptyTranscription:
            return "文字起こしデータがないため要約できません"
        }
    }

    var recoverySuggestion: String? {
        switch self {
        case .offline:
            return "Wi-Fiまたはモバイルデータ通信を確認してください。"
        case .serverError:
            return "しばらくしてからもう一度お試しください。"
        case .parseError:
            return "再度AI要約を実行してください。問題が続く場合はテンプレートを変更してお試しください。"
        case .notAuthenticated:
            return "設定画面からログインしてください。"
        case .networkError:
            return "しばらくしてからもう一度お試しください。"
        case .badRequest:
            return "文字起こしデータが正しく送信されませんでした。再度録音してお試しください。"
        case .rateLimited:
            return "しばらくしてからもう一度お試しください。"
        case .emptyTranscription:
            return "録音してから再度お試しください。"
        }
    }
}
