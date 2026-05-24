import XCTest
@testable import AcmeBank

@MainActor
final class LoginViewModelTests: XCTestCase {

    // MARK: - canSignIn (field validation)

    func test_canSignIn_falseWhenBothFieldsEmpty() {
        let vm = LoginViewModel()
        XCTAssertFalse(vm.canSignIn)
    }

    func test_canSignIn_falseWhenUsernameEmptyPasswordFilled() {
        let vm = LoginViewModel()
        vm.password = "s3cr3t"
        XCTAssertFalse(vm.canSignIn)
    }

    func test_canSignIn_falseWhenPasswordEmptyUsernameFilled() {
        let vm = LoginViewModel()
        vm.username = "alice"
        XCTAssertFalse(vm.canSignIn)
    }

    func test_canSignIn_falseWhenFieldsContainOnlyWhitespace() {
        let vm = LoginViewModel()
        vm.username = "   "
        vm.password = "   "
        XCTAssertFalse(vm.canSignIn)
    }

    func test_canSignIn_trueWhenBothFieldsNonEmpty() {
        let vm = LoginViewModel()
        vm.username = "alice"
        vm.password = "s3cr3t"
        XCTAssertTrue(vm.canSignIn)
    }

    // MARK: - signIn (isLoading toggling)

    func test_signIn_doesNothingWhenFieldsEmpty() async {
        var wasCalled = false
        let vm = LoginViewModel { _, _ in wasCalled = true }
        await vm.signIn()
        XCTAssertFalse(wasCalled, "onSignIn must not be called when fields are empty")
        XCTAssertFalse(vm.isLoading)
    }

    func test_signIn_setsIsLoadingTrueThenFalse() async {
        let vm = LoginViewModel { _, _ in
            // We can't observe mid-flight in a purely synchronous way,
            // but we verify that isLoading returns to false after completion.
        }
        vm.username = "alice"
        vm.password = "s3cr3t"
        await vm.signIn()
        XCTAssertFalse(vm.isLoading, "isLoading must be false after signIn completes")
    }

    func test_signIn_invokesOnSignInWithTrimmedCredentials() async {
        var receivedUsername: String?
        var receivedPassword: String?

        let vm = LoginViewModel { username, password in
            receivedUsername = username
            receivedPassword = password
        }
        vm.username = "  alice  "
        vm.password = "  s3cr3t  "

        await vm.signIn()

        XCTAssertEqual(receivedUsername, "alice")
        XCTAssertEqual(receivedPassword, "s3cr3t")
    }

    // MARK: - signIn (error handling)

    func test_signIn_setsErrorMessageOnFailure() async {
        struct AuthError: Error, LocalizedError {
            var errorDescription: String? { "Invalid credentials" }
        }

        let vm = LoginViewModel { _, _ in throw AuthError() }
        vm.username = "alice"
        vm.password = "wrong"

        await vm.signIn()

        XCTAssertEqual(vm.errorMessage, "Invalid credentials")
        XCTAssertFalse(vm.isLoading)
    }

    func test_signIn_clearsErrorMessageOnSuccess() async {
        let vm = LoginViewModel { _, _ in }
        vm.username = "alice"
        vm.password = "s3cr3t"
        vm.errorMessage = "Previous error"

        await vm.signIn()

        XCTAssertNil(vm.errorMessage, "errorMessage should be cleared on successful sign-in")
    }

    func test_signIn_isLoadingFalseAfterError() async {
        let vm = LoginViewModel { _, _ in throw URLError(.notConnectedToInternet) }
        vm.username = "alice"
        vm.password = "s3cr3t"

        await vm.signIn()

        XCTAssertFalse(vm.isLoading, "isLoading must reset to false even when sign-in throws")
    }
}
