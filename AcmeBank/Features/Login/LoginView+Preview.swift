import SwiftUI

// MARK: - Previews

#Preview("Idle – Light") {
    LoginView(viewModel: LoginViewModel())
        .preferredColorScheme(.light)
}

#Preview("Idle – Dark") {
    LoginView(viewModel: LoginViewModel())
        .preferredColorScheme(.dark)
}

#Preview("Loading state") {
    let vm = LoginViewModel()
    vm.username = "alice@acme.com"
    vm.password = "s3cr3t"
    vm.isLoading = true
    return LoginView(viewModel: vm)
}

#Preview("Error state") {
    let vm = LoginViewModel()
    vm.username = "alice@acme.com"
    vm.password = "wrongpassword"
    vm.errorMessage = "Invalid username or password. Please try again."
    return LoginView(viewModel: vm)
}
