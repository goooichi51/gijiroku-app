import Foundation
import Supabase

// Supabase DB用のデータ転送モデル
struct MeetingRecord: Codable {
    let id: UUID
    let userId: UUID
    let title: String
    let date: Date
    let location: String
    let participants: [String]
    let template: String
    let status: String
    let audioDuration: Double?
    let transcriptionText: String?
    let customTemplateId: UUID?
    let transcriptionSegmentsJson: String?
    let summaryRawText: String?
    let summaryJson: String?
    let notes: String?
    let createdAt: Date
    let updatedAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case title, date, location, participants, template, status, notes
        case audioDuration = "audio_duration"
        case customTemplateId = "custom_template_id"
        case transcriptionText = "transcription_text"
        case transcriptionSegmentsJson = "transcription_segments_json"
        case summaryRawText = "summary_raw_text"
        case summaryJson = "summary_json"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
}

@MainActor
class SyncService: ObservableObject {
    @Published var isSyncing = false
    @Published var lastSyncDate: Date?
    @Published var syncError: String?

    private var client: SupabaseClient { SupabaseManager.shared.client }
    private let tableName = "meetings"

    // MARK: - ローカル → リモート アップロード

    func uploadMeeting(_ meeting: Meeting) async {
        guard let userId = await currentUserId() else { return }

        let record = meetingToRecord(meeting, userId: userId)

        do {
            try await client.from(tableName)
                .upsert(record)
                .execute()
        } catch {
            syncError = "同期に失敗しました: \(error.localizedDescription)"
            AppLogger.sync.error("アップロードエラー: \(error)")
        }
    }

    // MARK: - リモート → ローカル ダウンロード

    func fetchMeetings() async -> [Meeting] {
        guard await currentUserId() != nil else { return [] }

        do {
            let records: [MeetingRecord] = try await client.from(tableName)
                .select()
                .order("updated_at", ascending: false)
                .execute()
                .value

            return records.map { recordToMeeting($0) }
        } catch {
            syncError = "データの取得に失敗しました: \(error.localizedDescription)"
            AppLogger.sync.error("ダウンロードエラー: \(error)")
            return []
        }
    }

    // MARK: - 全データ同期

    func sync(store: MeetingStore) async {
        isSyncing = true
        syncError = nil
        defer { isSyncing = false }

        guard let userId = await currentUserId() else {
            syncError = "ログインが必要です"
            return
        }

        // ローカルのデータをアップロード
        var uploadFailCount = 0
        for meeting in store.meetings {
            let record = meetingToRecord(meeting, userId: userId)
            do {
                try await client.from(tableName)
                    .upsert(record)
                    .execute()
            } catch {
                uploadFailCount += 1
                AppLogger.sync.error("同期エラー (id: \(meeting.id)): \(error.localizedDescription)")
            }
        }
        if uploadFailCount > 0 {
            syncError = "\(uploadFailCount)件の議事録のアップロードに失敗しました"
        }

        // リモートからダウンロードしてマージ
        do {
            let records: [MeetingRecord] = try await client.from(tableName)
                .select()
                .order("updated_at", ascending: false)
                .execute()
                .value

            let remoteMeetings = records.map { recordToMeeting($0) }

            // リモートにあってローカルにないものを追加
            for remote in remoteMeetings {
                if let localIndex = store.meetings.firstIndex(where: { $0.id == remote.id }) {
                    // 更新日時が新しい方を採用
                    if remote.updatedAt > store.meetings[localIndex].updatedAt {
                        store.meetings[localIndex] = remote
                    }
                } else {
                    store.meetings.append(remote)
                }
            }

            store.meetings.sort { $0.date > $1.date }
            store.save()
            lastSyncDate = Date()
        } catch {
            syncError = "同期に失敗しました: \(error.localizedDescription)"
            AppLogger.sync.error("同期エラー: \(error)")
        }
    }

    // MARK: - リモート削除

    func deleteMeeting(id: UUID) async {
        do {
            try await client.from(tableName)
                .delete()
                .eq("id", value: id.uuidString)
                .execute()
        } catch {
            AppLogger.sync.error("リモート削除エラー: \(error.localizedDescription)")
        }
    }

    // MARK: - ユーティリティ

    private func currentUserId() async -> UUID? {
        do {
            let session = try await client.auth.session
            return session.user.id
        } catch {
            return nil
        }
    }

    private func meetingToRecord(_ meeting: Meeting, userId: UUID) -> MeetingRecord {
        let encoder = JSONEncoder()

        var summaryJson: String?
        if let summary = meeting.summary,
           let data = try? encoder.encode(summary) {
            summaryJson = String(data: data, encoding: .utf8)
        }

        var segmentsJson: String?
        if let segments = meeting.transcriptionSegments,
           let data = try? encoder.encode(segments) {
            segmentsJson = String(data: data, encoding: .utf8)
        }

        let syncText = UserDefaults.standard.bool(forKey: "syncTranscriptionToCloud")

        return MeetingRecord(
            id: meeting.id,
            userId: userId,
            title: meeting.title,
            date: meeting.date,
            location: meeting.location,
            participants: meeting.participants,
            template: meeting.template.rawValue,
            status: meeting.status.rawValue,
            audioDuration: meeting.audioDuration,
            transcriptionText: syncText ? meeting.transcriptionText : nil,
            customTemplateId: meeting.customTemplateId,
            transcriptionSegmentsJson: syncText ? segmentsJson : nil,
            summaryRawText: syncText ? meeting.summary?.rawText : nil,
            summaryJson: syncText ? summaryJson : nil,
            notes: meeting.notes,
            createdAt: meeting.createdAt,
            updatedAt: meeting.updatedAt
        )
    }

    private func recordToMeeting(_ record: MeetingRecord) -> Meeting {
        let decoder = JSONDecoder()

        var summary: MeetingSummary?
        if let jsonString = record.summaryJson,
           let data = jsonString.data(using: .utf8) {
            summary = try? decoder.decode(MeetingSummary.self, from: data)
        } else if let rawText = record.summaryRawText {
            summary = MeetingSummary(rawText: rawText)
        }

        var segments: [TranscriptionSegment]?
        if let jsonString = record.transcriptionSegmentsJson,
           let data = jsonString.data(using: .utf8) {
            segments = try? decoder.decode([TranscriptionSegment].self, from: data)
        }

        var meeting = Meeting(
            id: record.id,
            title: record.title,
            date: record.date,
            location: record.location,
            participants: record.participants,
            template: MeetingTemplate(rawValue: record.template) ?? .standard,
            customTemplateId: record.customTemplateId,
            status: MeetingStatus(rawValue: record.status) ?? .completed,
            audioFilePath: nil,
            audioDuration: record.audioDuration,
            transcriptionText: record.transcriptionText,
            transcriptionSegments: segments,
            summary: summary,
            notes: record.notes,
            createdAt: record.createdAt,
            updatedAt: record.updatedAt
        )
        meeting.status = meeting.correctedStatus
        return meeting
    }
}
