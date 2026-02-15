import XCTest
@testable import GijirokuApp

final class StoreKitManagerTests: XCTestCase {

    // MARK: - StoreError

    func testStoreErrorFailedVerificationDescription() {
        let error = StoreError.failedVerification
        XCTAssertEqual(error.errorDescription, "購入の検証に失敗しました")
    }

    func testStoreErrorPurchaseFailedDescription() {
        let error = StoreError.purchaseFailed("テスト理由")
        XCTAssertEqual(error.errorDescription, "購入に失敗しました: テスト理由")
    }

    func testStoreErrorConformsToLocalizedError() {
        let error: LocalizedError = StoreError.failedVerification
        XCTAssertNotNil(error.errorDescription)
    }

    // MARK: - StoreKitManager Constants

    func testStandardMonthlyProductID() {
        XCTAssertEqual(StoreKitManager.standardMonthlyID, "com.gijiroku.app.standard.monthly")
    }

    // MARK: - SummarizationError

    func testSummarizationErrorOffline() {
        let error = SummarizationError.offline
        XCTAssertEqual(error.errorDescription, "インターネットに接続されていません")
        XCTAssertNotNil(error.recoverySuggestion)
    }

    func testSummarizationErrorServerError() {
        let error = SummarizationError.serverError
        XCTAssertEqual(error.errorDescription, "サーバーとの通信に失敗しました")
        XCTAssertNotNil(error.recoverySuggestion)
    }

    func testSummarizationErrorParseError() {
        let error = SummarizationError.parseError
        XCTAssertEqual(error.errorDescription, "AI要約の結果を解析できませんでした")
        XCTAssertNotNil(error.recoverySuggestion)
    }

    func testSummarizationErrorNotAuthenticated() {
        let error = SummarizationError.notAuthenticated
        XCTAssertEqual(error.errorDescription, "ログインが必要です")
        XCTAssertNotNil(error.recoverySuggestion)
    }

    func testSummarizationErrorNetworkError() {
        let error = SummarizationError.networkError("タイムアウト")
        XCTAssertEqual(error.errorDescription, "タイムアウト")
    }

    // MARK: - RecordingError

    func testRecordingErrorMicrophonePermission() {
        let error = RecordingError.microphonePermissionDenied
        XCTAssertTrue(error.errorDescription!.contains("マイク"))
    }

    func testRecordingErrorFailedToStart() {
        let error = RecordingError.failedToStart
        XCTAssertTrue(error.errorDescription!.contains("録音"))
    }

    func testRecordingErrorNoActiveRecording() {
        let error = RecordingError.noActiveRecording
        XCTAssertTrue(error.errorDescription!.contains("録音中"))
    }
}
