import XCTest
@testable import GijirokuApp

@MainActor
final class PlanManagerTests: XCTestCase {

    func testFreePlanDefaults() {
        let pm = PlanManager.shared
        // デフォルトはfreeプラン
        XCTAssertEqual(pm.currentPlan, .free)
    }

    func testCanStartRecordingFree() {
        let pm = PlanManager.shared
        pm.upgradeToPlan(.free)

        // リセットして0から開始
        let defaults = UserDefaults.standard
        defaults.set("9999-12", forKey: "meetingUsageData_yearMonth")
        defaults.set(0, forKey: "meetingUsageData_count")
        pm.meetingsThisMonth = 0

        XCTAssertTrue(pm.canStartRecording)
    }

    func testCannotStartRecordingOverLimit() {
        let pm = PlanManager.shared
        pm.upgradeToPlan(.free)
        pm.meetingsThisMonth = 5

        XCTAssertFalse(pm.canStartRecording)
    }

    func testStandardPlanUnlimited() {
        let pm = PlanManager.shared
        pm.upgradeToPlan(.standard)
        pm.meetingsThisMonth = 100

        XCTAssertTrue(pm.canStartRecording)
        XCTAssertTrue(pm.canUseSummarization)
        XCTAssertTrue(pm.canExportPDF)
    }

    func testFreePlanRestrictions() {
        let pm = PlanManager.shared
        pm.upgradeToPlan(.free)

        XCTAssertFalse(pm.canUseSummarization)
        XCTAssertFalse(pm.canExportPDF)
    }

    func testAvailableTemplates() {
        let pm = PlanManager.shared

        pm.upgradeToPlan(.free)
        XCTAssertEqual(pm.availableTemplates, [.simple])
        XCTAssertTrue(pm.isTemplateAvailable(.simple))
        XCTAssertFalse(pm.isTemplateAvailable(.standard))

        pm.upgradeToPlan(.standard)
        XCTAssertEqual(pm.availableTemplates.count, 4)
        XCTAssertTrue(pm.isTemplateAvailable(.standard))
        XCTAssertTrue(pm.isTemplateAvailable(.sales))
    }

    func testMaxRecordingDuration() {
        let pm = PlanManager.shared

        pm.upgradeToPlan(.free)
        XCTAssertEqual(pm.maxRecordingDuration, 30 * 60) // 30分

        pm.upgradeToPlan(.standard)
        XCTAssertEqual(pm.maxRecordingDuration, 4 * 60 * 60) // 4時間
    }

    func testRecordMeetingUsage() {
        let pm = PlanManager.shared
        pm.upgradeToPlan(.free)
        let before = pm.meetingsThisMonth
        pm.recordMeetingUsage()
        XCTAssertEqual(pm.meetingsThisMonth, before + 1)
    }

    func testRemainingFreeRecordings() {
        let pm = PlanManager.shared
        pm.upgradeToPlan(.free)
        pm.meetingsThisMonth = 3

        XCTAssertEqual(pm.remainingFreeRecordings, 2)

        pm.meetingsThisMonth = 5
        XCTAssertEqual(pm.remainingFreeRecordings, 0)

        pm.meetingsThisMonth = 10
        XCTAssertEqual(pm.remainingFreeRecordings, 0)
    }
}
