import SwiftUI

struct RootView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        Group {
            if appState.isLoading {
                VStack(spacing: Theme.Spacing.s30) {
                    Text("Pyramid")
                        .font(Theme.Typography.h1)
                        .foregroundStyle(Theme.Color.Content.Text.default)
                    ProgressView()
                        .tint(Theme.Color.Primary.resting)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.Color.Surface.Background.page)
            } else if let error = appState.loadError {
                VStack(spacing: Theme.Spacing.s30) {
                    Image(systemName: "wifi.exclamationmark")
                        .font(.system(size: 48))
                        .foregroundStyle(Theme.Color.Status.Error.resting)
                        .accessibilityHidden(true)
                    Text("Connection Error")
                        .font(Theme.Typography.subhead)
                        .foregroundStyle(Theme.Color.Content.Text.default)
                    Text(error)
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Color.Content.Text.subtle)
                        .multilineTextAlignment(.center)
                    Button("Try Again") {
                        Task { await appState.retryLoadSession() }
                    }
                    .themed(.primary)
                }
                .padding(Theme.Spacing.s40)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Theme.Color.Surface.Background.page)
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
