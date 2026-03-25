import SwiftUI

struct LeagueDetailView: View {
    @StateObject var viewModel: LeagueDetailViewModel
    @State var showPicks = false
    @State var showResults = false
    @State var showPickHistory = false
    @State var showCompleteView = false
    @State var showShareSheet = false
    @State var showEditLeague = false
    @State var showStory = false

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
                    if isAdmin {
                        Button {
                            showEditLeague = true
                        } label: {
                            Image(
                                systemName: "gearshape"
                            )
                        }
                        .accessibilityLabel(
                            "Edit league settings"
                        )
                    }
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
                            .themed(
                                .primary,
                                fullWidth: false
                            )
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
        .sheet(isPresented: $showEditLeague) {
            EditLeagueView(
                league: viewModel.league
            ) {
                Task { await viewModel.load() }
            }
        }
        .fullScreenCover(isPresented: $showStory) {
            if let gameweek = viewModel.currentGameweek {
                GameweekStoryView(
                    leagueId: viewModel.league.id,
                    gameweek: gameweek.id,
                    leagueName: viewModel.league.name,
                    currentUserId: viewModel.currentUserId
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

    private var isAdmin: Bool {
        guard let userId = viewModel.currentUserId,
              let createdBy = viewModel.league.createdBy
        else { return false }
        return userId == createdBy
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

}
