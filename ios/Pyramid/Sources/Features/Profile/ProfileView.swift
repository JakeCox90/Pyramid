import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = ProfileViewModel()

    #if DEBUG
    @State private var isResettingGame = false
    @State private var isResettingFull = false
    @State private var resetMessage: String?
    #endif

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.s30) {
                    profileHeader

                    if viewModel.isLoadingStats {
                        ProgressView()
                            .padding(.top, Theme.Spacing.s60)
                    } else {
                        statsGrid(stats: viewModel.stats)

                        if !viewModel.stats.activeStreaks.isEmpty {
                            activeStreaksSection(
                                streaks: viewModel.stats.activeStreaks
                            )
                        }

                        if !viewModel.stats.leagueHistory.isEmpty {
                            leagueHistorySection(
                                history: viewModel.stats.leagueHistory
                            )
                        }
                    }

                    settingsSection

                    #if DEBUG
                    devToolsSection
                    #endif

                    if let error = viewModel.errorMessage {
                        Text(error)
                            .font(Theme.Typography.footnote)
                            .foregroundStyle(
                                Theme.Color.Status.Error.text
                            )
                            .padding(.horizontal, Theme.Spacing.s40)
                            .multilineTextAlignment(.center)
                    }

                    signOutButton
                }
                .padding(.vertical, Theme.Spacing.s30)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(
                Theme.Color.Surface.Background.page.ignoresSafeArea()
            )
            .navigationTitle("Profile")
            .task {
                await viewModel.loadStats()
            }
        }
    }
}

// MARK: - Header

private extension ProfileView {
    var profileHeader: some View {
        VStack(spacing: Theme.Spacing.s20) {
            Image(systemName: Theme.Icon.Navigation.profile)
                .font(.system(size: 48))
                .foregroundStyle(Theme.Color.Content.Text.subtle)
            Text("Profile")
                .font(Theme.Typography.title2)
                .foregroundStyle(Theme.Color.Content.Text.default)
        }
    }
}

// MARK: - Settings

private extension ProfileView {
    var settingsSection: some View {
        NavigationLink(destination: NotificationPreferencesView()) {
            Label(
                "Notifications",
                systemImage: Theme.Icon.Navigation.notifications
            )
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Theme.Spacing.s40)
            .background(Theme.Color.Surface.Background.container)
            .clipShape(
                RoundedRectangle(cornerRadius: Theme.Radius.default)
            )
        }
        .buttonStyle(.plain)
        .padding(.horizontal, Theme.Spacing.s40)
    }
}

// MARK: - Sign Out

private extension ProfileView {
    var signOutButton: some View {
        Button("Sign Out") {
            Task {
                let didSignOut = await viewModel.signOut()
                if didSignOut {
                    appState.session = nil
                }
            }
        }
        .dsStyle(.destructive, isLoading: viewModel.isSigningOut)
        .disabled(viewModel.isSigningOut)
        .padding(.horizontal, Theme.Spacing.s40)
        .padding(.bottom, Theme.Spacing.s60)
        .accessibilityLabel("Sign Out")
    }
}

// MARK: - Developer Tools

#if DEBUG
private extension ProfileView {
    var devToolsSection: some View {
        VStack(spacing: Theme.Spacing.s20) {
            Text("Developer Tools")
                .font(Theme.Typography.footnote)
                .foregroundStyle(Theme.Color.Content.Text.subtle)
                .frame(maxWidth: .infinity, alignment: .leading)

            resetButton(
                title: "Reset Game Data",
                subtitle: "Re-seeds leagues, picks & fixtures",
                isLoading: isResettingGame,
                action: { await performReset(mode: "game") }
            )

            resetButton(
                title: "Reset Everything",
                subtitle: "Game data + restart onboarding",
                isLoading: isResettingFull,
                action: { await performReset(mode: "full") }
            )

            if let resetMessage {
                Text(resetMessage)
                    .font(Theme.Typography.footnote)
                    .foregroundStyle(Theme.Color.Content.Text.subtle)
                    .transition(.opacity)
            }
        }
        .padding(.horizontal, Theme.Spacing.s40)
    }

    func resetButton(
        title: String,
        subtitle: String,
        isLoading: Bool,
        action: @escaping () async -> Void
    ) -> some View {
        Button {
            Task { await action() }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(Theme.Typography.callout)
                        .foregroundStyle(Theme.Color.Content.Text.default)
                    Text(subtitle)
                        .font(Theme.Typography.caption1)
                        .foregroundStyle(Theme.Color.Content.Text.subtle)
                }
                Spacer()
                if isLoading {
                    ProgressView()
                } else {
                    Image(systemName: "arrow.counterclockwise")
                        .foregroundStyle(Theme.Color.Content.Text.subtle)
                }
            }
            .padding(Theme.Spacing.s30)
            .background(Theme.Color.Surface.Background.container)
            .clipShape(
                RoundedRectangle(cornerRadius: Theme.Radius.default)
            )
        }
        .buttonStyle(.plain)
        .disabled(isResettingGame || isResettingFull)
    }

    func performReset(mode: String) async {
        let isFull = mode == "full"
        if isFull {
            isResettingFull = true
        } else {
            isResettingGame = true
        }
        resetMessage = nil

        do {
            let client = SupabaseDependency.shared.client
            let response = try await DevResetService.reset(
                mode: mode,
                client: client
            )

            if response.clearOnboarding {
                appState.resetToOnboarding()
            }

            resetMessage = "Reset complete (\(mode))"
        } catch {
            Log.auth.error("DevReset failed: \(error.localizedDescription)")
            resetMessage = "Reset failed: \(error.localizedDescription)"
        }

        if isFull {
            isResettingFull = false
        } else {
            isResettingGame = false
        }
    }
}
#endif

// MARK: - Preview

#Preview {
    ProfileView()
        .environmentObject(AppState())
}
