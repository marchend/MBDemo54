import SwiftUI

/// Root content view for AcmeBank.
///
/// Presents `LoginView` as the initial screen.
/// Replace this with `RootView` (auth-state switching via `AppCoordinator`)
/// once the Okta integration story is implemented.
struct ContentView: View {
    var body: some View {
        LoginView(viewModel: LoginViewModel())
    }
}

#Preview {
    ContentView()
}
