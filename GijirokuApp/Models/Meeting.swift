import Foundation

struct Meeting: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var date: Date
    var location: String
    var participants: [String]
    var template: MeetingTemplate
    var status: MeetingStatus
    var audioFilePath: String?
    var audioDuration: TimeInterval?
    var transcriptionText: String?
    var transcriptionSegments: [TranscriptionSegment]?
    var summary: MeetingSummary?
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String = "",
        date: Date = Date(),
        location: String = "",
        participants: [String] = [],
        template: MeetingTemplate = .standard,
        status: MeetingStatus = .recording,
        audioFilePath: String? = nil,
        audioDuration: TimeInterval? = nil,
        transcriptionText: String? = nil,
        transcriptionSegments: [TranscriptionSegment]? = nil,
        summary: MeetingSummary? = nil,
        createdAt: Date = Date(),
        updatedAt: Date = Date()
    ) {
        self.id = id
        self.title = title
        self.date = date
        self.location = location
        self.participants = participants
        self.template = template
        self.status = status
        self.audioFilePath = audioFilePath
        self.audioDuration = audioDuration
        self.transcriptionText = transcriptionText
        self.transcriptionSegments = transcriptionSegments
        self.summary = summary
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var searchableText: String {
        [title, location, participants.joined(separator: " "), transcriptionText, summary?.rawText]
            .compactMap { $0 }
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }

    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ja_JP")
        formatter.dateFormat = "yyyy/MM/dd HH:mm"
        return formatter.string(from: date)
    }

    var formattedDuration: String {
        guard let duration = audioDuration else { return "" }
        let minutes = Int(duration) / 60
        if minutes >= 60 {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            return "\(hours)時間\(remainingMinutes)分"
        }
        return "\(minutes)分"
    }
}
