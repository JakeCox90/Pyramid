import SwiftUI

struct LeagueDetailView: View {
    @StateObject var viewModel: LeagueDetailViewModel
    @State var showPicks = false
    @State var showResults = false
    @State var showPickHistory = false
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
                        showPickHistory = true
                    } label: {
                        Image(systemName: Theme.Icon.Pick.history)
                    }
                    .accessibilityLabel("Pick history")
                    Button {
                        showShareSheet = true
                    } label: {
                        Image(systemName: Theme.Icon.Action.share)
                    }
                    .accessibilityLabel("Share league")
                    Button {
                        showResults = true
                    } label: {
                        Image(systemName: Theme.Icon.Pick.gameweek)
                    }
                    .accessibilityLabel("View results")
                    if viewModel.league.status == .active {
                        Button("My Pick") { showPicks = true }
                            .buttonStyle(.borderedProminent)
                            .accessibilityLabel("Make your pick")
                    }
                }
            }
        }
        .navigationDestination(isPresented: $showPicks) {
            PicksView(leagueId: viewModel.league.id)
        }
        .navigationDestination(isPresented: $showPickHistory) {
            PickHistoryView(leagueId: viewModel.league.id)
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
        .task {
            await viewModel.load()
            viewModel.startPolling()
        }
        .refreshable { await viewModel.load() }
        .onDisappear {
            viewModel.stopPolling()
        }
        .onAppear {
            if !viewModel.members.isEmpty {
                viewModel.startPolling()
            }
        }
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
                .accessibilityHidden(true)
            Text(message)
                .font(Theme.Typography.body)
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
                myPickCard
                if viewModel.members.isEmpty {
                    emptyMembersView
                } else {
                    membersList
                }
            }
            .padding(.vertical, Theme.Spacing.s40)
        }
    }

    private var emptyMembersView: some View {
        VStack(spacing: Theme.Spacing.s40) {
            Image(systemName: Theme.Icon.League.members)
                .font(.system(size: 48))
                .foregroundStyle(Theme.Color.Border.default)
                .accessibilityHidden(true)
            Text("No other members yet")
                .font(Theme.Typography.subhead)
                .foregroundStyle(Theme.Color.Content.Text.default)
            Text("Share the join code to invite players.")
                .font(Theme.Typography.body)
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
                        .accessibilityHidden(true)
                    Text("Picks are hidden until kick-off")
                        .font(Theme.Typography.overline)
                        .foregroundStyle(Theme.Color.Content.Text.disabled)
                    Spacer()
                }
                .padding(.horizontal, Theme.Spacing.s40)
            }

            ForEach(viewModel.sortedMembers) { member in
                MemberRow(
                    member: member,
                    pick: viewModel.pick(for: member),
                    fixture: viewModel.pick(for: member).flatMap { viewModel.fixture(for: $0) },
                    deadlinePassed: viewModel.isDeadlinePassed()
                )
                .padding(.horizontal, Theme.Spacing.s40)
            }
        }
    }
}
