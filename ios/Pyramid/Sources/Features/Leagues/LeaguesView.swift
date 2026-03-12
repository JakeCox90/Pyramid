import SwiftUI

struct LeaguesView: View {
    @StateObject private var viewModel = LeaguesViewModel()
    @State private var showCreateLeague = false
    @State private var showJoinLeague = false
    @State private var showJoinPaidLeague = false
    @State private var showBrowseLeagues = false

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
                            Button {
                                showJoinPaidLeague = true
                            } label: {
                                Label(
                                    "Join Paid League",
                                    systemImage: Theme.Icon.League.paid
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
            .sheet(
                isPresented: $showJoinPaidLeague,
                onDismiss: { Task { await viewModel.fetchLeagues() } },
                content: {
                    JoinPaidLeagueView { _ in
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
        VStack(spacing: Theme.Spacing.s60) {
            Spacer()

            VStack(spacing: Theme.Spacing.s40) {
                Image(systemName: Theme.Icon.Status.error)
                    .font(.system(size: 56))
                    .foregroundStyle(Theme.Color.Border.default)

                VStack(spacing: Theme.Spacing.s20) {
                    Text("Something went wrong")
                        .font(Theme.Typography.title3)
                        .foregroundStyle(Theme.Color.Content.Text.default)

                    Text(message)
                        .font(Theme.Typography.subheadline)
                        .foregroundStyle(Theme.Color.Content.Text.disabled)
                        .multilineTextAlignment(.center)
                }
            }

            Button("Try Again") {
                Task { await viewModel.fetchLeagues() }
            }
            .dsStyle(.primary)
            .padding(.horizontal, Theme.Spacing.s40)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, Theme.Spacing.s40)
    }

    private var emptyStateView: some View {
        VStack(spacing: Theme.Spacing.s60) {
            Spacer()

            VStack(spacing: Theme.Spacing.s40) {
                Image(systemName: Theme.Icon.League.trophy)
                    .font(.system(size: 56))
                    .foregroundStyle(Theme.Color.Border.default)

                VStack(spacing: Theme.Spacing.s20) {
                    Text("No leagues yet")
                        .font(Theme.Typography.title3)
                        .foregroundStyle(Theme.Color.Content.Text.default)

                    Text(
                        "Browse open leagues, create your own, "
                        + "or join one with a code."
                    )
                        .font(Theme.Typography.subheadline)
                        .foregroundStyle(Theme.Color.Content.Text.disabled)
                        .multilineTextAlignment(.center)
                }
            }

            VStack(spacing: Theme.Spacing.s30) {
                Button("Browse Free Leagues") {
                    showBrowseLeagues = true
                }
                .dsStyle(.primary)

                Button("Create a League") {
                    showCreateLeague = true
                }
                .dsStyle(.secondary)

                Button("Join with Code") {
                    showJoinLeague = true
                }
                .dsStyle(.secondary)
            }
            .padding(.horizontal, Theme.Spacing.s40)

            Spacer()
            Spacer()
        }
        .padding(.horizontal, Theme.Spacing.s40)
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

// MARK: - League Row

struct LeagueRowView: View {
    let league: League

    var body: some View {
        DSCard {
            HStack {
                VStack(alignment: .leading, spacing: Theme.Spacing.s10) {
                    Text(league.name)
                        .font(Theme.Typography.headline)
                        .foregroundStyle(Theme.Color.Content.Text.default)

                    HStack(spacing: Theme.Spacing.s20) {
                        Text(league.status.displayName)
                            .font(Theme.Typography.caption1)
                            .foregroundStyle(Theme.Color.Content.Text.disabled)

                        if let count = league.memberCount {
                            HStack(spacing: Theme.Spacing.s10) {
                                Image(systemName: Theme.Icon.League.members)
                                    .font(Theme.Typography.caption2)
                                Text("\(count)")
                                    .font(Theme.Typography.caption1)
                            }
                            .foregroundStyle(Theme.Color.Content.Text.disabled)
                        }
                    }
                }

                Spacer()

                Image(systemName: Theme.Icon.Navigation.disclosure)
                    .font(.caption)
                    .foregroundStyle(Theme.Color.Border.default)
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
