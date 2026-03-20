import SwiftUI

struct PicksView: View {
    @StateObject var viewModel: PicksViewModel

    @Environment(\.dismiss)
    private var dismiss

    @Environment(\.accessibilityReduceMotion)
    var reduceMotion

    init(leagueId: String) {
        _viewModel = StateObject(
            wrappedValue: PicksViewModel(leagueId: leagueId)
        )
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Theme.Color.Surface.Background.page
                    .ignoresSafeArea()

                Group {
                    if viewModel.isLoading
                        && viewModel.fixtures.isEmpty {
                        loadingView
                    } else if let error = viewModel.errorMessage,
                              viewModel.fixtures.isEmpty {
                        errorView(message: error)
                    } else if viewModel.fixtures.isEmpty {
                        emptyStateView
                    } else {
                        fixturesList
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(
                                .system(size: 16, weight: .semibold)
                            )
                            .foregroundStyle(
                                Theme.Color.Content.Text.default
                            )
                    }
                }
            }
            .task {
                await viewModel.load()
            }
            .refreshable {
                await viewModel.load()
            }
        }
    }
}

// MARK: - Header & Used Teams

extension PicksView {
    var headerSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s20) {
            if let gameweek = viewModel.gameweek {
                Text("GAMEWEEK \(gameweek.roundNumber)")
                    .font(Theme.Typography.caption1)
                    .foregroundStyle(
                        Theme.Color.Content.Text.disabled
                    )
                    .tracking(1.2)
            }

            Text("Pick a team")
                .font(Font.custom("Inter-Bold", size: 44))
                .foregroundStyle(
                    Theme.Color.Content.Text.default
                )

            if !viewModel.usedTeamIds.isEmpty {
                usedTeamsRail
            }

            if let deadline = viewModel.deadlineText {
                HStack(spacing: Theme.Spacing.s10) {
                    Image(
                        systemName: Theme.Icon.Pick.timeRemaining
                    )
                    .font(.system(size: 12))
                    .accessibilityHidden(true)
                    Text(deadline)
                        .font(Theme.Typography.caption1)
                }
                .foregroundStyle(
                    Theme.Color.Status.Warning.resting
                )
                .padding(.top, Theme.Spacing.s10)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Theme.Spacing.s40)
    }

    private var usedTeamsRail: some View {
        HStack(spacing: -8) {
            ForEach(
                viewModel.usedTeamNames, id: \.self
            ) { name in
                TeamBadge(
                    teamName: name,
                    logoURL: nil,
                    size: 28
                )
                .clipShape(Circle())
                .overlay(
                    Circle()
                        .stroke(
                            Theme.Color.Surface.Background.page,
                            lineWidth: 2
                        )
                )
            }

            let count = viewModel.usedTeamIds.count
            Text(
                "\(count) team\(count == 1 ? "" : "s") used"
            )
            .font(Theme.Typography.caption2)
            .foregroundStyle(
                Theme.Color.Content.Text.subtle
            )
            .padding(.horizontal, Theme.Spacing.s30)
            .padding(.vertical, Theme.Spacing.s10)
            .background(
                Theme.Color.Surface.Background.highlight
            )
            .clipShape(Capsule())
            .padding(.leading, Theme.Spacing.s20)
        }
    }
}

// MARK: - States & Fixtures List

extension PicksView {
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
                .foregroundStyle(
                    Theme.Color.Content.Text.disabled
                )
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
                .foregroundStyle(
                    Theme.Color.Content.Text.default
                )
            Text("Check back when the gameweek schedule is available.")
                .font(Theme.Typography.subheadline)
                .foregroundStyle(
                    Theme.Color.Content.Text.disabled
                )
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, Theme.Spacing.s40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    var fixturesList: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.s40) {
                headerSection
                bannerSection

                ForEach(viewModel.fixtures) { fixture in
                    FixturePickRow(
                        fixture: fixture,
                        selectedTeamId: viewModel.currentPick?.teamId,
                        usedTeamIds: viewModel.usedTeamIds,
                        isLocked: viewModel.isFixtureLocked(fixture),
                        isSubmitting: viewModel.isSubmitting,
                        submittingTeamId: viewModel.submittingTeamId,
                        celebratedTeamId: viewModel.celebratedTeamId,
                        showCelebration: viewModel.showCelebration
                    ) { teamId, teamName in
                        Task {
                            await viewModel.submitPick(
                                fixtureId: fixture.id,
                                teamId: teamId,
                                teamName: teamName
                            )
                        }
                    }
                    .padding(.horizontal, Theme.Spacing.s40)
                }
            }
            .padding(.vertical, Theme.Spacing.s40)
        }
    }
}
