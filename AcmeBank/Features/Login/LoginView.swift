import SwiftUI

/// Login screen — collects credentials and hands them off to `LoginViewModel`.
///
/// Design contract:
/// - Logo / app name at the top
/// - Username and password fields
/// - Sign In button disabled while fields are empty or a request is in flight
/// - Inline error banner when `viewModel.errorMessage` is non-nil
/// - Spinner overlay while `viewModel.isLoading` is `true`
struct LoginView: View {

    @StateObject var viewModel: LoginViewModel

    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            VStack(spacing: 32) {
                Spacer()

                // MARK: Logo / brand
                VStack(spacing: 8) {
                    Image(systemName: "building.columns.fill")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 72, height: 72)
                        .foregroundColor(.accentColor)
                        .accessibilityIdentifier("brandLogo")

                    Text("AcmeBank")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .accessibilityIdentifier("brandName")
                }

                // MARK: Fields
                VStack(spacing: 16) {
                    TextField("Username", text: $viewModel.username)
                        .textContentType(.username)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                        .accessibilityIdentifier("usernameField")

                    SecureField("Password", text: $viewModel.password)
                        .textContentType(.password)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                        .accessibilityIdentifier("passwordField")
                }
                .padding(.horizontal, 24)

                // MARK: Error banner
                if let errorMessage = viewModel.errorMessage {
                    Text(errorMessage)
                        .font(.subheadline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.red.opacity(0.85))
                        .cornerRadius(10)
                        .padding(.horizontal, 24)
                        .accessibilityIdentifier("errorBanner")
                }

                // MARK: Sign In button
                Button {
                    Task { await viewModel.signIn() }
                } label: {
                    Group {
                        if viewModel.isLoading {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        } else {
                            Text("Sign In")
                                .fontWeight(.semibold)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(viewModel.canSignIn ? Color.accentColor : Color.gray)
                    .foregroundColor(.white)
                    .cornerRadius(12)
                }
                .disabled(!viewModel.canSignIn || viewModel.isLoading)
                .padding(.horizontal, 24)
                .accessibilityIdentifier("signInButton")

                Spacer()
            }

            // Full-screen loading overlay (blocks interaction while in flight)
            if viewModel.isLoading {
                Color.black.opacity(0.15)
                    .ignoresSafeArea()
                    .allowsHitTesting(true)
                    .accessibilityIdentifier("loadingOverlay")
            }
        }
    }
}
