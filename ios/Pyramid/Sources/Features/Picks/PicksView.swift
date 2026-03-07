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
            .navigationTitle(viewModel.gameweek?.name ?? "Make Your Pick")
            .navigationBarTitleDisplayMode(.large)
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
        VStack(spacing: DS.Spacing.s4) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundStyle(Color.DS.Neutral.n300)
            Text(message)
                .font(.DS.subheadline)
                .foregroundStyle(Color.DS.Neutral.n500)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, DS.Spacing.pageMargin)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyStateView: some View {
        VStack(spacing: DS.Spacing.s4) {
            Image(systemName: "calendar.badge.clock")
                .font(.system(size: 56))
                .foregroundStyle(Color.DS.Neutral.n300)
            Text("No fixtures this week")
                .font(.DS.title3)
                .foregroundStyle(Color.DS.Neutral.n900)
            Text("Check back when the gameweek schedule is available.")
                .font(.DS.subheadline)
                .foregroundStyle(Color.DS.Neutral.n500)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, DS.Spacing.pageMargin)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var fixturesList: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.s3) {
                if let pick = viewModel.currentPick {
                    currentPickBanner(pick: pick)
                }
                if let success = viewModel.successMessage {
                    successBanner(message: success)
                }
                if let error = viewModel.errorMessage {
                    errorBanner(message: error)
                }

                if let deadline = viewModel.deadlineText {
                    HStack {
                        Image(systemName: "clock")
                            .foregroundStyle(Color.DS.Semantic.warning)
                        Text(deadline)
                            .font(.DS.subheadline.bold())
                            .foregroundStyle(Color.DS.Semantic.warning)
                    }
                    .padding(.horizontal, DS.Spacing.pageMargin)
                }

                Text("Tap a team to submit your pick. Teams already used this season are greyed out.")
                    .font(.DS.caption1)
                    .foregroundStyle(Color.DS.Neutral.n500)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, DS.Spacing.pageMargin)

                ForEach(viewModel.fixtures) { fixture in
                    FixturePickRow(
                        fixture: fixture,
                        selectedTeamId: viewModel.currentPick?.teamId,
                        usedTeamIds: viewModel.usedTeamIds,
                        isLocked: viewModel.isFixtureLocked(fixture),
                        isSubmitting: viewModel.isSubmitting
                    ) { teamId, teamName in
                        Task { await viewModel.submitPick(fixtureId: fixture.id, teamId: teamId, teamName: teamName) }
                    }
                    .padding(.horizontal, DS.Spacing.pageMargin)
                }
            }
            .padding(.vertical, DS.Spacing.s4)
        }
    }

    private func currentPickBanner(pick: Pick) -> some View {
        HStack {
            Image(systemName: pick.isLocked ? "lock.fill" : "checkmark.circle.fill")
                .foregroundStyle(pick.isLocked ? Color.DS.Neutral.n500 : Color.DS.Semantic.success)
            VStack(alignment: .leading, spacing: 2) {
                Text(pick.isLocked ? "Pick locked: \(pick.teamName)" : "Current pick: \(pick.teamName)")
                    .font(.DS.subheadline.bold())
                    .foregroundStyle(Color.DS.Neutral.n900)
                if !pick.isLocked {
                    Text("You can change your pick until kick-off.")
                        .font(.DS.caption1)
                        .foregroundStyle(Color.DS.Neutral.n500)
                }
            }
            Spacer()
        }
        .padding(DS.Spacing.s3)
        .background(Color.DS.Neutral.n100)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, DS.Spacing.pageMargin)
    }

    private func successBanner(message: String) -> some View {
        HStack {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(Color.DS.Semantic.success)
            Text(message)
                .font(.DS.subheadline)
                .foregroundStyle(Color.DS.Neutral.n900)
            Spacer()
        }
        .padding(DS.Spacing.s3)
        .background(Color.DS.Semantic.successSubtle)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, DS.Spacing.pageMargin)
    }

    private func errorBanner(message: String) -> some View {
        HStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(Color.DS.Semantic.error)
            Text(message)
                .font(.DS.subheadline)
                .foregroundStyle(Color.DS.Neutral.n900)
            Spacer()
        }
        .padding(DS.Spacing.s3)
        .background(Color.DS.Semantic.errorSubtle)
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .padding(.horizontal, DS.Spacing.pageMargin)
    }
}

// MARK: - Fixture Pick Row

struct FixturePickRow: View {
    let fixture: Fixture
    let selectedTeamId: Int?
    let usedTeamIds: Set<Int>
    let isLocked: Bool
    let isSubmitting: Bool
    let onPick: (Int, String) -> Void

    private var kickoffText: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE dd MMM, HH:mm"
        return formatter.string(from: fixture.kickoffAt)
    }

    var body: some View {
        DSCard {
            VStack(spacing: DS.Spacing.s3) {
                Text(kickoffText)
                    .font(.DS.caption1)
                    .foregroundStyle(Color.DS.Neutral.n500)
                    .frame(maxWidth: .infinity)

                HStack(spacing: DS.Spacing.s3) {
                    teamButton(
                        teamId: fixture.homeTeamId,
                        teamName: fixture.homeTeamName,
                        shortName: fixture.homeTeamShort,
                        score: fixture.homeScore
                    )

                    VStack(spacing: DS.Spacing.s1) {
                        if fixture.status.isLive || fixture.status.isFinished {
                            Text(fixture.status.displayLabel)
                                .font(.DS.caption1.bold())
                                .foregroundStyle(
                                    fixture.status.isLive
                                        ? Color.DS.Semantic.error
                                        : Color.DS.Neutral.n500
                                )
                        } else {
                            Text("vs")
                                .font(.DS.caption1)
                                .foregroundStyle(Color.DS.Neutral.n500)
                        }
                    }

                    teamButton(
                        teamId: fixture.awayTeamId,
                        teamName: fixture.awayTeamName,
                        shortName: fixture.awayTeamShort,
                        score: fixture.awayScore
                    )
                }
            }
        }
    }

    @ViewBuilder
    private func teamButton(teamId: Int, teamName: String, shortName: String, score: Int?) -> some View {
        let isPicked = selectedTeamId == teamId
        let isUsed = usedTeamIds.contains(teamId) && !isPicked
        let isDisabled = isLocked || isSubmitting || isUsed

        Button {
            guard !isDisabled else { return }
            onPick(teamId, teamName)
        } label: {
            VStack(spacing: DS.Spacing.s1) {
                if let score {
                    Text("\(score)")
                        .font(.DS.title2.bold())
                        .foregroundStyle(Color.DS.Neutral.n900)
                }
                Text(shortName)
                    .font(.DS.headline)
                    .foregroundStyle(isPicked ? Color.white : Color.DS.Neutral.n900)
                Text(teamName)
                    .font(.DS.caption2)
                    .foregroundStyle(isPicked ? Color.white.opacity(0.8) : Color.DS.Neutral.n500)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                if isUsed {
                    Text("Used")
                        .font(.DS.caption2)
                        .foregroundStyle(Color.DS.Semantic.error)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DS.Spacing.s3)
            .background(isPicked ? Color.DS.Neutral.n900 : Color.DS.Neutral.n100)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isPicked ? Color.DS.Neutral.n900 : Color.DS.Neutral.n300, lineWidth: 1)
            )
            .opacity(isDisabled && !isPicked ? 0.5 : 1.0)
        }
        .disabled(isDisabled && !isPicked)
    }
}
