import Foundation

@MainActor
class HomeViewModel: ObservableObject {
    @Published var showRecording = false
    @Published var showMeetingCreation = false
    @Published var recordedAudioURL: URL?
    @Published var recordedDuration: TimeInterval = 0

    func onRecordingComplete(url: URL, duration: TimeInterval) {
        recordedAudioURL = url
        recordedDuration = duration
        showRecording = false
        showMeetingCreation = true
    }
}
