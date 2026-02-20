import XCTest
@testable import GijirokuApp

@MainActor
final class RecordingViewModelTests: XCTestCase {

    private var viewModel: RecordingViewModel!

    override func setUp() {
        super.setUp()
        viewModel = RecordingViewModel()
    }

    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }

    // MARK: - Initial State

    func testInitialState() {
        XCTAssertEqual(viewModel.state, .idle)
    }

    func testInitialAudioLevel() {
        XCTAssertEqual(viewModel.audioLevel, 0.0)
    }

    func testInitialMeetingTitle() {
        XCTAssertEqual(viewModel.meetingTitle, "")
    }

    func testInitialMeetingLocation() {
        XCTAssertEqual(viewModel.meetingLocation, "")
    }

    func testInitialMeetingParticipants() {
        XCTAssertTrue(viewModel.meetingParticipants.isEmpty)
    }

    func testInitialSecretNoteText() {
        XCTAssertEqual(viewModel.secretNoteText, "")
    }

    func testInitialIsMinimalMode() {
        XCTAssertFalse(viewModel.isMinimalMode)
    }

    func testInitialShowTimeWarning() {
        XCTAssertFalse(viewModel.showTimeWarning)
    }

    func testInitialIsNotRecording() {
        XCTAssertFalse(viewModel.isRecording)
    }

    func testInitialIsNotPaused() {
        XCTAssertFalse(viewModel.isPaused)
    }

    func testInitialShowDiscardAlert() {
        XCTAssertFalse(viewModel.showDiscardAlert)
    }

    func testInitialErrorMessage() {
        XCTAssertNil(viewModel.errorMessage)
    }

    // MARK: - Computed Properties

    func testIsRecordingWhenIdle() {
        viewModel.state = .idle
        XCTAssertFalse(viewModel.isRecording)
    }

    func testIsRecordingWhenRecording() {
        viewModel.state = .recording
        XCTAssertTrue(viewModel.isRecording)
    }

    func testIsRecordingWhenPaused() {
        viewModel.state = .paused
        XCTAssertTrue(viewModel.isRecording)
    }

    func testIsPausedWhenPaused() {
        viewModel.state = .paused
        XCTAssertTrue(viewModel.isPaused)
    }

    func testIsPausedWhenRecording() {
        viewModel.state = .recording
        XCTAssertFalse(viewModel.isPaused)
    }

    // MARK: - Discard

    func testRequestDiscard() {
        viewModel.requestDiscard()
        XCTAssertTrue(viewModel.showDiscardAlert)
    }
}
