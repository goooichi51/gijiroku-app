import OSLog

enum AppLogger {
    static let recording = Logger(subsystem: "com.gijiroku.app", category: "recording")
    static let transcription = Logger(subsystem: "com.gijiroku.app", category: "transcription")
    static let sync = Logger(subsystem: "com.gijiroku.app", category: "sync")
    static let store = Logger(subsystem: "com.gijiroku.app", category: "store")
    static let storeKit = Logger(subsystem: "com.gijiroku.app", category: "storekit")
    static let audio = Logger(subsystem: "com.gijiroku.app", category: "audio")
    static let watch = Logger(subsystem: "com.gijiroku.app", category: "watch")
    static let summarization = Logger(subsystem: "com.gijiroku.app", category: "summarization")
}
