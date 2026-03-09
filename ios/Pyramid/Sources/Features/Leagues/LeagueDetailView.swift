import SwiftUI

struct LeagueDetailView: View {
    @StateObject private var viewModel: LeagueDetailViewModel
    @State private var showPicks = false

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
                if viewModel.league.status == .active {
                    Button("My Pick") { showPicks = true }
                        .buttonStyle(.borderedProminent)
                }
            }
        }
        .navigationDestination(isPresented: $showPicks) {
            PicksView(leagueId: viewModel.league.id)
        }
        .task { await viewModel.load() }
        .refreshable { await viewModel.load() }
    }

    // MARK: - Subviews

    private func errorView(message: String) -> some View {
        VStack(spacing: DS.Spacing.s4) {
            Image(systemName: SFSymbol.error)
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

    private var standingsContent: some View {
        ScrollView {
            VStack(spacing: DS.Spacing.s4) {
                statsHeader
                if viewModel.members.isEmpty {
                    emptyMembersView
                } else {
                    membersList
                }
            }
            .padding(.vertical, DS.Spacing.s4)
        }
    }

    private var statsHeader: some View {
        HStack(spacing: DS.Spacing.s3) {
            statBadge(
                label: "Alive",
                value: "\(viewModel.activeCount)",
                color: Color.DS.Semantic.success
            )
            statBadge(
                label: "Eliminated",
                value: "\(viewModel.eliminatedCount)",
                color: Color.DS.Semantic.error
            )
            if let gw = viewModel.currentGameweek {
                statBadge(
                    label: "Gameweek",
                    value: "\(gw.roundNumber)",
                    color: Color.DS.Neutral.n500
                )
            }
        }
        .padding(.horizontal, DS.Spacing.pageMargin)
    }

    private func statBadge(label: String, value: String, color: Color) -> some View {
        DSCard {
            VStack(spacing: DS.Spacing.s1) {
                Text(value)
                    .font(.DS.title2)
                    .foregroundStyle(color)
                Text(label)
                    .font(.DS.caption1)
                    .foregroundStyle(Color.DS.Neutral.n500)
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var emptyMembersView: some View {
        VStack(spacing: DS.Spacing.s4) {
            Image(systemName: SFSymbol.members)
                .font(.system(size: 48))
                .foregroundStyle(Color.DS.Neutral.n300)
            Text("No other members yet")
                .font(.DS.title3)
                .foregroundStyle(Color.DS.Neutral.n900)
            Text("Share the join code to invite players.")
                .font(.DS.subheadline)
                .foregroundStyle(Color.DS.Neutral.n500)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, DS.Spacing.pageMargin)
        .padding(.top, DS.Spacing.s8)
    }

    private var membersList: some View {
        VStack(spacing: DS.Spacing.s2) {
            if !viewModel.isDeadlinePassed() {
                HStack {
                    Image(systemName: SFSymbol.lockedPick)
                        .foregroundStyle(Color.DS.Neutral.n500)
                    Text("Picks are hidden until kick-off")
                        .font(.DS.caption1)
                        .foregroundStyle(Color.DS.Neutral.n500)
                    Spacer()
                }
                .padding(.horizontal, DS.Spacing.pageMargin)
            }

            ForEach(viewModel.sortedMembers) { member in
                MemberRow(
                    member: member,
                    pick: viewModel.pick(for: member),
                    deadlinePassed: viewModel.isDeadlinePassed()
                )
                .padding(.horizontal, DS.Spacing.pageMargin)
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
            HStack(spacing: DS.Spacing.s3) {
                statusIcon

                VStack(alignment: .leading, spacing: DS.Spacing.s1) {
                    Text(member.profiles.displayLabel)
                        .font(.DS.headline)
                        .foregroundStyle(Color.DS.Neutral.n900)

                    if let eliminatedGw = member.eliminatedInGameweekId {
                        Text("Eliminated GW\(eliminatedGw)")
                            .font(.DS.caption1)
                            .foregroundStyle(Color.DS.Semantic.error)
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
            Image(systemName: SFSymbol.trophyFill)
                .foregroundStyle(Color.DS.Semantic.warning)
        case .active:
            Image(systemName: SFSymbol.success)
                .foregroundStyle(Color.DS.Semantic.success)
        case .eliminated:
            Image(systemName: SFSymbol.failure)
                .foregroundStyle(Color.DS.Semantic.error)
        }
    }

    @ViewBuilder private var pickView: some View {
        if !deadlinePassed {
            Image(systemName: SFSymbol.lockedPick)
                .font(.DS.caption1)
                .foregroundStyle(Color.DS.Neutral.n300)
        } else if let pick {
            VStack(alignment: .trailing, spacing: 2) {
                Text(pick.teamName)
                    .font(.DS.subheadline)
                    .foregroundStyle(Color.DS.Neutral.n900)
                resultBadge(for: pick.result)
            }
        } else {
            Text("No pick")
                .font(.DS.caption1)
                .foregroundStyle(Color.DS.Neutral.n300)
        }
    }

    @ViewBuilder
    private func resultBadge(for result: PickResult) -> some View {
        switch result {
        case .survived:
            Text("Survived")
                .font(.DS.caption2)
                .foregroundStyle(Color.DS.Semantic.success)
        case .eliminated:
            Text("Eliminated")
                .font(.DS.caption2)
                .foregroundStyle(Color.DS.Semantic.error)
        case .pending:
            Text("Pending")
                .font(.DS.caption2)
                .foregroundStyle(Color.DS.Neutral.n500)
        case .void:
            Text("Void")
                .font(.DS.caption2)
                .foregroundStyle(Color.DS.Semantic.warning)
        }
    }
}
