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
        metadata: MeetingMetadata
    ) async throws -> MeetingSummary {
        isSummarizing = true
        errorMessage = nil
        defer { isSummarizing = false }

        guard NetworkMonitor.shared.isConnected else {
            throw SummarizationError.networkError("インターネット接続がありません。Wi-Fiまたはモバイルデータを確認してください。")
        }

        let prompt = PromptTemplates.buildPrompt(
            template: template,
            metadata: metadata
        )

        let requestBody = SummarizeRequest(
            prompt: prompt,
            transcription: transcription
        )

        var lastError: Error?
        for attempt in 0...maxRetries {
            do {
                let response: SummarizeResponse = try await SupabaseManager.shared.client
                    .functions
                    .invoke(
                        "summarize",
                        options: .init(body: requestBody)
                    )
                return parseSummary(response.summary, template: template)
            } catch {
                lastError = error
                if attempt < maxRetries {
                    try await Task.sleep(for: .seconds(Double(attempt + 1) * 2))
                }
            }
        }

        throw lastError ?? SummarizationError.networkError("AI要約の生成に失敗しました。しばらくしてからお試しください。")
    }

    private func parseSummary(_ jsonString: String, template: MeetingTemplate) -> MeetingSummary {
        var summary = MeetingSummary(rawText: jsonString)

        guard let data = jsonString.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
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
    case networkError(String)
    case parseError
    case notAuthenticated

    var errorDescription: String? {
        switch self {
        case .networkError(let detail):
            return "AI要約の生成に失敗しました: \(detail)"
        case .parseError:
            return "AI要約の結果を解析できませんでした。"
        case .notAuthenticated:
            return "ログインが必要です。"
        }
    }
}
