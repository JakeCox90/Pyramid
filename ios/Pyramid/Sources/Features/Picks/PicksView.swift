import SwiftUI

enum PickViewMode: String {
    case carousel, list
}

struct PicksView: View {
    @StateObject var viewModel: PicksViewModel

    @AppStorage("pickViewMode")
    private var viewMode: String = PickViewMode.carousel.rawValue

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
                } else if viewMode
                    == PickViewMode.carousel.rawValue {
                    PickCarouselView(
                        viewModel: viewModel
                    )
                    .transition(.opacity)
                } else {
                    fixturesList
                        .transition(.opacity)
                }
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "chevron.left")
                        .font(Theme.Typography.subhead)
                        .foregroundStyle(Theme.Color.Content.Text.default)
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        viewMode = viewMode
                            == PickViewMode.carousel.rawValue
                            ? PickViewMode.list.rawValue
                            : PickViewMode.carousel.rawValue
                    }
                } label: {
                    Image(
                        systemName: viewMode
                            == PickViewMode.carousel.rawValue
                            ? "list.bullet"
                            : "rectangle.stack"
                    )
                    .font(
                        .system(
                            size: 16,
                            weight: .semibold
                        )
                    )
                    .foregroundStyle(Theme.Color.Content.Text.default)
                }
            }
        }
        .task {
            await viewModel.load()
        }
        .refreshable {
            await viewModel.load()
        }
        .onChange(of: viewModel.pickConfirmed) { confirmed in
            if confirmed {
                dismiss()
            }
        }
    }
}

// MARK: - Header

extension PicksView {
    var headerSection: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s20) {
            if let gameweek = viewModel.gameweek {
                Text("GAMEWEEK \(gameweek.roundNumber)")
                    .font(Theme.Typography.overline)
                    .textCase(.uppercase)
                    .foregroundStyle(
                        Theme.Color.Content.Text.secondary
                    )
            }

            Text("Pick a team")
                .font(Theme.Typography.h1)
                .foregroundStyle(Theme.Color.Content.Text.default)

            if !viewModel.usedTeamIds.isEmpty {
                TeamsUsedPill(
                    teamNames: viewModel.usedTeamNames,
                    count: viewModel.usedTeamIds.count
                )
            }

            if let deadline = viewModel.deadlineText {
                HStack(spacing: Theme.Spacing.s10) {
                    Image(
                        systemName: Theme.Icon.Pick
                            .timeRemaining
                    )
                    .font(Theme.Typography.overline)
                    .accessibilityHidden(true)
                    Text(deadline)
                        .font(Theme.Typography.overline)
                }
                .foregroundStyle(
                    Theme.Color.Status.Warning.resting
                )
                .padding(.top, Theme.Spacing.s10)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, Theme.Spacing.s60)
    }
}

// MARK: - States & Fixtures List

extension PicksView {
    private var loadingView: some View {
        ProgressView()
            .tint(Theme.Color.Content.Text.default)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorView(message: String) -> some View {
        VStack(spacing: Theme.Spacing.s40) {
            Image(systemName: Theme.Icon.Status.error)
                .font(.system(size: 48))
                .foregroundStyle(
                    Theme.Color.Content.Text.tertiary
                )
            Text(message)
                .font(Theme.Typography.body)
                .foregroundStyle(
                    Theme.Color.Content.Text.secondary
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
                .foregroundStyle(
                    Theme.Color.Content.Text.tertiary
                )
            Text("No fixtures this week")
                .font(Theme.Typography.subhead)
                .foregroundStyle(Theme.Color.Content.Text.default)
            Text(
                "Check back when the gameweek schedule is available."
            )
            .font(Theme.Typography.body)
            .foregroundStyle(
                Theme.Color.Content.Text.secondary
            )
            .multilineTextAlignment(.center)
        }
        .padding(.horizontal, Theme.Spacing.s40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    var fixturesList: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.s60) {
                headerSection
                bannerSection

                VStack(spacing: Theme.Spacing.s60) {
                    ForEach(viewModel.fixtures) { fixture in
                        FixturePickRow(
                            fixture: fixture,
                            selectedTeamId: viewModel
                                .currentPick?.teamId,
                            usedTeamIds: viewModel.usedTeamIds,
                            usedTeamRounds: viewModel.usedTeamRounds,
                            isLocked: viewModel
                                .isFixtureLocked(fixture),
                            isSubmitting: viewModel
                                .isSubmitting,
                            submittingTeamId: viewModel
                                .submittingTeamId,
                            celebratedTeamId: viewModel
                                .celebratedTeamId,
                            showCelebration: viewModel
                                .showCelebration
                        ) { teamId, teamName in
                            Task {
                                await viewModel.submitPick(
                                    fixtureId: fixture.id,
                                    teamId: teamId,
                                    teamName: teamName
                                )
                            }
                        }
                    }
                }
                .padding(.horizontal, Theme.Spacing.s60)
            }
            .padding(.vertical, Theme.Spacing.s40)
        }
    }
}
