import SwiftUI

struct LeaguesView: View {
    @StateObject var viewModel = LeaguesViewModel()
    @State var showCreateLeague = false
    @State var showJoinLeague = false
    @State var showBrowseLeagues = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.leagues.isEmpty {
                    loadingView
                } else if let errorMessage = viewModel.errorMessage,
                          viewModel.leagues.isEmpty {
                    errorStateView(message: errorMessage)
                } else if viewModel.leagues.isEmpty {
                    emptyStateContent
                } else {
                    leaguesList
                }
            }
            .navigationTitle("Leagues")
            .toolbar {
                if !viewModel.leagues.isEmpty {
                    ToolbarItem(placement: .primaryAction) {
                        Menu {
                            Button {
                                showBrowseLeagues = true
                            } label: {
                                Label(
                                    "Browse Free Leagues",
                                    systemImage: Theme.Icon.League.members
                                )
                            }
                            Button {
                                showCreateLeague = true
                            } label: {
                                Label(
                                    "Create League",
                                    systemImage: Theme.Icon.League.create
                                )
                            }
                            Button {
                                showJoinLeague = true
                            } label: {
                                Label(
                                    "Join with Code",
                                    systemImage: Theme.Icon.League.join
                                )
                            }
                        } label: {
                            Image(systemName: Theme.Icon.Navigation.add)
                        }
                    }
                }
            }
            .sheet(
                isPresented: $showCreateLeague,
                onDismiss: { Task { await viewModel.fetchLeagues() } },
                content: {
                    CreateLeagueView { created in
                        Task { await viewModel.leagueAdded(created) }
                    }
                }
            )
            .sheet(
                isPresented: $showJoinLeague,
                onDismiss: { Task { await viewModel.fetchLeagues() } },
                content: {
                    JoinLeagueView { _ in
                        Task { await viewModel.fetchLeagues() }
                    }
                }
            )
            .sheet(
                isPresented: $showBrowseLeagues,
                onDismiss: { Task { await viewModel.fetchLeagues() } },
                content: {
                    BrowseLeaguesView { _ in
                        Task { await viewModel.fetchLeagues() }
                    }
                }
            )
            .background(Theme.Color.Surface.Background.page.ignoresSafeArea())
            .task {
                await viewModel.fetchLeagues()
            }
            .refreshable {
                await viewModel.fetchLeagues()
            }
        }
    }

    // MARK: - Subviews

    private var loadingView: some View {
        ProgressView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private func errorStateView(message: String) -> some View {
        ErrorStateView(message: message) {
            await viewModel.fetchLeagues()
        }
    }

    private var leaguesList: some View {
        ScrollView {
            LazyVStack(spacing: Theme.Spacing.s30) {
                ForEach(viewModel.leagues) { league in
                    NavigationLink(
                        destination: LeagueDetailView(league: league)
                    ) {
                        LeagueRowView(league: league)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, Theme.Spacing.s40)
                }
            }
            .padding(.vertical, Theme.Spacing.s40)
        }
    }
}
