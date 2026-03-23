import SwiftUI

struct BrowseLeaguesView: View {
    @StateObject private var viewModel = BrowseLeaguesViewModel()
    @Environment(\.dismiss)
    private var dismiss

    var onJoined: ((JoinLeagueResponse) -> Void)?

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.leagues.isEmpty {
                    loadingView
                } else if viewModel.leagues.isEmpty {
                    emptyView
                } else {
                    leaguesList
                }
            }
            .background(Theme.Color.Surface.Background.page.ignoresSafeArea())
            .navigationTitle("Free Leagues")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Close") { dismiss() }
                }
            }
            .task {
                await viewModel.fetchOpenLeagues()
            }
            .refreshable {
                await viewModel.fetchOpenLeagues()
            }
            .alert(
                "Joined!",
                isPresented: .init(
                    get: { viewModel.joinedLeague != nil },
                    set: { if !$0 {
                        if let joined = viewModel.joinedLeague {
                            onJoined?(joined)
                        }
                        viewModel.joinedLeague = nil
                    }}
                )
            ) {
                Button("OK") {
                    if let joined = viewModel.joinedLeague {
                        onJoined?(joined)
                    }
                    viewModel.joinedLeague = nil
                    dismiss()
                }
            } message: {
                if let joined = viewModel.joinedLeague {
                    Text("You've joined \(joined.name). Good luck!")
                }
            }
            .alert(
                "Error",
                isPresented: .init(
                    get: { viewModel.errorMessage != nil },
                    set: { if !$0 { viewModel.errorMessage = nil } }
                )
            ) {
                Button("OK", role: .cancel) {}
            } message: {
                Text(viewModel.errorMessage ?? "")
            }
        }
    }

    private var loadingView: some View {
        ProgressView()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var emptyView: some View {
        VStack(spacing: Theme.Spacing.s40) {
            Spacer()

            Image(systemName: Theme.Icon.League.trophy)
                .font(.system(size: 56))
                .foregroundStyle(Theme.Color.Border.default)

            VStack(spacing: Theme.Spacing.s20) {
                Text("No open leagues")
                    .font(Theme.Typography.subhead)
                    .foregroundStyle(Theme.Color.Content.Text.default)

                Text(
                    "There are no free leagues available to join right now. "
                    + "Why not create one?"
                )
                    .font(Theme.Typography.body)
                    .foregroundStyle(Theme.Color.Content.Text.disabled)
                    .multilineTextAlignment(.center)
            }

            Spacer()
            Spacer()
        }
        .padding(.horizontal, Theme.Spacing.s40)
    }

    private var leaguesList: some View {
        ScrollView {
            LazyVStack(spacing: Theme.Spacing.s30) {
                ForEach(viewModel.leagues) { league in
                    BrowseLeagueCardView(
                        league: league,
                        isJoining: viewModel.joiningLeagueId == league.id
                    ) {
                        Task { await viewModel.joinLeague(league) }
                    }
                    .padding(.horizontal, Theme.Spacing.s40)
                }
            }
            .padding(.vertical, Theme.Spacing.s40)
        }
    }
}

// MARK: - Card

private struct BrowseLeagueCardView: View {
    let league: BrowseLeague
    let isJoining: Bool
    let onJoin: () -> Void

    var body: some View {
        Card {
            HStack {
                VStack(alignment: .leading, spacing: Theme.Spacing.s10) {
                    Text(league.name)
                        .font(Theme.Typography.subhead)
                        .foregroundStyle(Theme.Color.Content.Text.default)

                    HStack(spacing: Theme.Spacing.s20) {
                        Label(
                            "\(league.memberCount) players",
                            systemImage: Theme.Icon.League.members
                        )
                        .font(Theme.Typography.overline)
                        .foregroundStyle(Theme.Color.Content.Text.disabled)

                        Text(
                            league.status == .pending
                                ? "Waiting" : "Active"
                        )
                            .font(Theme.Typography.overline)
                            .foregroundStyle(
                                league.status == .active
                                    ? Theme.Color.Status.Success.resting
                                    : Theme.Color.Content.Text.disabled
                            )
                    }
                }

                Spacer()

                if isJoining {
                    ProgressView()
                } else {
                    Button("Join") { onJoin() }
                        .themed(.primary, fullWidth: false)
                }
            }
        }
    }
}
