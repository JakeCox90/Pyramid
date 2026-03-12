import SwiftUI

struct PicksView: View {
    @StateObject private var viewModel: PicksViewModel

    init(leagueId: String) {
        _viewModel = StateObject(wrappedValue: PicksViewModel(leagueId: leagueId))
    }

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.fixtures.isEmpty {
                    loadingView
                } else if let error = viewModel.errorMessage, viewModel.fixtures.isEmpty {
                    errorView(message: error)
                } else if viewModel.fixtures.isEmpty {
                    emptyStateView
                } else {
                    fixturesList
                }
            }
            .navigationTitle("Make Your Pick")
            .navigationBarTitleDisplayMode(.large)
            .background(Theme.Color.Surface.Background.page.ignoresSafeArea())
            .task {
                await viewModel.load()
            }
            .refreshable {
                await viewModel.load()
            }
        }
    }

    // MARK: - Subviews

    private var loadingView: some View {
        ProgressView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: Theme.Spacing.s40) {
            Image(systemName: Theme.Icon.Status.error)
                .font(.system(size: 48))
                .foregroundStyle(Theme.Color.Border.default)
            Text(message)
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.Color.Content.Text.disabled)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, Theme.Spacing.s40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyStateView: some View {
        VStack(spacing: Theme.Spacing.s40) {
            Image(systemName: Theme.Icon.Pick.deadline)
                .font(.system(size: 56))
                .foregroundStyle(Theme.Color.Border.default)
            Text("No fixtures this week")
                .font(Theme.Typography.title3)
                .foregroundStyle(Theme.Color.Content.Text.default)
            Text("Check back when the gameweek schedule is available.")
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.Color.Content.Text.disabled)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, Theme.Spacing.s40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var fixturesList: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.s30) {
                if let gameweek = viewModel.gameweek {
                    Text("Gameweek \(gameweek.roundNumber)")
                        .font(Theme.Typography.subheadline)
                        .foregroundStyle(Theme.Color.Content.Text.disabled)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, Theme.Spacing.s40)
                }

                if let pick = viewModel.currentPick {
                    currentPickBanner(pick: pick)
                }
                if let success = viewModel.successMessage {
                    successBanner(message: success)
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .animation(.spring(response: 0.4), value: viewModel.successMessage)
                }
                if let error = viewModel.errorMessage {
                    errorBanner(message: error)
                }

                if let deadline = viewModel.deadlineText {
                    HStack {
                        Image(systemName: Theme.Icon.Pick.timeRemaining)
                            .foregroundStyle(Theme.Color.Status.Warning.resting)
                        Text(deadline)
                            .font(Theme.Typography.subheadline.bold())
                            .foregroundStyle(Theme.Color.Status.Warning.resting)
                    }
                    .padding(.horizontal, Theme.Spacing.s40)
                }

                Text("Tap a team to submit your pick. Teams already used this season are greyed out.")
                    .font(Theme.Typography.caption1)
                    .foregroundStyle(Theme.Color.Content.Text.disabled)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, Theme.Spacing.s40)

                ForEach(viewModel.fixtures) { fixture in
                    FixturePickRow(
                        fixture: fixture,
                        selectedTeamId: viewModel.currentPick?.teamId,
                        usedTeamIds: viewModel.usedTeamIds,
                        isLocked: viewModel.isFixtureLocked(fixture),
                        isSubmitting: viewModel.isSubmitting,
                        celebratedTeamId: viewModel.celebratedTeamId,
                        showCelebration: viewModel.showCelebration
                    ) { teamId, teamName in
                        Task { await viewModel.submitPick(fixtureId: fixture.id, teamId: teamId, teamName: teamName) }
                    }
                    .padding(.horizontal, Theme.Spacing.s40)
                }
            }
            .padding(.vertical, Theme.Spacing.s40)
        }
    }

    private func currentPickBanner(pick: Pick) -> some View {
        HStack {
            Image(systemName: pick.isLocked ? Theme.Icon.Pick.locked : Theme.Icon.Status.success)
                .foregroundStyle(pick.isLocked ? Theme.Color.Content.Text.disabled : Theme.Color.Status.Success.resting)
            VStack(alignment: .leading, spacing: 2) {
                Text(pick.isLocked ? "Pick locked: \(pick.teamName)" : "Current pick: \(pick.teamName)")
                    .font(Theme.Typography.subheadline.bold())
                    .foregroundStyle(Theme.Color.Content.Text.default)
                if !pick.isLocked {
                    Text("You can change your pick until kick-off.")
                        .font(Theme.Typography.caption1)
                        .foregroundStyle(Theme.Color.Content.Text.disabled)
                }
            }
            Spacer()
        }
        .padding(Theme.Spacing.s30)
        .background(Theme.Color.Surface.Background.page)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, Theme.Spacing.s40)
    }

    private func successBanner(message: String) -> some View {
        HStack {
            Image(systemName: Theme.Icon.Status.success)
                .foregroundStyle(Theme.Color.Status.Success.resting)
            Text(message)
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.Color.Content.Text.default)
            Spacer()
        }
        .padding(Theme.Spacing.s30)
        .background(Theme.Color.Status.Success.subtle)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, Theme.Spacing.s40)
    }

    private func errorBanner(message: String) -> some View {
        HStack {
            Image(systemName: Theme.Icon.Status.errorFill)
                .foregroundStyle(Theme.Color.Status.Error.resting)
            Text(message)
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.Color.Content.Text.default)
            Spacer()
        }
        .padding(Theme.Spacing.s30)
        .background(Theme.Color.Status.Error.subtle)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, Theme.Spacing.s40)
    }
}
