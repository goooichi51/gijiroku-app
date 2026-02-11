import Foundation

struct TranscriptionSegment: Identifiable, Codable, Equatable {
    let id: UUID
    var startTime: TimeInterval
    var endTime: TimeInterval
    var text: String

    init(id: UUID = UUID(), startTime: TimeInterval, endTime: TimeInterval, text: String) {
        self.id = id
        self.startTime = startTime
        self.endTime = endTime
        self.text = text
    }

    var formattedStartTime: String {
        Self.formatTime(startTime)
    }

    var formattedEndTime: String {
        Self.formatTime(endTime)
    }

    var duration: TimeInterval {
        endTime - startTime
    }

    static func formatTime(_ time: TimeInterval) -> String {
        let hours = Int(time) / 3600
        let minutes = (Int(time) % 3600) / 60
        let seconds = Int(time) % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
