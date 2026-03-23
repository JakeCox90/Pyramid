import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = ProfileViewModel()

    #if DEBUG
    @State private var isResettingGame = false
    @State private var isResettingFull = false
    @State private var resetMessage: String?
    @State private var gameweekPhase =
        DebugGameweekOverride.current
    #endif

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: Theme.Spacing.s30) {
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
                            .font(Theme.Typography.caption)
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
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .task {
                await viewModel.loadStats()
            }
        }
    }
}

// MARK: - Settings

private extension ProfileView {
    var settingsSection: some View {
        VStack(spacing: Theme.Spacing.s20) {
            settingsRow(
                title: "Leaderboard",
                icon: "chart.bar.fill",
                destination: LeaderboardView()
            )

            settingsRow(
                title: "Notifications",
                icon: Theme.Icon.Navigation.notifications,
                destination: NotificationPreferencesView()
            )

            #if DEBUG
            settingsRow(
                title: "Design System",
                icon: "paintpalette",
                destination: DesignSystemBrowserView()
            )
            #endif
        }
        .padding(.horizontal, Theme.Spacing.s40)
    }

    func settingsRow<D: View>(
        title: String,
        icon: String,
        destination: D
    ) -> some View {
        NavigationLink(destination: destination) {
            HStack {
                Label(title, systemImage: icon)
                Spacer()
                Image(
                    systemName: Theme.Icon.Navigation.disclosure
                )
                .foregroundStyle(
                    Theme.Color.Content.Text.subtle
                )
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(Theme.Spacing.s40)
            .background(
                Theme.Color.Surface.Background.container
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: Theme.Radius.default
                )
            )
        }
        .buttonStyle(.plain)
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
        .themed(.destructive, isLoading: viewModel.isSigningOut)
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
                .font(Theme.Typography.caption)
                .foregroundStyle(Theme.Color.Content.Text.subtle)
                .frame(maxWidth: .infinity, alignment: .leading)

            gameweekPhaseControl

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
                    .font(Theme.Typography.caption)
                    .foregroundStyle(Theme.Color.Content.Text.subtle)
                    .transition(.opacity)
            }
        }
        .padding(.horizontal, Theme.Spacing.s40)
    }

    var gameweekPhaseControl: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s10) {
            Text("Gameweek Status")
                .font(Theme.Typography.body)
                .foregroundStyle(
                    Theme.Color.Content.Text.default
                )
            Picker(
                "Gameweek Phase",
                selection: $gameweekPhase
            ) {
                ForEach(
                    DebugGameweekOverride.Phase.allCases,
                    id: \.self
                ) { phase in
                    Text(phase.rawValue).tag(phase)
                }
            }
            .pickerStyle(.segmented)
            .onChange(of: gameweekPhase) { phase in
                DebugGameweekOverride.current = phase
            }
            Text(
                gameweekPhase == .none
                    ? "Using real API data"
                    : "Overriding gameweek state"
            )
            .font(Theme.Typography.caption)
            .foregroundStyle(
                Theme.Color.Content.Text.subtle
            )
        }
        .padding(Theme.Spacing.s30)
        .background(
            Theme.Color.Surface.Background.container
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: Theme.Radius.default
            )
        )
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
                        .font(Theme.Typography.body)
                        .foregroundStyle(Theme.Color.Content.Text.default)
                    Text(subtitle)
                        .font(Theme.Typography.overline)
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
