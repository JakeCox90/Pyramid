import SwiftUI

struct HomeView: View {
    @StateObject var viewModel = HomeViewModel()

    var body: some View {
        NavigationStack {
            Group {
                if viewModel.isLoading && viewModel.homeData == nil {
                    loadingView
                } else if let error = viewModel.errorMessage,
                          viewModel.homeData == nil {
                    errorView(error)
                } else if let data = viewModel.homeData {
                    contentView(data)
                } else {
                    loadingView
                }
            }
            .navigationTitle("Home")
            .navigationBarTitleDisplayMode(.large)
            .background(
                Theme.Color.Surface.Background.page.ignoresSafeArea()
            )
            .task { await viewModel.load() }
        }
    }

    // MARK: - Loading

    private var loadingView: some View {
        VStack(spacing: Theme.Spacing.s40) {
            ProgressView()
                .tint(Theme.Color.Content.Text.subtle)
            Text("Loading...")
                .font(Theme.Typography.body)
                .foregroundStyle(Theme.Color.Content.Text.subtle)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Error

    private func errorView(_ message: String) -> some View {
        ErrorStateView(message: message) {
            await viewModel.load()
        }
    }

    // MARK: - Content

    func contentView(_ data: HomeData) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.s40) {
                picksNeededSection(data)
                liveMatchSection()
                lastGwResultsSection(data)
                leaguesSection(data)
            }
            .padding(Theme.Spacing.s40)
        }
        .refreshable { await viewModel.load() }
        .onDisappear { viewModel.stopPolling() }
    }

    func picksNeededSection(_ data: HomeData) -> some View {
        let leaguesNeedingPick = data.leagues.filter { league in
            data.picks[league.id] == nil
                && data.memberStatuses[league.id] == .active
        }

        return Group {
            if !leaguesNeedingPick.isEmpty {
                VStack(alignment: .leading, spacing: Theme.Spacing.s20) {
                    Text("Picks Needed")
                        .font(Theme.Typography.headline)
                        .foregroundStyle(Theme.Color.Content.Text.default)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: Theme.Spacing.s30) {
                            ForEach(leaguesNeedingPick) { league in
                                NavigationLink(
                                    destination: LeagueDetailView(
                                        league: league
                                    )
                                ) {
                                    pickNeededCard(
                                        league: league,
                                        gameweek: data.gameweek
                                    )
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
            }
        }
    }

    private func pickNeededCard(
        league: League,
        gameweek: Gameweek?
    ) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.s20) {
            Text(league.name)
                .font(Theme.Typography.headline)
                .foregroundStyle(Theme.Color.Content.Text.default)
                .lineLimit(1)

            if let gw = gameweek {
                Text(gw.name)
                    .font(Theme.Typography.caption1)
                    .foregroundStyle(Theme.Color.Content.Text.subtle)
            }

            if let deadline = gameweek?.deadlineAt {
                Text(deadline, style: .relative)
                    .font(Theme.Typography.caption1)
                    .foregroundStyle(
                        Theme.Color.Status.Warning.resting
                    )
            }

            HStack {
                Text("Select a pick")
                    .font(Theme.Typography.callout)
                    .foregroundStyle(Theme.Color.Primary.text)
                Image(systemName: "chevron.right")
                    .font(Theme.Typography.caption1)
                    .foregroundStyle(Theme.Color.Primary.text)
            }
            .padding(.horizontal, Theme.Spacing.s30)
            .padding(.vertical, Theme.Spacing.s20)
            .background(Theme.Color.Primary.resting)
            .clipShape(
                RoundedRectangle(cornerRadius: Theme.Radius.default)
            )
        }
        .padding(Theme.Spacing.s40)
        .frame(width: 200, alignment: .leading)
        .background(Theme.Color.Surface.Background.container)
        .clipShape(RoundedRectangle(cornerRadius: Theme.Radius.r40))
    }
}
