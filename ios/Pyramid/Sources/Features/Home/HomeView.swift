import SwiftUI

struct HomeView: View {
    @StateObject var viewModel = HomeViewModel()
    @State var showPicks = false
    @State private var matchCardVisible = true
    @State var showEliminationOverlay = false
    @State var eliminationOverlayResult: LeagueResult?
    @State var showSurvivalOverlay = false
    @State var survivalOverlayResult: LeagueResult?

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading,
                   viewModel.homeData == nil {
                    loadingView
                } else if let error = viewModel.errorMessage,
                          viewModel.homeData == nil {
                    errorView(error)
                } else {
                    contentView
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .background(
                Theme.Color.Surface.Background.page
                    .ignoresSafeArea()
            )
            .task { await viewModel.load() }
            .fullScreenCover(
                isPresented: $showEliminationOverlay
            ) {
                if let result = eliminationOverlayResult {
                    EliminationOverlay(
                        leagueName: result.leagueName,
                        pickedTeamName: result.teamName,
                        opponentName: result.pickedHome
                            ? result.awayTeamName
                            : result.homeTeamName,
                        homeScore: result.homeScore,
                        awayScore: result.awayScore,
                        pickedHome: result.pickedHome,
                        onDismiss: {
                            showEliminationOverlay = false
                        }
                    )
                    .background(.black)
                }
            }
            .fullScreenCover(
                isPresented: $showSurvivalOverlay
            ) {
                if let result = survivalOverlayResult {
                    SurvivalOverlay(
                        leagueName: result.leagueName,
                        pickedTeamName: result.teamName,
                        opponentName: result.pickedHome
                            ? result.awayTeamName
                            : result.homeTeamName,
                        homeScore: result.homeScore,
                        awayScore: result.awayScore,
                        pickedHome: result.pickedHome,
                        onDismiss: {
                            showSurvivalOverlay = false
                        }
                    )
                    .background(.black)
                }
            }
            .onChange(
                of: viewModel.homeData
            ) { newData in
                checkForElimination(data: newData)
                checkForSurvival(data: newData)
            }
            .navigationDestination(
                isPresented: $showPicks
            ) {
                if let leagueId = viewModel
                    .selectedLeague?.id {
                    PicksView(leagueId: leagueId)
                }
            }
            .onChange(of: showPicks) { showing in
                if showing {
                    // Hide card so it can animate in on return
                    matchCardVisible = false
                } else {
                    Task {
                        await viewModel.load()
                        // Animate the card into view
                        withAnimation(
                            .easeOut(duration: 0.45)
                                .delay(0.1)
                        ) {
                            matchCardVisible = true
                        }
                    }
                }
            }
        }
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: Theme.Spacing.s40) {
            ProgressView()
                .tint(Theme.Color.Content.Text.subtle)
            Text("Loading...")
                .font(Theme.Typography.body)
                .foregroundStyle(
                    Theme.Color.Content.Text.subtle
                )
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Error

    private func errorView(
        _ message: String
    ) -> some View {
        PlaceholderView(
            icon: Theme.Icon.Status.error,
            title: "Something went wrong",
            message: message,
            buttonTitle: "Try Again",
            onAsyncAction: { await viewModel.load() }
        )
    }

    // MARK: - Content

    private var contentView: some View {
        let leagues = viewModel.homeData?.leagues ?? []

        return VStack(spacing: 0) {
            // Fixed header — pinned above scroll
            VStack(spacing: Theme.Spacing.s40) {
                countdownSection
                leagueSelector
            }
            .padding(.horizontal, Theme.Spacing.s40)
            .padding(.bottom, Theme.Spacing.s40)

            // Swipeable per-league content
            if leagues.count > 1 {
                TabView(
                    selection: Binding(
                        get: {
                            viewModel.selectedLeague?.id ?? ""
                        },
                        set: { newId in
                            if let league = leagues.first(
                                where: { $0.id == newId }
                            ) {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    viewModel.selectLeague(league)
                                }
                            }
                        }
                    )
                ) {
                    ForEach(leagues) { league in
                        leaguePageContent(league)
                            .tag(league.id)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .never))
            } else if let league = leagues.first {
                leaguePageContent(league)
            }
        }
        .onDisappear {
            viewModel.stopPolling()
            viewModel.stopCountdown()
        }
    }

    func leaguePageContent(
        _ league: League
    ) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: Theme.Spacing.s40) {
                if viewModel.isEliminated(in: league) {
                    eliminationSection(for: league)
                } else if let context = viewModel
                    .currentPick(for: league) {
                    matchCard(context)
                        .opacity(matchCardVisible ? 1 : 0)
                        .offset(
                            y: matchCardVisible ? 0 : 20
                        )
                } else {
                    matchCardEmpty()
                }

                if !viewModel.isEliminated(in: league) {
                    playersRemainingCard(for: league)
                }

                previousPicksSection(for: league)
            }
            .padding(.horizontal, Theme.Spacing.s40)
            .padding(.bottom, Theme.Spacing.s80)
        }
        .refreshable { await viewModel.load() }
    }
}
