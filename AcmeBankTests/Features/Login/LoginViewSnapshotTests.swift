import XCTest
import SwiftUI
@testable import AcmeBank

/// Structural tests for `LoginView`.
///
/// These tests verify that `LoginView` instantiates without crashing in each
/// significant UI state.  Full pixel-level snapshot tests require a third-party
/// library (e.g. swift-snapshot-testing) which is not yet in the project; those
/// can be layered on when the dependency is added.
@MainActor
final class LoginViewSnapshotTests: XCTestCase {

    // MARK: - Helpers

    private func makeHostingController(for view: LoginView) -> UIHostingController<LoginView> {
        let host = UIHostingController(rootView: view)
        host.view.frame = CGRect(x: 0, y: 0, width: 390, height: 844) // iPhone 14 logical pts
        host.loadViewIfNeeded()
        return host
    }

    // MARK: - Idle state

    func test_loginView_idleState_rendersWithoutCrashing() {
        let vm = LoginViewModel()
        let view = LoginView(viewModel: vm)
        let host = makeHostingController(for: view)
        XCTAssertNotNil(host.view, "LoginView in idle state should produce a non-nil UIView")
    }

    // MARK: - Loading state

    func test_loginView_loadingState_rendersWithoutCrashing() {
        let vm = LoginViewModel()
        vm.username = "alice"
        vm.password = "s3cr3t"
        vm.isLoading = true
        let view = LoginView(viewModel: vm)
        let host = makeHostingController(for: view)
        XCTAssertNotNil(host.view, "LoginView in loading state should produce a non-nil UIView")
    }

    // MARK: - Empty fields → button disabled

    func test_loginViewModel_emptyFields_canSignInIsFalse() {
        let vm = LoginViewModel()
        XCTAssertFalse(
            vm.canSignIn,
            "Sign In action must be unavailable when both fields are empty"
        )
    }

    func test_loginViewModel_filledFields_canSignInIsTrue() {
        let vm = LoginViewModel()
        vm.username = "alice"
        vm.password = "s3cr3t"
        XCTAssertTrue(
            vm.canSignIn,
            "Sign In action must be available when both fields have non-whitespace content"
        )
    }

    // MARK: - Error state

    func test_loginView_errorState_rendersWithoutCrashing() {
        let vm = LoginViewModel()
        vm.username = "alice"
        vm.password = "wrong"
        vm.errorMessage = "Invalid username or password."
        let view = LoginView(viewModel: vm)
        let host = makeHostingController(for: view)
        XCTAssertNotNil(host.view, "LoginView in error state should produce a non-nil UIView")
    }
}
