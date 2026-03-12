import SwiftUI

struct LeagueDetailView: View {
    @EnvironmentObject var appState: AppState
    @StateObject var viewModel: LeagueDetailViewModel
    @State var showPicks = false
    @State var showResults = false
    @State var showPickHistory = false
    @State var showCompleteView = false
    @State var showShareSheet = false
    @State var showSettlementResult = false

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
        .sheet(isPresented: $showSettlementResult) {
            if let gameweek = viewModel.currentGameweek {
                SettlementResultView(
                    leagueId: viewModel.league.id,
                    gameweekId: gameweek.id
                )
            }
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
                mySettlementBanner
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

}
