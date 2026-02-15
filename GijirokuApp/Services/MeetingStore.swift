import Foundation

@MainActor
class MeetingStore: ObservableObject {
    @Published var meetings: [Meeting] = []

    let syncService = SyncService()
    private let storageKey = "meetings_data"
    private let userDefaults: UserDefaults

    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        load()
    }

    func load() {
        guard let data = userDefaults.data(forKey: storageKey) else { return }
        do {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            meetings = try decoder.decode([Meeting].self, from: data)
            // 保存済み議事録のステータスを補正（録音中のまま保存された場合の修正）
            for i in meetings.indices {
                let corrected = meetings[i].correctedStatus
                if corrected != meetings[i].status {
                    meetings[i].status = corrected
                }
            }
            meetings.sort { $0.date > $1.date }
        } catch {
            AppLogger.store.error("議事録データの読み込みに失敗しました: \(error.localizedDescription)")
        }
    }

    func save() {
        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            let data = try encoder.encode(meetings)
            userDefaults.set(data, forKey: storageKey)
        } catch {
            AppLogger.store.error("議事録データの保存に失敗しました: \(error.localizedDescription)")
        }
    }

    func add(_ meeting: Meeting) {
        meetings.insert(meeting, at: 0)
        save()
        Task { await syncService.uploadMeeting(meeting) }
    }

    func update(_ meeting: Meeting) {
        if let index = meetings.firstIndex(where: { $0.id == meeting.id }) {
            var updated = meeting
            updated.updatedAt = Date()
            meetings[index] = updated
            save()
            Task { await syncService.uploadMeeting(updated) }
        }
    }

    func delete(_ meeting: Meeting) {
        let id = meeting.id
        meetings.removeAll { $0.id == id }
        save()
        Task { await syncService.deleteMeeting(id: id) }
    }

    func delete(at offsets: IndexSet) {
        let ids = offsets.map { meetings[$0].id }
        meetings.remove(atOffsets: offsets)
        save()
        Task {
            for id in ids {
                await syncService.deleteMeeting(id: id)
            }
        }
    }

    func syncWithCloud() async {
        await syncService.sync(store: self)
    }

    func search(query: String) -> [Meeting] {
        guard !query.isEmpty else { return meetings }
        let lowercased = query.lowercased()
        return meetings.filter { meeting in
            meeting.title.lowercased().contains(lowercased)
            || meeting.transcriptionText?.lowercased().contains(lowercased) == true
            || meeting.summary?.rawText.lowercased().contains(lowercased) == true
            || meeting.participants.contains { $0.lowercased().contains(lowercased) }
            || meeting.location.lowercased().contains(lowercased)
        }
    }

    func meetingsThisMonth() -> Int {
        let calendar = Calendar.current
        let now = Date()
        return meetings.filter {
            calendar.isDate($0.createdAt, equalTo: now, toGranularity: .month)
        }.count
    }
}
