import SwiftUI

/// Bootstrap placeholder screen.
/// Replace with `RootView` (auth-state switching) in the AppCoordinator story.
struct ContentView: View {
    var body: some View {
        VStack {
            Text("AcmeBank")
                .font(.largeTitle)
                .fontWeight(.bold)
                .accessibilityIdentifier("appNameLabel")
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemBackground))
    }
}

#Preview {
    ContentView()
}
