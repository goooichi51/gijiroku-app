import WatchConnectivity

class WatchSessionManager: NSObject, ObservableObject {
    static let shared = WatchSessionManager()

    @Published var isReachable = false
    @Published var isTransferring = false
    @Published var transferProgress: Double = 0
    @Published var transferError: String?
    @Published var lastTransferSuccess = false

    private var activeTransfer: WCSessionFileTransfer?

    private override init() {
        super.init()
        if WCSession.isSupported() {
            WCSession.default.delegate = self
            WCSession.default.activate()
        }
    }

    func transferAudioFile(at url: URL, duration: TimeInterval) {
        guard WCSession.default.activationState == .activated else {
            transferError = "iPhoneとの接続が確立されていません"
            return
        }

        isTransferring = true
        transferProgress = 0
        transferError = nil
        lastTransferSuccess = false

        let metadata: [String: Any] = [
            "type": "audio_recording",
            "duration": duration,
            "timestamp": Date().timeIntervalSince1970,
            "format": "m4a"
        ]

        activeTransfer = WCSession.default.transferFile(url, metadata: metadata)
    }
}

// MARK: - WCSessionDelegate

extension WatchSessionManager: WCSessionDelegate {
    func session(_ session: WCSession, activationDidCompleteWith activationState: WCSessionActivationState, error: Error?) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }
    }

    func sessionReachabilityDidChange(_ session: WCSession) {
        DispatchQueue.main.async {
            self.isReachable = session.isReachable
        }
    }

    func session(_ session: WCSession, didFinish fileTransfer: WCSessionFileTransfer, error: Error?) {
        DispatchQueue.main.async {
            self.isTransferring = false
            if let error = error {
                self.transferError = "転送に失敗しました: \(error.localizedDescription)"
                self.lastTransferSuccess = false
            } else {
                self.transferProgress = 1.0
                self.lastTransferSuccess = true
                // 転送完了後にローカルファイルを削除
                try? FileManager.default.removeItem(at: fileTransfer.file.fileURL)
            }
        }
    }
}
