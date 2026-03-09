import SwiftUI

struct LeaguesView: View {
    @StateObject private var viewModel = LeaguesViewModel()
    @State private var showCreateLeague = false
    @State private var showJoinLeague = false
    @State private var showJoinPaidLeague = false

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.leagues.isEmpty {
                    loadingView
                } else if let errorMessage = viewModel.errorMessage,
                          viewModel.leagues.isEmpty {
                    errorStateView(message: errorMessage)
                } else if viewModel.leagues.isEmpty {
                    emptyStateView
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
                                showCreateLeague = true
                            } label: {
                                Label("Create League", systemImage: SFSymbol.createLeague)
                            }
                            Button {
                                showJoinLeague = true
                            } label: {
                                Label("Join League", systemImage: SFSymbol.joinLeague)
                            }
                            Button {
                                showJoinPaidLeague = true
                            } label: {
                                Label("Join Paid League", systemImage: SFSymbol.paidLeague)
                            }
                        } label: {
                            Image(systemName: SFSymbol.addButton)
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
                isPresented: $showJoinPaidLeague,
                onDismiss: { Task { await viewModel.fetchLeagues() } },
                content: {
                    JoinPaidLeagueView { _ in
                        Task { await viewModel.fetchLeagues() }
                    }
                }
            )
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
        VStack(spacing: DS.Spacing.s6) {
            Spacer()

            VStack(spacing: DS.Spacing.s4) {
                Image(systemName: SFSymbol.error)
                    .font(.system(size: 56))
                    .foregroundStyle(Color.DS.Neutral.n300)

                VStack(spacing: DS.Spacing.s2) {
                    Text("Something went wrong")
                        .font(.DS.title3)
                        .foregroundStyle(Color.DS.Neutral.n900)

                    Text(message)
                        .font(.DS.subheadline)
                        .foregroundStyle(Color.DS.Neutral.n500)
                        .multilineTextAlignment(.center)
                }
            }

            Button("Try Again") {
                Task { await viewModel.fetchLeagues() }
            }
            .dsStyle(.primary)
            .padding(.horizontal, DS.Spacing.pageMargin)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, DS.Spacing.pageMargin)
    }

    private var emptyStateView: some View {
        VStack(spacing: DS.Spacing.s6) {
            Spacer()

            VStack(spacing: DS.Spacing.s4) {
                Image(systemName: SFSymbol.trophy)
                    .font(.system(size: 56))
                    .foregroundStyle(Color.DS.Neutral.n300)

                VStack(spacing: DS.Spacing.s2) {
                    Text("No leagues yet")
                        .font(.DS.title3)
                        .foregroundStyle(Color.DS.Neutral.n900)

                    Text("Create a league and invite friends, or join one with a code.")
                        .font(.DS.subheadline)
                        .foregroundStyle(Color.DS.Neutral.n500)
                        .multilineTextAlignment(.center)
                }
            }

            VStack(spacing: DS.Spacing.s3) {
                Button("Create a League") {
                    showCreateLeague = true
                }
                .dsStyle(.primary)

                Button("Join with Code") {
                    showJoinLeague = true
                }
                .dsStyle(.secondary)
            }
            .padding(.horizontal, DS.Spacing.pageMargin)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, DS.Spacing.pageMargin)
    }

    private var leaguesList: some View {
        ScrollView {
            LazyVStack(spacing: DS.Spacing.s3) {
                ForEach(viewModel.leagues) { league in
                    NavigationLink(destination: LeagueDetailView(league: league)) {
                        LeagueRowView(league: league)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, DS.Spacing.pageMargin)
                }
            }
            .padding(.vertical, DS.Spacing.s4)
        }
    }
}

// MARK: - League Row

struct LeagueRowView: View {
    let league: League

    var body: some View {
        DSCard {
            HStack {
                VStack(alignment: .leading, spacing: DS.Spacing.s1) {
                    Text(league.name)
                        .font(.DS.headline)
                        .foregroundStyle(Color.DS.Neutral.n900)

                    Text(league.status.displayName)
                        .font(.DS.caption1)
                        .foregroundStyle(Color.DS.Neutral.n500)
                }

                Spacer()

                Image(systemName: SFSymbol.disclosure)
                    .font(.caption)
                    .foregroundStyle(Color.DS.Neutral.n300)
            }
        }
    }
}

private extension League.LeagueStatus {
    var displayName: String {
        switch self {
        case .pending:   return "Waiting for players"
        case .active:    return "In progress"
        case .completed: return "Finished"
        case .cancelled: return "Cancelled"
        }
    }
}
