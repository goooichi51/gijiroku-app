import Foundation

class AudioFileManager {
    static let shared = AudioFileManager()

    private let fileManager = FileManager.default

    private var recordingsDirectory: URL {
        let documentsURL = fileManager.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let recordingsURL = documentsURL.appendingPathComponent("Recordings", isDirectory: true)
        if !fileManager.fileExists(atPath: recordingsURL.path) {
            try? fileManager.createDirectory(at: recordingsURL, withIntermediateDirectories: true)
        }
        return recordingsURL
    }

    func generateRecordingURL() -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let fileName = "recording_\(formatter.string(from: Date())).wav"
        return recordingsDirectory.appendingPathComponent(fileName)
    }

    func deleteFile(at url: URL) {
        try? fileManager.removeItem(at: url)
    }

    func fileExists(at path: String) -> Bool {
        fileManager.fileExists(atPath: path)
    }

    func fileSize(at url: URL) -> Int64? {
        guard let attrs = try? fileManager.attributesOfItem(atPath: url.path),
              let size = attrs[.size] as? Int64 else {
            return nil
        }
        return size
    }

    func audioDuration(at url: URL) -> TimeInterval? {
        // AVAudioFileではなくファイルサイズから計算（PCM: 16kHz, 16bit, 1ch）
        guard let size = fileSize(at: url) else { return nil }
        let headerSize: Int64 = 44 // WAVヘッダー
        let dataSize = size - headerSize
        let bytesPerSecond: Int64 = 16000 * 2 * 1 // サンプルレート × バイト深度 × チャンネル
        return TimeInterval(dataSize) / TimeInterval(bytesPerSecond)
    }

    func allRecordings() -> [URL] {
        guard let files = try? fileManager.contentsOfDirectory(
            at: recordingsDirectory,
            includingPropertiesForKeys: [.creationDateKey],
            options: .skipsHiddenFiles
        ) else {
            return []
        }
        return files.filter { $0.pathExtension == "wav" }
            .sorted { url1, url2 in
                let date1 = (try? url1.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                let date2 = (try? url2.resourceValues(forKeys: [.creationDateKey]).creationDate) ?? Date.distantPast
                return date1 > date2
            }
    }

    func deleteAllRecordings() {
        for url in allRecordings() {
            deleteFile(at: url)
        }
    }
}
