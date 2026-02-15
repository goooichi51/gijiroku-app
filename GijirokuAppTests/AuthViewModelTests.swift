import XCTest
@testable import GijirokuApp

@MainActor
final class AuthViewModelTests: XCTestCase {

    private var viewModel: AuthViewModel!

    override func setUp() {
        super.setUp()
        viewModel = AuthViewModel()
    }

    override func tearDown() {
        viewModel = nil
        super.tearDown()
    }

    // MARK: - Initial State

    func testInitialState() {
        XCTAssertEqual(viewModel.email, "")
        XCTAssertEqual(viewModel.password, "")
        XCTAssertFalse(viewModel.isSignUp)
        XCTAssertFalse(viewModel.isLoading)
    }

    // MARK: - Email Validation

    func testValidEmail() {
        viewModel.email = "user@example.com"
        XCTAssertTrue(viewModel.isEmailValid)
    }

    func testEmailWithoutAt() {
        viewModel.email = "userexample.com"
        XCTAssertFalse(viewModel.isEmailValid)
    }

    func testEmailWithoutDot() {
        viewModel.email = "user@example"
        XCTAssertFalse(viewModel.isEmailValid)
    }

    func testEmailTooShort() {
        viewModel.email = "a@b"
        XCTAssertFalse(viewModel.isEmailValid)
    }

    func testEmptyEmail() {
        viewModel.email = ""
        XCTAssertFalse(viewModel.isEmailValid)
    }

    // MARK: - Form Validation

    func testFormValidWithValidEmailAndPassword() {
        viewModel.email = "user@example.com"
        viewModel.password = "password123"
        XCTAssertTrue(viewModel.isFormValid)
    }

    func testFormInvalidWithShortPassword() {
        viewModel.email = "user@example.com"
        viewModel.password = "12345"
        XCTAssertFalse(viewModel.isFormValid)
    }

    func testFormInvalidWithInvalidEmail() {
        viewModel.email = "invalid"
        viewModel.password = "password123"
        XCTAssertFalse(viewModel.isFormValid)
    }

    func testFormInvalidWithBothInvalid() {
        viewModel.email = ""
        viewModel.password = ""
        XCTAssertFalse(viewModel.isFormValid)
    }

    func testPasswordExactlySixChars() {
        viewModel.email = "user@example.com"
        viewModel.password = "123456"
        XCTAssertTrue(viewModel.isFormValid)
    }

    func testPasswordFiveChars() {
        viewModel.email = "user@example.com"
        viewModel.password = "12345"
        XCTAssertFalse(viewModel.isFormValid)
    }
}
