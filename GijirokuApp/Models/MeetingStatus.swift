import Foundation

enum MeetingStatus: String, Codable {
    case recording
    case transcribing
    case readyForSummary
    case summarizing
    case completed

    var displayName: String {
        switch self {
        case .recording: return "録音中"
        case .transcribing: return "文字起こし中"
        case .readyForSummary: return "要約待ち"
        case .summarizing: return "要約生成中"
        case .completed: return "保存済み"
        }
    }

    var isProcessing: Bool {
        switch self {
        case .recording, .transcribing, .summarizing:
            return true
        case .readyForSummary, .completed:
            return false
        }
    }
}
