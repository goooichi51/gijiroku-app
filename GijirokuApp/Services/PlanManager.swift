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
        let savedMonth = defaults.integer(forKey: "\(usageKey)_month")
        let currentMonth = Calendar.current.component(.month, from: Date())

        if savedMonth == currentMonth {
            meetingsThisMonth = defaults.integer(forKey: "\(usageKey)_count")
        } else {
            // 月が変わったらリセット
            meetingsThisMonth = 0
            saveUsageData()
        }
    }

    private func saveUsageData() {
        let defaults = UserDefaults.standard
        let currentMonth = Calendar.current.component(.month, from: Date())
        defaults.set(currentMonth, forKey: "\(usageKey)_month")
        defaults.set(meetingsThisMonth, forKey: "\(usageKey)_count")
    }

    func upgradeToPlan(_ plan: SubscriptionPlan) {
        currentPlan = plan
        UserDefaults.standard.set(plan.rawValue, forKey: "currentPlan")
    }
}
