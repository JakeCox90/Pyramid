import SwiftUI

struct LeagueDetailView: View {
    @StateObject var viewModel: LeagueDetailViewModel
    @State var showPicks = false
    @State var showResults = false
    @State var showCompleteView = false
    @State var showShareSheet = false

    init(league: League) {
        _viewModel = StateObject(wrappedValue: LeagueDetailViewModel(league: league))
    }

    var body: some View {
        Group {
            if viewModel.isLoading && viewModel.members.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let error = viewModel.errorMessage, viewModel.members.isEmpty {
                errorView(message: error)
            } else {
                standingsContent
            }
        }
        .navigationTitle(viewModel.league.name)
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                HStack(spacing: Theme.Spacing.s20) {
                    Button {
                        showShareSheet = true
                    } label: {
                        Image(systemName: Theme.Icon.Action.share)
                    }
                    Button {
                        showResults = true
                    } label: {
                        Image(systemName: Theme.Icon.Pick.gameweek)
                    }
                    if viewModel.league.status == .active {
                        Button("My Pick") { showPicks = true }
                            .buttonStyle(.borderedProminent)
                    }
                }
            }
        }
        .navigationDestination(isPresented: $showPicks) {
            PicksView(leagueId: viewModel.league.id)
        }
        .navigationDestination(isPresented: $showResults) {
            ResultsView(
                leagueId: viewModel.league.id,
                season: viewModel.league.season
            )
        }
        .sheet(isPresented: $showCompleteView) {
            LeagueCompleteView(
                leagueName: viewModel.league.name,
                winners: viewModel.winners,
                totalMembers: viewModel.members.count
            )
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(
                items: [shareMessage]
            )
        }
        .background(Theme.Color.Surface.Background.page.ignoresSafeArea())
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
    }

    private var shareMessage: String {
        "Join my Last Man Standing league '\(viewModel.league.name)'! "
            + "Code: \(viewModel.league.joinCode)"
    }

    // MARK: - Subviews

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

    private var standingsContent: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.s40) {
                if viewModel.isCompleted {
                    winnerBanner
                }
                statsHeader
                if viewModel.members.isEmpty {
                    emptyMembersView
                } else {
                    membersList
                }
            }
            .padding(.vertical, Theme.Spacing.s40)
        }
    }

    private var statsHeader: some View {
        HStack(spacing: Theme.Spacing.s30) {
            if viewModel.isCompleted && viewModel.winnerCount > 0 {
                statBadge(
                    label: viewModel.winnerCount == 1 ? "Winner" : "Winners",
                    value: "\(viewModel.winnerCount)",
                    color: Theme.Color.Status.Warning.resting
                )
            } else {
                statBadge(
                    label: "Alive",
                    value: "\(viewModel.activeCount)",
                    color: Theme.Color.Status.Success.resting
                )
            }
            statBadge(
                label: "Eliminated",
                value: "\(viewModel.eliminatedCount)",
                color: Theme.Color.Status.Error.resting
            )
            if let gw = viewModel.currentGameweek {
                statBadge(
                    label: "Gameweek",
                    value: "\(gw.roundNumber)",
                    color: Theme.Color.Content.Text.disabled
                )
            }
        }
        .padding(.horizontal, Theme.Spacing.s40)
    }

    private func statBadge(label: String, value: String, color: Color) -> some View {
        DSCard {
            VStack(spacing: Theme.Spacing.s10) {
                Text(value)
                    .font(Theme.Typography.title2)
                    .foregroundStyle(color)
                Text(label)
                    .font(Theme.Typography.caption1)
                    .foregroundStyle(Theme.Color.Content.Text.disabled)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var emptyMembersView: some View {
        VStack(spacing: Theme.Spacing.s40) {
            Image(systemName: Theme.Icon.League.members)
                .font(.system(size: 48))
                .foregroundStyle(Theme.Color.Border.default)
            Text("No other members yet")
                .font(Theme.Typography.title3)
                .foregroundStyle(Theme.Color.Content.Text.default)
            Text("Share the join code to invite players.")
                .font(Theme.Typography.subheadline)
                .foregroundStyle(Theme.Color.Content.Text.disabled)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, Theme.Spacing.s40)
        .padding(.top, Theme.Spacing.s70)
    }

    private var membersList: some View {
        VStack(spacing: Theme.Spacing.s20) {
            if !viewModel.isDeadlinePassed() {
                HStack {
                    Image(systemName: Theme.Icon.Pick.locked)
                        .foregroundStyle(Theme.Color.Content.Text.disabled)
                    Text("Picks are hidden until kick-off")
                        .font(Theme.Typography.caption1)
                        .foregroundStyle(Theme.Color.Content.Text.disabled)
                    Spacer()
                }
                .padding(.horizontal, Theme.Spacing.s40)
            }

            ForEach(viewModel.sortedMembers) { member in
                MemberRow(
                    member: member,
                    pick: viewModel.pick(for: member),
                    deadlinePassed: viewModel.isDeadlinePassed()
                )
                .padding(.horizontal, Theme.Spacing.s40)
            }
        }
    }
}

// MARK: - Member Row

struct MemberRow: View {
    let member: LeagueMember
    let pick: MemberPick?
    let deadlinePassed: Bool

    var body: some View {
        DSCard {
            HStack(spacing: Theme.Spacing.s30) {
                statusIcon

                VStack(alignment: .leading, spacing: Theme.Spacing.s10) {
                    Text(member.profiles.displayLabel)
                        .font(Theme.Typography.headline)
                        .foregroundStyle(Theme.Color.Content.Text.default)

                    if let eliminatedGw = member.eliminatedInGameweekId {
                        Text("Eliminated GW\(eliminatedGw)")
                            .font(Theme.Typography.caption1)
                            .foregroundStyle(Theme.Color.Status.Error.resting)
                    }
                }

                Spacer()

                pickView
            }
        }
    }

    @ViewBuilder private var statusIcon: some View {
        switch member.status {
        case .winner:
            Image(systemName: Theme.Icon.League.trophyFill)
                .foregroundStyle(Theme.Color.Status.Warning.resting)
        case .active:
            Image(systemName: Theme.Icon.Status.success)
                .foregroundStyle(Theme.Color.Status.Success.resting)
        case .eliminated:
            Image(systemName: Theme.Icon.Status.failure)
                .foregroundStyle(Theme.Color.Status.Error.resting)
        }
    }

    @ViewBuilder private var pickView: some View {
        if !deadlinePassed {
            Image(systemName: Theme.Icon.Pick.locked)
                .font(Theme.Typography.caption1)
                .foregroundStyle(Theme.Color.Border.default)
        } else if let pick {
            VStack(alignment: .trailing, spacing: 2) {
                Text(pick.teamName)
                    .font(Theme.Typography.subheadline)
                    .foregroundStyle(Theme.Color.Content.Text.default)
                resultBadge(for: pick.result)
            }
        } else {
            Text("No pick")
                .font(Theme.Typography.caption1)
                .foregroundStyle(Theme.Color.Border.default)
        }
    }

    @ViewBuilder
    private func resultBadge(for result: PickResult) -> some View {
        switch result {
        case .survived:
            Text("Survived")
                .font(Theme.Typography.caption2)
                .foregroundStyle(Theme.Color.Status.Success.resting)
        case .eliminated:
            Text("Eliminated")
                .font(Theme.Typography.caption2)
                .foregroundStyle(Theme.Color.Status.Error.resting)
        case .pending:
            Text("Pending")
                .font(Theme.Typography.caption2)
                .foregroundStyle(Theme.Color.Content.Text.disabled)
        case .void:
            Text("Void")
                .font(Theme.Typography.caption2)
                .foregroundStyle(Theme.Color.Status.Warning.resting)
        }
    }
}
