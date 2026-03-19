import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Group {
            if appState.isLoading {
                ProgressView()
            } else if appState.session != nil && appState.showOnboarding {
                OnboardingView()
            } else if appState.session != nil {
                MainTabView()
            } else {
                AuthView()
            }
        }
        .preferredColorScheme(.dark)
        .task {
            await appState.loadSession()
        }
    }
}
