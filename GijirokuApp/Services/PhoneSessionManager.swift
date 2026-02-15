import WatchConnectivity
import Foundation

@MainActor
class PhoneSessionManager: NSObject, ObservableObject {
    static let shared = PhoneSessionManager()

    @Published var receivedAudioURL: URL?
    @Published var receivedDuration: TimeInterval = 0
    @Published var hasNewRecording = false

    private override init() {
        super.init()
    }

    func activate() {
        guard WCSession.isSupported() else { return }
        WCSession.default.delegate = self
        WCSession.default.activate()
    }
}

// MARK: - WCSessionDelegate

extension PhoneSessionManager: WCSessionDelegate {
    nonisolated func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        if let error = error {
            AppLogger.watch.error("WCSession activation failed: \(error.localizedDescription)")
        }
    }

    nonisolated func sessionDidBecomeInactive(_ session: WCSession) {}
    nonisolated func sessionDidDeactivate(_ session: WCSession) {
        session.activate()
    }

    // Watch から転送されたファイルを受信
    nonisolated func session(_ session: WCSession, didReceive file: WCSessionFile) {
        let metadata = file.metadata ?? [:]
        let duration = metadata["duration"] as? TimeInterval ?? 0

        // 録音ファイルをアプリのドキュメントディレクトリにコピー
        let fileName = "watch_\(UUID().uuidString).m4a"
        let destURL = AudioFileManager.shared.recordingsDirectory.appendingPathComponent(fileName)

        do {
            try FileManager.default.copyItem(at: file.fileURL, to: destURL)
            Task { @MainActor in
                self.receivedAudioURL = destURL
                self.receivedDuration = duration
                self.hasNewRecording = true
            }
        } catch {
            AppLogger.watch.error("Watch録音ファイルのコピーに失敗: \(error.localizedDescription)")
        }
    }
}
