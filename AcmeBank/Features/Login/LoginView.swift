import SwiftUI
import SafariServices

/// Login screen — collects credentials and hands them off to `LoginViewModel`.
///
/// Design contract:
/// - Logo / app name at the top
/// - Username field with email keyboard and `name@acmebank.com` placeholder
/// - Password field with show/hide eye toggle
/// - "Keep me signed in" checkbox (local state only, unchecked by default)
/// - Sign In button disabled while fields are empty or a request is in flight
/// - "Need help?" link that opens a Safari sheet with the support URL
/// - Inline error banner when `viewModel.errorMessage` is non-nil
/// - Spinner overlay while `viewModel.isLoading` is `true`
struct LoginView: View {

    @StateObject var viewModel: LoginViewModel

    // MARK: - Local UI state

    /// Controls whether the password characters are revealed.
    @State private var isPasswordVisible: Bool = false

    /// Controls the "Keep me signed in" checkbox. Local state only;
    /// Keychain persistence is deferred to the Okta auth story.
    @State private var keepMeSignedIn: Bool = false

    /// Controls presentation of the "Need help?" Safari sheet.
    @State private var isHelpSheetPresented: Bool = false

    /// Placeholder support URL — will be replaced with the real URL when available.
    private let helpURL = URL(string: "https://www.acmebank.com/support")!

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
                    // Username — email keyboard type + email-style placeholder (AC)
                    TextField("name@acmebank.com", text: $viewModel.username)
                        .keyboardType(.emailAddress)
                        .textContentType(.username)
                        .textInputAutocapitalization(.never)
                        .disableAutocorrection(true)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                        .accessibilityIdentifier("usernameField")

                    // Password — show/hide toggle (AC)
                    ZStack(alignment: .trailing) {
                        Group {
                            if isPasswordVisible {
                                TextField("Password", text: $viewModel.password)
                                    .textContentType(.password)
                                    .textInputAutocapitalization(.never)
                                    .disableAutocorrection(true)
                            } else {
                                SecureField("Password", text: $viewModel.password)
                                    .textContentType(.password)
                            }
                        }
                        .padding()
                        .padding(.trailing, 44) // room for the eye button
                        .background(Color(.secondarySystemBackground))
                        .cornerRadius(10)
                        .accessibilityIdentifier("passwordField")

                        Button {
                            isPasswordVisible.toggle()
                        } label: {
                            Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                                .foregroundColor(.secondary)
                                .padding(.trailing, 12)
                        }
                        .accessibilityLabel(isPasswordVisible ? "Hide password" : "Show password")
                        .accessibilityIdentifier("passwordVisibilityToggle")
                    }
                }
                .padding(.horizontal, 24)

                // MARK: Keep me signed in (AC — local state, Keychain deferred)
                Toggle(isOn: $keepMeSignedIn) {
                    Text("Keep me signed in")
                        .font(.subheadline)
                        .foregroundColor(.primary)
                }
                .toggleStyle(CheckboxToggleStyle())
                .padding(.horizontal, 24)
                .accessibilityIdentifier("keepMeSignedInToggle")

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

                // MARK: Need help? link (AC)
                Button {
                    isHelpSheetPresented = true
                } label: {
                    Text("Need help?")
                        .font(.footnote)
                        .foregroundColor(.accentColor)
                        .underline()
                }
                .accessibilityIdentifier("needHelpButton")
                .sheet(isPresented: $isHelpSheetPresented) {
                    SafariView(url: helpURL)
                        .ignoresSafeArea()
                }

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

// MARK: - Checkbox toggle style

/// A toggle style that renders as a checkbox instead of the default iOS switch.
private struct CheckboxToggleStyle: ToggleStyle {
    func makeBody(configuration: Configuration) -> some View {
        Button {
            configuration.isOn.toggle()
        } label: {
            HStack(spacing: 8) {
                Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                    .foregroundColor(configuration.isOn ? .accentColor : .secondary)
                    .imageScale(.large)
                configuration.label
            }
        }
        .buttonStyle(.plain)
    }
}

// MARK: - SafariView wrapper

/// A `UIViewControllerRepresentable` wrapper around `SFSafariViewController`.
private struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) {}
}
