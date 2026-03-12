import SwiftUI

struct ProfileView: View {
    @EnvironmentObject private var appState: AppState
    @StateObject private var viewModel = ProfileViewModel()

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

// MARK: - Preview

#Preview {
    ProfileView()
        .environmentObject(AppState())
}
