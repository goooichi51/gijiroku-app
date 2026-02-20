import Foundation

enum SubscriptionPlan: String, Codable {
    case free
    case standard
}

@MainActor
class PlanManager: ObservableObject {
    static let shared = PlanManager()

    @Published var currentPlan: SubscriptionPlan = .free
    @Published var meetingsThisMonth: Int = 0

    private let maxFreeRecordings = 5
    private let maxFreeRecordingDuration: TimeInterval = 30 * 60 // 30分

    private init() {
        if let saved = UserDefaults.standard.string(forKey: "currentPlan"),
           let plan = SubscriptionPlan(rawValue: saved) {
            currentPlan = plan
        }
        loadUsageData()
    }

    // MARK: - プラン制限チェック

    var canStartRecording: Bool {
        currentPlan == .standard || meetingsThisMonth < maxFreeRecordings
    }

    var remainingFreeRecordings: Int {
        max(0, maxFreeRecordings - meetingsThisMonth)
    }

    var maxRecordingDuration: TimeInterval {
        currentPlan == .standard ? AudioRecorderService.maxDuration : maxFreeRecordingDuration
    }

    var canUseSummarization: Bool {
        currentPlan == .standard
    }

    var canExportPDF: Bool {
        currentPlan == .standard
    }

    var availableTemplates: [MeetingTemplate] {
        switch currentPlan {
        case .free:
            return [.simple]
        case .standard:
            return MeetingTemplate.allCases.map { $0 }
        }
    }

    func isTemplateAvailable(_ template: MeetingTemplate) -> Bool {
        availableTemplates.contains(template)
    }

    // MARK: - 利用記録

    func recordMeetingUsage() {
        meetingsThisMonth += 1
        saveUsageData()
    }

    // MARK: - 永続化

    private let usageKey = "meetingUsageData"

    private func loadUsageData() {
        let defaults = UserDefaults.standard
        let savedYearMonth = defaults.string(forKey: "\(usageKey)_yearMonth") ?? ""
        let currentYearMonth = Self.currentYearMonth()

        if savedYearMonth == currentYearMonth {
            meetingsThisMonth = defaults.integer(forKey: "\(usageKey)_count")
        } else {
            meetingsThisMonth = 0
            saveUsageData()
        }
    }

    private func saveUsageData() {
        let defaults = UserDefaults.standard
        defaults.set(Self.currentYearMonth(), forKey: "\(usageKey)_yearMonth")
        defaults.set(meetingsThisMonth, forKey: "\(usageKey)_count")
    }

    private static func currentYearMonth() -> String {
        let cal = Calendar.current
        let now = Date()
        let year = cal.component(.year, from: now)
        let month = cal.component(.month, from: now)
        return "\(year)-\(month)"
    }

    func upgradeToPlan(_ plan: SubscriptionPlan) {
        currentPlan = plan
        UserDefaults.standard.set(plan.rawValue, forKey: "currentPlan")
    }
}
