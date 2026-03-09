import SwiftUI

struct ResultsView: View {
    @StateObject private var viewModel: ResultsViewModel

    init(leagueId: String, season: Int) {
        _viewModel = StateObject(
            wrappedValue: ResultsViewModel(
                leagueId: leagueId,
                season: season
            )
        )
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.rounds.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.errorMessage,
                      viewModel.rounds.isEmpty {
                errorView(message: error)
            } else if viewModel.rounds.isEmpty {
                emptyView
            } else {
                roundsList
            }
        }
        .navigationTitle("Results")
        .navigationBarTitleDisplayMode(.large)
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
    }

    // MARK: - Subviews

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

    private var emptyView: some View {
        VStack(spacing: Theme.Spacing.s40) {
            Image(systemName: Theme.Icon.Pick.gameweek)
                .font(.system(size: 48))
                .foregroundStyle(Theme.Color.Border.default)
            Text("No results yet")
                .font(Theme.Typography.title3)
                .foregroundStyle(
                    Theme.Color.Content.Text.default
                )
            Text("Results will appear here once gameweeks are settled.")
                .font(Theme.Typography.subheadline)
                .foregroundStyle(
                    Theme.Color.Content.Text.disabled
                )
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, Theme.Spacing.s40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var roundsList: some View {
        ScrollView {
            LazyVStack(spacing: Theme.Spacing.s30) {
                ForEach(viewModel.rounds) { round in
                    RoundSection(
                        round: round,
                        isExpanded: viewModel.expandedRoundId
                            == round.id,
                        onToggle: {
                            withAnimation(.easeInOut(duration: 0.25)) {
                                viewModel.toggleRound(round.id)
                            }
                        }
                    )
                }
            }
            .padding(.horizontal, Theme.Spacing.s40)
            .padding(.vertical, Theme.Spacing.s40)
        }
    }
}

// MARK: - Round Section

private struct RoundSection: View {
    let round: RoundResult
    let isExpanded: Bool
    let onToggle: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            roundHeader
            if isExpanded {
                Divider()
                    .background(Theme.Color.Border.default)
                expandedContent
            }
        }
        .background(Theme.Color.Surface.Background.container)
        .clipShape(
            RoundedRectangle(cornerRadius: Theme.Radius.r40)
        )
        .themeShadow(Theme.Shadow.md)
    }

    private var roundHeader: some View {
        Button(action: onToggle) {
            HStack {
                VStack(alignment: .leading, spacing: Theme.Spacing.s10) {
                    Text(round.gameweek.name)
                        .font(Theme.Typography.headline)
                        .foregroundStyle(
                            Theme.Color.Content.Text.default
                        )
                    HStack(spacing: Theme.Spacing.s20) {
                        Label(
                            "\(round.survivedCount)",
                            systemImage: Theme.Icon.Status.success
                        )
                        .foregroundStyle(
                            Theme.Color.Status.Success.resting
                        )
                        Label(
                            "\(round.eliminatedCount)",
                            systemImage: Theme.Icon.Status.failure
                        )
                        .foregroundStyle(
                            Theme.Color.Status.Error.resting
                        )
                        if round.voidCount > 0 {
                            Label(
                                "\(round.voidCount)",
                                systemImage: Theme.Icon.Status.error
                            )
                            .foregroundStyle(
                                Theme.Color.Status.Warning.resting
                            )
                        }
                    }
                    .font(Theme.Typography.caption1)
                }

                Spacer()

                Image(
                    systemName: isExpanded
                        ? "chevron.up"
                        : "chevron.down"
                )
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.Color.Content.Text.subtle)
            }
            .padding(Theme.Spacing.s40)
        }
        .buttonStyle(.plain)
    }

    private var expandedContent: some View {
        VStack(spacing: 0) {
            ForEach(round.picks) { pick in
                RoundPickRowView(
                    pick: pick,
                    fixture: round.fixture(for: pick.fixtureId)
                )
                if pick.id != round.picks.last?.id {
                    Divider()
                        .background(Theme.Color.Border.default)
                        .padding(.leading, Theme.Spacing.s40)
                }
            }
        }
    }
}

// MARK: - Round Pick Row View

private struct RoundPickRowView: View {
    let pick: RoundPickRow
    let fixture: Fixture?

    var body: some View {
        HStack(spacing: Theme.Spacing.s30) {
            resultIcon

            VStack(alignment: .leading, spacing: 2) {
                Text(pick.profiles.displayLabel)
                    .font(Theme.Typography.subheadline)
                    .foregroundStyle(
                        Theme.Color.Content.Text.default
                    )
                HStack(spacing: Theme.Spacing.s10) {
                    Text(pick.teamName)
                        .font(Theme.Typography.caption1)
                        .foregroundStyle(
                            Theme.Color.Content.Text.subtle
                        )
                    if let fixture {
                        Text(fixture.scoreLabel)
                            .font(Theme.Typography.caption2)
                            .foregroundStyle(
                                Theme.Color.Content.Text.disabled
                            )
                    }
                }
            }

            Spacer()

            PickStatusBadge(status: pick.result.pickStatus)
        }
        .padding(.horizontal, Theme.Spacing.s40)
        .padding(.vertical, Theme.Spacing.s30)
    }

    @ViewBuilder private var resultIcon: some View {
        switch pick.result {
        case .survived:
            Image(systemName: Theme.Icon.Status.success)
                .foregroundStyle(
                    Theme.Color.Status.Success.resting
                )
        case .eliminated:
            Image(systemName: Theme.Icon.Status.failure)
                .foregroundStyle(
                    Theme.Color.Status.Error.resting
                )
        case .void:
            Image(systemName: Theme.Icon.Status.errorFill)
                .foregroundStyle(
                    Theme.Color.Status.Warning.resting
                )
        case .pending:
            Image(systemName: Theme.Icon.Pick.timeRemaining)
                .foregroundStyle(
                    Theme.Color.Content.Text.disabled
                )
        }
    }
}

// MARK: - Helpers

private extension Fixture {
    var scoreLabel: String {
        guard let home = homeScore, let away = awayScore else {
            return ""
        }
        return "\(homeTeamShort) \(home)-\(away) \(awayTeamShort)"
    }
}

private extension PickResult {
    var pickStatus: PickStatus {
        switch self {
        case .survived:   return .survived
        case .eliminated: return .eliminated
        case .void:       return .void
        case .pending:    return .pending
        }
    }
}
