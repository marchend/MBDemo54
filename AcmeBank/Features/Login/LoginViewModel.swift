import Foundation
import Combine

/// ViewModel for the login screen.
///
/// Holds the user-editable `username` and `password` fields together with
/// transient UI state (`isLoading`, `errorMessage`).  The actual
/// authentication call is supplied by the caller via the `onSignIn` closure
/// so that the ViewModel stays testable without a real auth backend.
final class LoginViewModel: ObservableObject {

    // MARK: - Published state

    @Published var username: String = ""
    @Published var password: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String? = nil

    // MARK: - Computed helpers

    /// `true` when both fields contain at least one non-whitespace character.
    var canSignIn: Bool {
        !username.trimmingCharacters(in: .whitespaces).isEmpty &&
        !password.trimmingCharacters(in: .whitespaces).isEmpty
    }

    // MARK: - Injected sign-in handler

    /// Called with the trimmed username and password when the user taps Sign In.
    /// Defaults to a no-op stub; replace with a real auth closure at the call site.
    var onSignIn: (String, String) async throws -> Void

    // MARK: - Init

    init(onSignIn: @escaping (String, String) async throws -> Void = { _, _ in }) {
        self.onSignIn = onSignIn
    }

    // MARK: - Actions

    /// Invoked by the view when the Sign In button is tapped.
    @MainActor
    func signIn() async {
        guard canSignIn else { return }

        isLoading = true
        errorMessage = nil

        do {
            try await onSignIn(
                username.trimmingCharacters(in: .whitespaces),
                password.trimmingCharacters(in: .whitespaces)
            )
        } catch {
            // Prefer the caller-supplied, user-friendly localised description from a
            // `LocalizedError`; fall back to a generic message rather than forwarding
            // raw SDK / system error strings (e.g. NSURLErrorDomain codes) to the UI.
            errorMessage = (error as? LocalizedError)?.errorDescription
                ?? "Something went wrong. Please try again."
        }

        isLoading = false
    }
}
